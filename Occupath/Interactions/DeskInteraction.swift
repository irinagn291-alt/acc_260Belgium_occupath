import Foundation
import SwiftUI
import UIKit

/// Interaction. Sheet identity. Chrome owned by SwiftUI, not a ViewModel.
enum DeskSheet: String, Identifiable, Equatable, Sendable {
    case ledger
    case settings
    case inspector
    case meet
    case measurement
    case path
    case onboarding
    case token

    var id: String { rawValue }
}

/// SwiftUI @State plate (SPEC 3.1–3.2). Chrome and the working board.
/// Does not run desk verbs. A view starts a Context; Interaction is the role method.
/// Not a ViewModel: no @Observable, no use case, no coordinator.
@MainActor
struct DeskInteraction {
    var board: WorkingTimetable
    var playhead: Double
    var chainage: Double
    var selectedTrainID: UUID?
    var selectedBlockID: UUID?
    var meetOffer: MeetOffer?
    var sheet: DeskSheet?
    var onboarded: Bool
    var fault: String?
    var busy = false
    var commitBusy = false
    var commitFlash = false
    var weekIndex: [WorkingTimetable] = []

    let ledger: WeekLedger
    let defaults: UserDefaults
    var shouldLoad: Bool
    private var appeared = false
    private var hookConsumed = false

    var published: PublishedOccupation {
        OccupationInk.published(from: board)
    }

    init(
        ledger: WeekLedger,
        defaults: UserDefaults = .standard,
        shouldLoad: Bool = true
    ) {
        self.ledger = ledger
        self.defaults = defaults
        self.shouldLoad = shouldLoad
        let opening = openingBoard(isoWeek: ISOWeekDate.current())
        let ink = OccupationInk.published(from: opening)
        board = opening
        playhead = ink.timeStart
        chainage = 0
        onboarded = defaults.bool(forKey: PreferenceKey.onboardingComplete)
    }

    static func live() -> DeskInteraction {
        let directory: URL
        do {
            let root = try FileManager.default.url(
                for: .applicationSupportDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: true
            )
            directory = root.appendingPathComponent("Occupath/Boards", isDirectory: true)
        } catch {
            directory = FileManager.default.temporaryDirectory.appendingPathComponent(
                "Occupath/Boards",
                isDirectory: true
            )
        }
        return DeskInteraction(ledger: WeekLedger(directory: directory), defaults: .standard)
    }

    static func previewPopulated() -> DeskInteraction {
        makePreview(board: DeskSeed.legalOccupationBoard(), onboarded: true)
    }

    static func previewEmpty() -> DeskInteraction {
        makePreview(board: openingBoard(isoWeek: ISOWeekDate(year: 2026, week: 35)), onboarded: true)
    }

    private static func makePreview(board: WorkingTimetable, onboarded: Bool) -> DeskInteraction {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(
            "ocp-preview-\(UUID().uuidString)",
            isDirectory: true
        )
        let suite = "ocp.preview.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite) ?? .standard
        defaults.set(onboarded, forKey: PreferenceKey.onboardingComplete)
        var desk = DeskInteraction(
            ledger: WeekLedger(directory: directory, defaultsSuiteName: suite, writeDelayNanoseconds: 0),
            defaults: defaults,
            shouldLoad: false
        )
        desk.onboarded = onboarded
        desk.install(board)
        if board.blocks.isEmpty {
            desk.weekIndex = []
        }
        return desk
    }

    mutating func install(_ board: WorkingTimetable) {
        self.board = board
        weekIndex = [board]
        clampScrubbers()
        playhead = published.board.occupations.first?.start ?? published.timeStart
        if let first = board.blocks.first {
            chainage = published.chainage[first.fromMilepost] ?? 0
        }
    }

    mutating func appear() async {
        guard shouldLoad else {
            applyReviewHook()
            return
        }
        if appeared {
            applyReviewHook()
            return
        }
        appeared = true
        do {
            try await ledger.seedDemoIfNeeded()
        } catch {
            fault = "The week ledger could not be opened."
        }
        onboarded = defaults.bool(forKey: PreferenceKey.onboardingComplete)
        let loaded = await ledger.load()
        if let seeded = loaded.boards.first(where: { $0.isoWeek == DeskSeed.week })
            ?? loaded.boards.last
        {
            board = seeded
        } else {
            board = openingBoard(isoWeek: ISOWeekDate.current())
        }
        weekIndex = loaded.boards
        if loaded.warning == .startedEmpty {
            fault = "A working board was unreadable. The desk is empty."
        } else if loaded.warning == .recoveredFromBackup {
            fault = "Recovered the last good working board."
        }
        clampScrubbers()
        playhead = published.board.occupations.first?.start ?? published.timeStart
        busy = false
        applyReviewHook()
    }

    mutating func flush() async {
        do {
            try await ledger.flush()
        } catch {
            fault = "The working board could not be written."
        }
    }

    mutating func retry() async {
        fault = nil
        appeared = false
        await appear()
    }

    mutating func finishOnboarding() {
        defaults.set(true, forKey: PreferenceKey.onboardingComplete)
        onboarded = true
        applyReviewHook()
    }

    mutating func reopenOnboarding() {
        sheet = nil
        defaults.set(false, forKey: PreferenceKey.onboardingComplete)
        onboarded = false
    }

    mutating func resetAll() async {
        commitBusy = true
        defer { commitBusy = false }
        do {
            try await ledger.resetAllData()
            defaults.removeObject(forKey: PreferenceKey.demoSeed)
            board = openingBoard(isoWeek: ISOWeekDate.current())
            weekIndex = []
            fault = nil
            meetOffer = nil
            sheet = nil
            clampScrubbers()
        } catch {
            fault = "The ledger could not be cleared."
        }
    }

    mutating func adopt(_ next: WorkingTimetable) {
        board = next
        persistNote()
        clampScrubbers()
    }

    mutating func presentMeet(trainID: UUID, blockID: UUID) {
        if let context = ApplyMeet.bind(laterTrainID: trainID, blockID: blockID, on: board) {
            selectedTrainID = context.laterPath.train.id
            selectedBlockID = context.block.id
            meetOffer = context.laterPath.offer()
            if meetOffer != nil {
                sheet = .meet
            } else {
                fault = "The token is still out."
            }
        } else {
            selectedTrainID = trainID
            selectedBlockID = blockID
            fault = "The token is still out."
        }
    }

    mutating func presentMeet(_ mark: ConflictMark) {
        presentMeet(trainID: mark.trainID, blockID: mark.blockID)
    }

    mutating func select(trainID: UUID?, blockID: UUID?) {
        selectedTrainID = trainID
        selectedBlockID = blockID
    }

    mutating func openBoard(_ board: WorkingTimetable) {
        self.board = board
        sheet = nil
        clampScrubbers()
    }

    mutating func commitBoard() async {
        guard published.loopFeasible else {
            fault = "The board stays in exception until the loop can hold the shorter consist."
            return
        }
        commitBusy = true
        defer { commitBusy = false }
        do {
            try await ledger.save(board)
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            commitFlash = true
            let nextWeek = OccupationInk.succeedingWeek(board.isoWeek)
            if let existing = await ledger.board(for: nextWeek) {
                board = existing
            } else {
                board = openingBoard(isoWeek: nextWeek)
            }
            weekIndex = await ledger.boards
            persistNote()
            clampScrubbers()
        } catch {
            fault = "The working board could not be committed."
        }
    }

    mutating func applyReviewHook() {
        guard let hook = ReviewHook.consume(
            arguments: ProcessInfo.processInfo.arguments,
            onboarded: onboarded,
            consumed: &hookConsumed
        ) else { return }
        switch hook {
        case .today:
            sheet = nil
        case .log:
            sheet = .ledger
        case .goals:
            sheet = .settings
        }
    }

    private func persistNote() {
        let snapshot = board
        Task { await ledger.note(snapshot) }
    }

    private mutating func clampScrubbers() {
        let ink = published
        if playhead < ink.timeStart || playhead > ink.timeEnd {
            playhead = ink.timeStart
        }
        if chainage < 0 || chainage > ink.maxChainage {
            chainage = 0
        }
    }
}

extension Binding where Value == DeskInteraction {
    @MainActor
    func appear() async {
        var value = wrappedValue
        await value.appear()
        wrappedValue = value
    }

    @MainActor
    func flush() async {
        var value = wrappedValue
        await value.flush()
        wrappedValue = value
    }

    @MainActor
    func retry() async {
        var value = wrappedValue
        await value.retry()
        wrappedValue = value
    }

    @MainActor
    func resetAll() async {
        var value = wrappedValue
        await value.resetAll()
        wrappedValue = value
    }

    @MainActor
    func commitBoard() async {
        var value = wrappedValue
        await value.commitBoard()
        wrappedValue = value
        if wrappedValue.commitFlash {
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 1_200_000_000)
                wrappedValue.commitFlash = false
            }
        }
    }
}
