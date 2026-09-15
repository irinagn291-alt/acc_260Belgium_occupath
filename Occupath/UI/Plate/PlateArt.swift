import SwiftUI

/// Role: Presentation. Catalog names for lithographed plate art. Images arrive later.
enum PlateArt {
    static let emptyHome = "ocp_EmptyHome"
    static let emptyList = "ocp_EmptyList"
    static let card = "ocp_CardBackdrop"
    static let control = "ocp_ControlFace"
    static let twist = "ocp_TwistHero"
    static let success = "ocp_SuccessMark"
    static let header = "ocp_HeaderDecor"
    static let splash = "ocp_Splash"

    static func onboarding(_ page: Int) -> String {
        switch page {
        case 0: return "ocp_Onboarding1"
        case 1: return "ocp_Onboarding2"
        default: return "ocp_Onboarding3"
        }
    }
}

/// Role: Presentation. Wide litho band above the Marey. Decorative; VoiceOver skips it.
struct PlateHeaderBand: View {
    var body: some View {
        Group {
            if UIImage(named: PlateArt.header) != nil {
                Image(PlateArt.header)
                    .resizable()
                    .scaledToFill()
            } else {
                Rectangle().fill(PlateInk.surface)
            }
        }
        .frame(height: PlateInk.space(5))
        .clipped()
        .accessibilityHidden(true)
    }
}

/// Role: Presentation. Brief success stamp after a board commit.
struct PlateFlash: View {
    var visible: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Group {
            if UIImage(named: PlateArt.success) != nil {
                Image(PlateArt.success)
                    .resizable()
                    .scaledToFit()
            } else {
                Circle().stroke(PlateInk.accent, lineWidth: 3)
            }
        }
        .frame(width: 128, height: 128)
        .opacity(visible ? 1 : 0)
        .animation(reduceMotion ? nil : PlateInk.motion, value: visible)
        .accessibilityHidden(true)
        .allowsHitTesting(false)
    }
}

/// Role: Presentation. Low-contrast card paper behind inspector figures.
struct PlateCardBackdrop: View {
    var body: some View {
        Group {
            if UIImage(named: PlateArt.card) != nil {
                Image(PlateArt.card)
                    .resizable()
                    .scaledToFill()
                    .opacity(0.35)
            } else {
                PlateInk.surface
            }
        }
        .clipped()
        .accessibilityHidden(true)
    }
}
