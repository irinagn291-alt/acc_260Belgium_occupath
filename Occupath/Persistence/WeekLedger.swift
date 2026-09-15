import Foundation

/// Role: Persistence. Preference keys. Demo seed is Simulator-only and versioned.
enum PreferenceKey {
    static let demoSeed = "ocp.demo.v1"
    static let onboardingComplete = "ocp.onboarding.complete"
}

/// Role: Persistence. Recoverable load outcome. Never crash on a corrupt document.
enum LedgerWarning: Equatable, Sendable {
    case recoveredFromBackup
    case startedEmpty
}

/// Role: Persistence. JSON documents, one file per working timetable. FileManager stays here.
actor WeekLedger {
    private let directory: URL
    private let defaultsSuiteName: String?
    private let fileManager: FileManager
    private let writeDelayNanoseconds: UInt64

    private var boardsByWeek: [ISOWeekDate: WorkingTimetable] = [:]
    private var pendingWeeks: Set<ISOWeekDate> = []
    private var writeTask: Task<Void, Never>?
    private(set) var warning: LedgerWarning?
    private(set) var lastWriteError: String?

    init(
        directory: URL,
        defaultsSuiteName: String? = nil,
        fileManager: FileManager = .default,
        writeDelayNanoseconds: UInt64 = 300_000_000
    ) {
        self.directory = directory
        self.defaultsSuiteName = defaultsSuiteName
        self.fileManager = fileManager
        self.writeDelayNanoseconds = writeDelayNanoseconds
    }

    static func applicationSupportDirectory(fileManager: FileManager = .default) throws -> URL {
        let root = try fileManager.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        return root.appendingPathComponent("Occupath/Boards", isDirectory: true)
    }

    var boards: [WorkingTimetable] {
        boardsByWeek.values.sorted { $0.isoWeek < $1.isoWeek }
    }

    func board(for week: ISOWeekDate) -> WorkingTimetable? {
        boardsByWeek[week]
    }

    func load() async -> (boards: [WorkingTimetable], warning: LedgerWarning?) {
        warning = nil
        boardsByWeek = [:]
        prepareDirectory()
        let urls = documentURLs()
        if urls.isEmpty {
            return (boards, warning)
        }
        var recovered = false
        var loadedAny = false
        for url in urls {
            if let board = decodeFile(url) {
                boardsByWeek[board.isoWeek] = board
                loadedAny = true
                continue
            }
            if let board = decodeFile(backupURL(for: url)) {
                boardsByWeek[board.isoWeek] = board
                recovered = true
                loadedAny = true
            }
        }
        if recovered {
            warning = .recoveredFromBackup
        } else if !loadedAny {
            warning = .startedEmpty
        }
        return (boards, warning)
    }

    func save(_ board: WorkingTimetable) async throws {
        boardsByWeek[board.isoWeek] = board
        try persist(board)
        pendingWeeks.remove(board.isoWeek)
    }

    func note(_ board: WorkingTimetable) {
        boardsByWeek[board.isoWeek] = board
        pendingWeeks.insert(board.isoWeek)
        scheduleFlush()
    }

    func flush() async throws {
        writeTask?.cancel()
        writeTask = nil
        try persistPending()
    }

    func resetAllData() async throws {
        writeTask?.cancel()
        writeTask = nil
        pendingWeeks = []
        boardsByWeek = [:]
        warning = nil
        if fileManager.fileExists(atPath: directory.path) {
            try fileManager.removeItem(at: directory)
        }
        prepareDirectory()
    }

    func seedDemoIfNeeded() async throws {
        #if targetEnvironment(simulator)
        let defaults = preferenceDefaults()
        guard defaults.object(forKey: PreferenceKey.demoSeed) == nil else { return }
        let board = DeskSeed.legalOccupationBoard()
        boardsByWeek[board.isoWeek] = board
        try persist(board)
        defaults.set(true, forKey: PreferenceKey.demoSeed)
        defaults.set(true, forKey: PreferenceKey.onboardingComplete)
        #endif
    }

    private func flushIfNeeded() async {
        writeTask = nil
        do {
            try persistPending()
        } catch {
            lastWriteError = String(describing: error)
        }
    }

    private func persistPending() throws {
        let weeks = pendingWeeks
        pendingWeeks = []
        for week in weeks {
            if let board = boardsByWeek[week] {
                try persist(board)
                lastWriteError = nil
            }
        }
    }

    private func scheduleFlush() {
        writeTask?.cancel()
        let delay = writeDelayNanoseconds
        writeTask = Task { [weak self] in
            if delay > 0 {
                try? await Task.sleep(nanoseconds: delay)
            }
            guard !Task.isCancelled else { return }
            await self?.flushIfNeeded()
        }
    }

    private func persist(_ board: WorkingTimetable) throws {
        prepareDirectory()
        let url = fileURL(for: board.isoWeek)
        let data = try TimetableCodec.encode(board)
        if fileManager.fileExists(atPath: url.path) {
            let backup = backupURL(for: url)
            try? fileManager.removeItem(at: backup)
            try? fileManager.copyItem(at: url, to: backup)
        }
        try data.write(to: url, options: .atomic)
    }

    private func decodeFile(_ url: URL) -> WorkingTimetable? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? TimetableCodec.decode(data)
    }

    private func documentURLs() -> [URL] {
        let contents = try? fileManager.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: nil
        )
        return (contents ?? []).filter { url in
            url.pathExtension == "json" && !url.lastPathComponent.hasSuffix(".json.backup")
        }
    }

    private func fileURL(for week: ISOWeekDate) -> URL {
        directory.appendingPathComponent("\(week.daykey).json")
    }

    private func backupURL(for url: URL) -> URL {
        url.appendingPathExtension("backup")
    }

    private func preferenceDefaults() -> UserDefaults {
        if let defaultsSuiteName {
            return UserDefaults(suiteName: defaultsSuiteName) ?? .standard
        }
        return .standard
    }

    private func prepareDirectory() {
        if !fileManager.fileExists(atPath: directory.path) {
            try? fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        }
    }
}

/// Role: Persistence. Simulator-only legal occupation graph. Device never seeds.
enum DeskSeed {
    static let week = ISOWeekDate(year: 2026, week: 35)
    static let boardID = uuid("11111111-1111-4111-8111-111111111111")
    static let blockAB = uuid("22222222-2222-4222-8222-222222222222")
    static let blockBC = uuid("33333333-3333-4333-8333-333333333333")
    static let blockCD = uuid("44444444-4444-4444-8444-444444444444")
    static let blockDA = uuid("55555555-5555-4555-8555-555555555555")
    static let trainID = uuid("66666666-6666-4666-8666-666666666666")

    /// Seed identities are literals. Failure here is a programmer error.
    private static func uuid(_ raw: String) -> UUID {
        guard let value = UUID(uuidString: raw) else {
            fatalError("Demo seed UUID literal is invalid")
        }
        return value
    }

    static func legalOccupationBoard() -> WorkingTimetable {
        let blocks = [
            SingleLineBlock(id: blockAB, fromMilepost: "MP10", toMilepost: "MP20", tape: 10, clino: 0, brg: 0),
            SingleLineBlock(id: blockBC, fromMilepost: "MP20", toMilepost: "MP30", tape: 10, clino: 0, brg: 90),
            SingleLineBlock(id: blockCD, fromMilepost: "MP30", toMilepost: "MP40", tape: 10, clino: 0, brg: 180),
            SingleLineBlock(id: blockDA, fromMilepost: "MP40", toMilepost: "MP10", tape: 10, clino: 0, brg: 270),
        ]
        let train = Train(
            id: trainID,
            name: "Pilot",
            length: 8,
            passingTimes: [
                PassingTime(milepost: "MP10", secondsFromMidnight: 36_000),
                PassingTime(milepost: "MP20", secondsFromMidnight: 36_600),
            ]
        )
        let occupation = Occupation(
            id: uuid("77777777-7777-4777-8777-777777777777"),
            trainID: trainID,
            blockID: blockAB,
            start: 36_000,
            end: 36_600
        )
        return WorkingTimetable(
            id: boardID,
            isoWeek: week,
            trains: [train],
            blocks: blocks,
            tokens: [
                Token(blockID: blockAB, holderID: trainID),
                Token(blockID: blockBC, holderID: nil),
                Token(blockID: blockCD, holderID: nil),
                Token(blockID: blockDA, holderID: nil),
            ],
            occupations: [occupation]
        )
    }
}
