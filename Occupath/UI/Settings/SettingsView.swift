import SwiftUI

/// Role: Presentation. Contact, re-run onboarding, reset. ReviewScreen goals.
struct SettingsView: View {
    @Binding var interaction: DeskInteraction
    @State private var confirmReset = false
    @Environment(\.sizeCategory) private var sizeCategory

    init(interaction: Binding<DeskInteraction> = .constant(.previewPopulated())) {
        self._interaction = interaction
    }

    var body: some View {
        VStack(alignment: .leading, spacing: PlateInk.space(2)) {
            PlateSheetHeader(title: "Settings") {
                interaction.sheet = nil
            }
            if let fault = interaction.fault {
                Text(fault)
                    .plateText(.body, category: sizeCategory)
                    .foregroundStyle(PlateInk.accent)
                PlatePrimaryButton(title: "Retry") {
                    Task { await $interaction.retry() }
                }
            }
            Text("Working boards stay on this device. One token per single-line block.")
                .plateText(.body, category: sizeCategory)
            if let url = URL(string: "https://occupath.pro/contact-us") {
                Link(destination: url) {
                    PlateStrokeRow {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Contact Occupath")
                                .plateText(.token, category: sizeCategory)
                                .foregroundStyle(PlateInk.accent)
                            Text(url.absoluteString)
                                .plateText(.caption, category: sizeCategory)
                                .foregroundStyle(PlateInk.muted)
                        }
                    }
                }
                .buttonStyle(.plain)
            }
            PlatePrimaryButton(title: "Re-run onboarding") {
                interaction.reopenOnboarding()
            }
            Button(role: .destructive) {
                confirmReset = true
            } label: {
                PlateStrokeRow(accent: true) {
                    Text("Reset all data")
                        .plateText(.token, category: sizeCategory)
                        .foregroundStyle(PlateInk.accent)
                }
            }
            .buttonStyle(.plain)
            .disabled(interaction.commitBusy)
            Spacer(minLength: 0)
        }
        .padding(PlateInk.space(2))
        .frame(maxWidth: 560, alignment: .leading)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(PlateInk.background.ignoresSafeArea())
        .confirmationDialog("Clear every working board?", isPresented: $confirmReset, titleVisibility: .visible) {
            Button("Reset all data", role: .destructive) {
                Task { await $interaction.resetAll() }
            }
            Button("Cancel", role: .cancel) {}
        }
    }
}
