import SwiftUI
import UIKit

/// Role: Presentation. First measurement — tape / clino / brg on the desk.
struct MeasurementSheet: View {
    @Binding var interaction: DeskInteraction
    @State private var fromMilepost = ""
    @State private var toMilepost = ""
    @State private var tape = ""
    @State private var clino = "0"
    @State private var brg = "0"
    @State private var localFault: String?
    @FocusState private var focused: Field?
    @Environment(\.sizeCategory) private var sizeCategory

    private enum Field: Hashable {
        case from, to, tape, clino, brg
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: PlateInk.space(2)) {
                    if let localFault {
                        Text(localFault)
                            .plateText(.caption, category: sizeCategory)
                            .foregroundStyle(PlateInk.accent)
                    }
                    field("From milepost", text: $fromMilepost, field: .from)
                    field("To milepost", text: $toMilepost, field: .to)
                    decimalField("Tape", text: $tape, field: .tape)
                    decimalField("Clino", text: $clino, field: .clino)
                    decimalField("Bearing", text: $brg, field: .brg)
                    Button("Enter measurement") { submit() }
                        .plateText(.token, category: sizeCategory)
                        .foregroundStyle(canSubmit ? PlateInk.accent : PlateInk.muted)
                        .plateTap()
                        .disabled(!canSubmit)
                }
                .padding(PlateInk.space(2))
            }
            .scrollDismissesKeyboard(.interactively)
            .background(PlateInk.background.ignoresSafeArea())
            .navigationTitle("Measurement")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close", systemImage: "xmark") { interaction.sheet = nil }
                        .accessibilityLabel("Close")
                }
            }
            .onTapGesture { focused = nil }
        }
    }

    private var canSubmit: Bool {
        parseDecimal(tape).map { $0 > 0 } == true
            && parseDecimal(clino) != nil
            && parseDecimal(brg) != nil
            && !fromMilepost.isEmpty
            && !toMilepost.isEmpty
            && fromMilepost != toMilepost
    }

    private func submit() {
        guard let tapeValue = parseDecimal(tape), tapeValue > 0,
              let clinoValue = parseDecimal(clino),
              let brgValue = parseDecimal(brg)
        else {
            localFault = "Tape must be a positive length."
            return
        }
        let block = SingleLineBlock(
            fromMilepost: fromMilepost,
            toMilepost: toMilepost,
            tape: tapeValue,
            clino: clinoValue,
            brg: brgValue
        )
        do {
            interaction.adopt(try LoopCheck.bind(interaction.board).surveyor.record(block))
            interaction.sheet = nil
        } catch {
            localFault = plateCopy(error)
        }
    }

    private func field(_ title: String, text: Binding<String>, field: Field) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title)
                .plateText(.caption, category: sizeCategory)
                .foregroundStyle(PlateInk.muted)
            TextField(title, text: text)
                .plateText(.body, category: sizeCategory)
                .focused($focused, equals: field)
                .frame(minHeight: PlateInk.tap)
        }
    }

    private func decimalField(_ title: String, text: Binding<String>, field: Field) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title)
                .plateText(.caption, category: sizeCategory)
                .foregroundStyle(PlateInk.muted)
            TextField(title, text: text)
                .keyboardType(.decimalPad)
                .plateText(.body, category: sizeCategory)
                .focused($focused, equals: field)
                .frame(minHeight: PlateInk.tap)
        }
    }
}

/// Role: Presentation. Place a path by passing times — editor lives on the desk.
struct PathSheet: View {
    @Binding var interaction: DeskInteraction
    @State private var name = ""
    @State private var length = ""
    @State private var times: [String] = []
    @State private var localFault: String?
    @FocusState private var focused: String?
    @Environment(\.sizeCategory) private var sizeCategory

    private var mileposts: [String] {
        var seen: [String] = []
        for block in interaction.published.board.blocks {
            if !seen.contains(block.fromMilepost) { seen.append(block.fromMilepost) }
            if !seen.contains(block.toMilepost) { seen.append(block.toMilepost) }
        }
        return seen
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: PlateInk.space(2)) {
                    if mileposts.isEmpty {
                        PlateEmpty(
                            image: "ocp_EmptyHome",
                            headline: "No mileposts",
                            line: "Enter the first measurement.",
                            actionTitle: "Enter measurement",
                            action: { interaction.sheet = .measurement }
                        )
                    } else {
                        if let localFault {
                            Text(localFault)
                                .plateText(.caption, category: sizeCategory)
                                .foregroundStyle(PlateInk.accent)
                        }
                        labeled("Consist", text: $name, keyboard: .default, focus: "name")
                        labeled("Length", text: $length, keyboard: .decimalPad, focus: "length")
                        ForEach(Array(mileposts.enumerated()), id: \.element) { index, post in
                            labeled(post, text: timeBinding(index), keyboard: .numbersAndPunctuation, focus: post)
                        }
                        Button("Paint the path") { submit() }
                            .plateText(.token, category: sizeCategory)
                            .foregroundStyle(PlateInk.accent)
                            .plateTap()
                    }
                }
                .padding(PlateInk.space(2))
            }
            .scrollDismissesKeyboard(.interactively)
            .background(PlateInk.background.ignoresSafeArea())
            .navigationTitle("Path")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close", systemImage: "xmark") { interaction.sheet = nil }
                        .accessibilityLabel("Close")
                }
            }
            .onAppear {
                if times.count != mileposts.count {
                    times = Array(repeating: "", count: mileposts.count)
                }
            }
        }
    }

    private func timeBinding(_ index: Int) -> Binding<String> {
        Binding(
            get: { index < times.count ? times[index] : "" },
            set: { value in
                if times.count != mileposts.count {
                    times = Array(repeating: "", count: mileposts.count)
                }
                if times.indices.contains(index) {
                    times[index] = value
                }
            }
        )
    }

    private func submit() {
        guard !name.isEmpty, let lengthValue = parseDecimal(length), lengthValue > 0 else {
            localFault = "A consist needs a name and a positive length."
            return
        }
        var stamps: [PassingTime] = []
        for (index, post) in mileposts.enumerated() {
            let raw = index < times.count ? times[index] : ""
            guard !raw.isEmpty else { continue }
            guard let seconds = parseClock(raw), seconds >= 0 else {
                localFault = "Passing time is not a number."
                return
            }
            stamps.append(PassingTime(milepost: post, secondsFromMidnight: seconds))
        }
        guard stamps.count >= 2 else {
            localFault = "The path needs times at both mileposts."
            return
        }
        let train = Train(name: name, length: lengthValue, passingTimes: stamps)
        do {
            var next = try OccupyBlock.Occupier(train: train, board: interaction.board).arrive()
            if let block = next.blocks.first(where: { occupationInterval(train: train, block: $0) != nil }) {
                let context = try OccupyBlock.bind(trainID: train.id, blockID: block.id, on: next)
                do {
                    next = try context.occupier.take()
                } catch BoardError.tokenHeld {
                    interaction.adopt(next)
                    interaction.presentMeet(trainID: train.id, blockID: block.id)
                    interaction.sheet = nil
                    return
                }
            }
            interaction.sheet = nil
            interaction.adopt(next)
        } catch {
            localFault = plateCopy(error)
        }
    }

    private func labeled(
        _ title: String,
        text: Binding<String>,
        keyboard: UIKeyboardType,
        focus: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title)
                .plateText(.caption, category: sizeCategory)
                .foregroundStyle(PlateInk.muted)
                .lineLimit(1)
            TextField(title, text: text)
                .keyboardType(keyboard)
                .plateText(.body, category: sizeCategory)
                .focused($focused, equals: focus)
                .frame(minHeight: PlateInk.tap)
        }
    }
}

/// Role: Presentation. Twist — accept a meet that hands the token and rewrites the later path.
struct MeetSheet: View {
    @Binding var interaction: DeskInteraction
    @Environment(\.sizeCategory) private var sizeCategory

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: PlateInk.space(2)) {
                if UIImage(named: "ocp_TwistHero") != nil {
                    Image("ocp_TwistHero")
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 180)
                        .accessibilityHidden(true)
                }
                if let offer = interaction.meetOffer {
                    Text("Hand the token")
                        .plateText(.plate, category: sizeCategory)
                    Text("Token returns at \(PlayheadClock.label(offer.tokenReturn)). The later path is rewritten to that departure.")
                        .plateText(.body, category: sizeCategory)
                    Text(offer.rewritten.name)
                        .plateText(.token, category: sizeCategory)
                        .lineLimit(1)
                    Button("Accept meet") {
                        if let context = ApplyMeet.bind(
                            laterTrainID: offer.laterTrainID,
                            blockID: offer.blockID,
                            on: interaction.board
                        ) {
                            do {
                                interaction.meetOffer = nil
                                interaction.sheet = nil
                                interaction.adopt(try context.laterPath.accept())
                            } catch {
                                interaction.fault = plateCopy(error)
                            }
                        }
                    }
                    .plateText(.token, category: sizeCategory)
                    .foregroundStyle(PlateInk.accent)
                    .plateTap()
                } else {
                    Text("No meet on this block.")
                        .plateText(.body, category: sizeCategory)
                    Button("Retry") { interaction.sheet = nil }
                        .plateText(.token, category: sizeCategory)
                        .plateTap()
                }
                Spacer()
            }
            .padding(PlateInk.space(2))
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background(PlateInk.background.ignoresSafeArea())
            .navigationTitle("Meet")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close", systemImage: "xmark") { interaction.sheet = nil }
                        .accessibilityLabel("Close")
                }
            }
        }
    }
}
