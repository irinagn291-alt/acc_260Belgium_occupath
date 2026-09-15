import SwiftUI

/// Role: Presentation. Local list of working boards keyed by ISO week. Opens a Marey document.
struct WeekLedgerView: View {
    @Binding var interaction: DeskInteraction
    @Environment(\.sizeCategory) private var sizeCategory

    init(interaction: Binding<DeskInteraction> = .constant(.previewPopulated())) {
        self._interaction = interaction
    }

    var body: some View {
        VStack(alignment: .leading, spacing: PlateInk.space(2)) {
            PlateSheetHeader(title: "Week ledger") {
                interaction.sheet = nil
            }
            .padding(.horizontal, PlateInk.space(2))
            .padding(.top, PlateInk.space(2))
            Group {
                if let fault = interaction.fault, interaction.weekIndex.isEmpty {
                    errorState(fault)
                } else if interaction.weekIndex.isEmpty {
                    PlateEmpty(
                        image: "ocp_EmptyList",
                        headline: "No working boards",
                        line: "Commit a week from the Marey desk.",
                        actionTitle: "Open the desk",
                        action: { interaction.sheet = nil }
                    )
                } else {
                    List {
                        ForEach(interaction.weekIndex) { board in
                            Button {
                                interaction.openBoard(board)
                            } label: {
                                HStack {
                                    Text(board.isoWeek.daykey)
                                        .plateText(.token, category: sizeCategory)
                                        .lineLimit(1)
                                    Spacer()
                                    Text(OccupathFormatter.integer(board.occupations.count))
                                        .plateText(.figure, category: sizeCategory)
                                }
                                .frame(maxWidth: .infinity, minHeight: PlateInk.tap)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .listRowBackground(PlateInk.surface)
                            .accessibilityLabel("Working board \(board.isoWeek.daykey)")
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(PlateInk.background.ignoresSafeArea())
    }

    private func errorState(_ text: String) -> some View {
        VStack(alignment: .leading, spacing: PlateInk.space(2)) {
            Text(text)
                .plateText(.body, category: sizeCategory)
                .foregroundStyle(PlateInk.accent)
            PlatePrimaryButton(title: "Retry") {
                Task { await $interaction.retry() }
            }
        }
        .padding(PlateInk.space(2))
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}
