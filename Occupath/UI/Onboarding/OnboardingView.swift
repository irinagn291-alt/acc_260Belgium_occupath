import SwiftUI

/// Role: Presentation. Four plates. Skip still writes the completion flag.
struct OnboardingView: View {
    @Binding var interaction: DeskInteraction
    @State private var page = 0
    @Environment(\.sizeCategory) private var sizeCategory
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(interaction: Binding<DeskInteraction> = .constant(.previewEmpty())) {
        self._interaction = interaction
    }

    var body: some View {
        VStack(spacing: 0) {
            pageBlock
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .animation(reduceMotion ? nil : PlateInk.motion, value: page)
            bottomBar
        }
        .padding(.horizontal, PlateInk.space(2))
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(PlateInk.background.ignoresSafeArea())
    }

    @ViewBuilder
    private var pageBlock: some View {
        switch page {
        case 0:
            pageView(
                image: "ocp_Onboarding1",
                title: "Paint the path",
                line: "Time runs down, distance runs across. The Marey is the occupation, not a train list."
            )
        case 1:
            pageView(
                image: "ocp_Onboarding2",
                title: "Hand the token",
                line: "A single-line block issues one token. A second consist is refused until you hand it."
            )
        case 2:
            pageView(
                image: "ocp_Onboarding3",
                title: "Close the loop",
                line: "Tape, clino and bearing reduce to a traverse. The board clears only when the loop holds the shorter consist."
            )
        default:
            pageView(
                image: "ocp_TwistHero",
                title: "Commit the week",
                line: "Accept a meet to rewrite the later path. Commit the working board and open the next ISO week."
            )
        }
    }

    private var bottomBar: some View {
        VStack(spacing: PlateInk.space(1)) {
            PlatePrimaryButton(title: page < 3 ? "Next" : "Open the desk") {
                if page < 3 {
                    page += 1
                } else {
                    interaction.finishOnboarding()
                }
            }
            Button {
                interaction.finishOnboarding()
            } label: {
                Text("Skip")
                    .plateText(.token, category: sizeCategory)
                    .frame(maxWidth: .infinity, minHeight: PlateInk.tap)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Skip")
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, PlateInk.space(2))
    }

    private func pageView(image: String, title: String, line: String) -> some View {
        VStack(spacing: PlateInk.space(2)) {
            Group {
                if UIImage(named: image) != nil {
                    Image(image)
                        .resizable()
                        .scaledToFit()
                } else {
                    Rectangle()
                        .fill(PlateInk.surface)
                        .overlay(Rectangle().stroke(PlateInk.muted.opacity(0.4), lineWidth: 1))
                }
            }
            .frame(maxWidth: .infinity)
            .accessibilityHidden(true)
            Text(title)
                .plateText(.plate, category: sizeCategory)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
            Text(line)
                .plateText(.body, category: sizeCategory)
                .foregroundStyle(PlateInk.muted)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding(.top, PlateInk.space(2))
    }
}
