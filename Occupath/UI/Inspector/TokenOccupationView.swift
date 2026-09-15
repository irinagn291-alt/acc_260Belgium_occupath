import SwiftUI

/// Role: Presentation. Twist screen — one token per single-line block. Not a tab.
struct TokenOccupationView: View {
    @Binding var interaction: DeskInteraction
    @Environment(\.sizeCategory) private var sizeCategory

    init(interaction: Binding<DeskInteraction> = .constant(.previewPopulated())) {
        self._interaction = interaction
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            PlateSheetHeader(title: "Token occupation") {
                interaction.sheet = nil
            }
            .padding(.horizontal, PlateInk.space(2))
            .padding(.top, PlateInk.space(2))
            if let fault = interaction.fault {
                errorState(fault)
                    .padding(PlateInk.space(2))
            } else if interaction.published.board.blocks.isEmpty {
                PlateEmpty(
                    image: PlateArt.emptyHome,
                    headline: "No token on the plate",
                    line: "Enter the first measurement. A block issues one token.",
                    actionTitle: "Enter measurement",
                    action: { interaction.sheet = .measurement }
                )
                .frame(maxHeight: .infinity)
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: PlateInk.space(2)) {
                        hero
                        Text("One token per single-line block. A second consist is refused until you hand it.")
                            .plateText(.body, category: sizeCategory)
                            .foregroundStyle(PlateInk.muted)
                        ForEach(interaction.published.board.blocks) { block in
                            tokenRow(block)
                        }
                    }
                    .padding(PlateInk.space(2))
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .scrollDismissesKeyboard(.interactively)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(PlateInk.background.ignoresSafeArea())
    }

    private var hero: some View {
        Group {
            if UIImage(named: PlateArt.twist) != nil {
                Image(PlateArt.twist)
                    .resizable()
                    .scaledToFit()
            } else {
                Rectangle()
                    .fill(PlateInk.surface)
                    .overlay(Rectangle().stroke(PlateInk.muted.opacity(0.4), lineWidth: 1))
            }
        }
        .frame(maxHeight: 180)
        .frame(maxWidth: .infinity)
        .clipped()
        .accessibilityHidden(true)
    }

    private func errorState(_ text: String) -> some View {
        VStack(alignment: .leading, spacing: PlateInk.space(1)) {
            Text(text)
                .plateText(.body, category: sizeCategory)
                .foregroundStyle(PlateInk.accent)
            PlatePrimaryButton(title: "Retry") {
                Task { await $interaction.retry() }
            }
        }
    }

    private func tokenRow(_ block: SingleLineBlock) -> some View {
        let token = interaction.published.board.token(for: block.id)
        let holder = token?.holder
        let holderName = holder.flatMap { interaction.published.board.train(id: $0.trainID)?.name }
        return VStack(alignment: .leading, spacing: PlateInk.space(1)) {
            Text("\(block.fromMilepost) – \(block.toMilepost)")
                .plateText(.token, category: sizeCategory)
                .lineLimit(1)
            Text(holderName.map { "Held by \($0)" } ?? "Token at the block")
                .plateText(.caption, category: sizeCategory)
                .foregroundStyle(holderName == nil ? PlateInk.muted : PlateInk.accent)
            if holder != nil, let context = try? HandToken.bind(blockID: block.id, on: interaction.board) {
                PlatePrimaryButton(title: "Hand the token") {
                    interaction.adopt(context.holder?.returnToken() ?? context.issuedToken.release())
                }
            } else if let train = interaction.published.board.trains.first,
                      let context = try? OccupyBlock.bind(trainID: train.id, blockID: block.id, on: interaction.board)
            {
                PlatePrimaryButton(title: "Take the token") {
                    do {
                        interaction.adopt(try context.occupier.take())
                    } catch BoardError.tokenHeld {
                        interaction.presentMeet(trainID: context.occupier.train.id, blockID: context.block.id)
                    } catch {
                        interaction.fault = plateCopy(error)
                    }
                }
            }
        }
        .padding(PlateInk.space(2))
        .frame(maxWidth: .infinity, alignment: .leading)
        .background { PlateCardBackdrop() }
    }
}
