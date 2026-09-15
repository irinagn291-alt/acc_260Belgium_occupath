import SwiftUI

/// Role: Presentation. Sidebar detail column — selected train or block, not a tab.
struct InspectorColumn: View {
    @Binding var interaction: DeskInteraction
    var showsClose: Bool = false
    @Environment(\.sizeCategory) private var sizeCategory

    init(interaction: Binding<DeskInteraction> = .constant(.previewPopulated()), showsClose: Bool = false) {
        self._interaction = interaction
        self.showsClose = showsClose
    }

    var body: some View {
        let published = interaction.published
        ScrollView {
            VStack(alignment: .leading, spacing: PlateInk.space(2)) {
                if let fault = interaction.fault {
                    Text(fault)
                        .plateText(.caption, category: sizeCategory)
                        .foregroundStyle(PlateInk.accent)
                    Button("Retry") {
                        Task { await $interaction.retry() }
                    }
                    .plateText(.token, category: sizeCategory)
                    .plateTap()
                }
                Text("Conflicts \(OccupathFormatter.integer(published.conflicts.count))")
                    .plateText(.figure, category: sizeCategory)
                    .padding(PlateInk.space(2))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background { PlateCardBackdrop() }
                Text("Token hops \(OccupathFormatter.integer(published.tokenHops))")
                    .plateText(.body, category: sizeCategory)
                Button("Token occupation") {
                    interaction.sheet = .token
                }
                .plateText(.token, category: sizeCategory)
                .foregroundStyle(PlateInk.accent)
                .plateTap()
                .accessibilityLabel("Token occupation")
                Text(published.loopFeasible ? "Loop feasible" : "Loop in exception")
                    .plateText(.body, category: sizeCategory)
                    .foregroundStyle(published.loopFeasible ? PlateInk.ink : PlateInk.accent)
                if let train = published.board.trains.first(where: { $0.id == interaction.selectedTrainID }) {
                    trainCard(train, published: published)
                } else if let block = published.board.blocks.first(where: { $0.id == interaction.selectedBlockID }) {
                    blockCard(block, published: published)
                } else {
                    Text("Tap a path or a block on the plate.")
                        .plateText(.caption, category: sizeCategory)
                        .foregroundStyle(PlateInk.muted)
                }
                if let mark = published.conflicts.first,
                   let context = ApplyMeet.bind(laterTrainID: mark.trainID, blockID: mark.blockID, on: interaction.board)
                {
                    Button("Offer a meet") {
                        interaction.meetOffer = context.laterPath.offer()
                        interaction.selectedTrainID = context.laterPath.train.id
                        interaction.selectedBlockID = context.block.id
                        interaction.sheet = .meet
                    }
                    .plateText(.token, category: sizeCategory)
                    .foregroundStyle(PlateInk.accent)
                    .plateTap()
                }
            }
            .padding(PlateInk.space(2))
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(PlateInk.surface.ignoresSafeArea())
        .navigationTitle("Inspector")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if showsClose {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close", systemImage: "xmark") {
                        interaction.sheet = nil
                    }
                    .accessibilityLabel("Close")
                }
            }
        }
    }

    private func trainCard(_ train: Train, published: PublishedOccupation) -> some View {
        VStack(alignment: .leading, spacing: PlateInk.space(1)) {
            Text(train.name)
                .plateText(.token, category: sizeCategory)
                .lineLimit(1)
            Text("Length \(OccupathFormatter.decimal(train.length))")
                .plateText(.caption, category: sizeCategory)
            ForEach(Array(train.passingTimes.enumerated()), id: \.offset) { _, stamp in
                Text("\(stamp.milepost)  \(PlayheadClock.label(stamp.secondsFromMidnight))")
                    .plateText(.caption, category: sizeCategory)
            }
            if let block = published.board.blocks.first(where: { occupationInterval(train: train, block: $0) != nil }),
               let context = try? OccupyBlock.bind(trainID: train.id, blockID: block.id, on: interaction.board)
            {
                Button("Take the token") {
                    startOccupy(context)
                }
                .plateText(.token, category: sizeCategory)
                .foregroundStyle(PlateInk.accent)
                .plateTap()
            }
        }
    }

    private func blockCard(_ block: SingleLineBlock, published: PublishedOccupation) -> some View {
        let token = published.board.token(for: block.id)
        return VStack(alignment: .leading, spacing: PlateInk.space(1)) {
            Text("\(block.fromMilepost) – \(block.toMilepost)")
                .plateText(.token, category: sizeCategory)
            Text("Tape \(OccupathFormatter.decimal(block.tape))  clino \(OccupathFormatter.decimal(block.clino))  brg \(OccupathFormatter.decimal(block.brg))")
                .plateText(.caption, category: sizeCategory)
            if let holder = token?.holder, let name = published.board.train(id: holder.trainID)?.name {
                Text("Token held by \(name)")
                    .plateText(.body, category: sizeCategory)
                if let context = try? HandToken.bind(blockID: block.id, on: interaction.board) {
                    Button("Hand the token") {
                        startHand(context)
                    }
                    .plateText(.token, category: sizeCategory)
                    .foregroundStyle(PlateInk.accent)
                    .plateTap()
                }
            } else {
                Text("Token at the block")
                    .plateText(.body, category: sizeCategory)
                if let train = published.board.trains.first,
                   let context = try? OccupyBlock.bind(trainID: train.id, blockID: block.id, on: interaction.board)
                {
                    Button("Take the token") {
                        startOccupy(context)
                    }
                    .plateText(.token, category: sizeCategory)
                    .foregroundStyle(PlateInk.accent)
                    .plateTap()
                }
            }
        }
    }

    private func startOccupy(_ context: OccupyBlock) {
        do {
            interaction.adopt(try context.occupier.take())
        } catch BoardError.tokenHeld {
            interaction.presentMeet(trainID: context.occupier.train.id, blockID: context.block.id)
        } catch {
            interaction.fault = plateCopy(error)
        }
    }

    private func startHand(_ context: HandToken) {
        interaction.adopt(context.holder?.returnToken() ?? context.issuedToken.release())
    }
}
