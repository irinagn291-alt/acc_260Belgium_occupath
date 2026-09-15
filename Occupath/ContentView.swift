import SwiftUI

/// Role: Presentation. Host. Marey stays home; ledger and settings arrive as sheets.
struct ContentView: View {
    @Binding var interaction: DeskInteraction
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    init(interaction: Binding<DeskInteraction> = .constant(.previewPopulated())) {
        self._interaction = interaction
    }

    var body: some View {
        Group {
            if interaction.onboarded {
                deskRoot
            } else {
                OnboardingView(interaction: $interaction)
            }
        }
        .preferredColorScheme(.light)
        .task { await $interaction.appear() }
        .onChange(of: scenePhase) { _, phase in
            if phase == .inactive || phase == .background {
                Task { await $interaction.flush() }
            }
        }
        .fullScreenCover(item: sheetBinding) { sheet in
            switch sheet {
            case .ledger:
                WeekLedgerView(interaction: $interaction)
            case .settings:
                SettingsView(interaction: $interaction)
            case .inspector:
                NavigationStack {
                    InspectorColumn(interaction: $interaction, showsClose: true)
                }
            case .meet:
                MeetSheet(interaction: $interaction)
            case .measurement:
                MeasurementSheet(interaction: $interaction)
            case .path:
                PathSheet(interaction: $interaction)
            case .onboarding:
                OnboardingView(interaction: $interaction)
            case .token:
                TokenOccupationView(interaction: $interaction)
            }
        }
    }

    private var deskRoot: some View {
        Group {
            if horizontalSizeClass == .regular {
                NavigationSplitView {
                    InspectorColumn(interaction: $interaction)
                } detail: {
                    polishedDesk
                }
            } else {
                polishedDesk
            }
        }
    }

    private var polishedDesk: some View {
        MareyDeskView(interaction: $interaction)
            .overlay { PlateFlash(visible: interaction.commitFlash) }
    }

    private var sheetBinding: Binding<DeskSheet?> {
        Binding(
            get: { interaction.sheet },
            set: { next in
                if next == nil {
                    interaction.sheet = nil
                }
            }
        )
    }
}

#Preview {
    ContentView()
}
