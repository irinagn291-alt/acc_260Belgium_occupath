import SwiftUI
import UIKit

/// Role: Presentation. Palette, DIN Condensed scale, and spacing live only here.
enum PlateInk {
    static let background = Color("ocp_background")
    static let surface = Color("ocp_surface")
    static let ink = Color("ocp_ink")
    static let accent = Color("ocp_accent")
    static let muted = Color("ocp_muted")
    static let face = "DIN Condensed"
    static let boldPostScript = "DINCondensed-Bold"
    static let regularPostScript = "DINCondensed-Regular"

    static let unit: CGFloat = 8
    static let tap: CGFloat = 44
    static let motion = Animation.easeInOut(duration: 0.28)

    static var backgroundUI: UIColor { named("ocp_background", red: 243, green: 237, blue: 224) }
    static var surfaceUI: UIColor { named("ocp_surface", red: 250, green: 246, blue: 234) }
    static var inkUI: UIColor { named("ocp_ink", red: 27, green: 25, blue: 20) }
    static var accentUI: UIColor { named("ocp_accent", red: 192, green: 23, blue: 43) }
    static var mutedUI: UIColor { named("ocp_muted", red: 95, green: 107, blue: 88) }

    static func space(_ steps: Int) -> CGFloat {
        unit * CGFloat(steps)
    }

    enum Step: CaseIterable {
        case plate
        case figure
        case token
        case body
        case caption
        case stamp

        var size: CGFloat {
            switch self {
            case .plate: return 28
            case .figure: return 22
            case .token: return 18
            case .body: return 17
            case .caption: return 13
            case .stamp: return 11
            }
        }

        var style: Font.TextStyle {
            switch self {
            case .plate: return .title
            case .figure: return .title2
            case .token: return .headline
            case .body: return .body
            case .caption: return .caption
            case .stamp: return .caption2
            }
        }

        var postScript: String {
            switch self {
            case .plate, .figure, .token:
                return PlateInk.boldPostScript
            case .body, .caption, .stamp:
                return PlateInk.regularPostScript
            }
        }
    }

    static func font(_ step: Step, sizeCategory: ContentSizeCategory) -> Font {
        if sizeCategory >= .accessibilityMedium {
            return .system(step.style).width(.condensed)
        }
        return .custom(step.postScript, size: step.size, relativeTo: step.style)
    }

    private static func named(_ name: String, red: CGFloat, green: CGFloat, blue: CGFloat) -> UIColor {
        UIColor(named: name) ?? UIColor(red: red / 255, green: green / 255, blue: blue / 255, alpha: 1)
    }
}

/// Role: Presentation. Locale-aware clock. Round only at display.
enum PlayheadClock {
    static func label(_ seconds: Double, locale: Locale = .current) -> String {
        let total = max(0, Int(seconds.rounded()))
        let hours = twoDigits(total / 3600, locale: locale)
        let minutes = twoDigits((total % 3600) / 60, locale: locale)
        return "\(hours):\(minutes)"
    }

    private static func twoDigits(_ value: Int, locale: Locale) -> String {
        let formatter = NumberFormatter()
        formatter.locale = locale
        formatter.numberStyle = .decimal
        formatter.minimumIntegerDigits = 2
        formatter.maximumFractionDigits = 0
        formatter.usesGroupingSeparator = false
        return formatter.string(from: NSNumber(value: value)) ?? "—"
    }
}

func plateCopy(_ error: Error) -> String {
    guard let board = error as? BoardError else {
        return "The desk could not finish that verb."
    }
    switch board {
    case .emptyName: return "A consist needs a name."
    case .emptyMilepost: return "Mileposts cannot be blank."
    case .sameMilepost: return "A block needs two different mileposts."
    case .invalidTape: return "Tape must be a positive length."
    case .invalidAngle: return "Clino and bearing must be finite."
    case .invalidLength: return "Train length must be positive."
    case .invalidTime: return "Passing time is not a number."
    case .invalidInterval: return "Passing times must open an interval."
    case .unknownTrain: return "That consist is not on this board."
    case .unknownBlock: return "That block is not on this board."
    case .duplicateBlock: return "This block is already on the plate."
    case .missingPassingTimes: return "The path needs times at both mileposts."
    case .tokenHeld: return "The token is still out."
    }
}

func parseDecimal(_ text: String, locale: Locale = .current) -> Double? {
    let formatter = NumberFormatter()
    formatter.locale = locale
    formatter.numberStyle = .decimal
    return formatter.number(from: text.trimmingCharacters(in: .whitespaces))?.doubleValue
}

func parseClock(_ text: String, locale: Locale = .current) -> Double? {
    let trimmed = text.trimmingCharacters(in: .whitespaces)
    let parts = trimmed.split(separator: ":")
    if parts.count == 2, let hours = Int(parts[0]), let minutes = Int(parts[1]),
       (0 ... 23).contains(hours), (0 ... 59).contains(minutes)
    {
        return Double(hours * 3_600 + minutes * 60)
    }
    return parseDecimal(trimmed, locale: locale)
}

extension View {
    func plateText(_ step: PlateInk.Step, category: ContentSizeCategory) -> some View {
        font(PlateInk.font(step, sizeCategory: category))
            .foregroundStyle(PlateInk.ink)
    }

    func plateTap() -> some View {
        frame(minWidth: PlateInk.tap, minHeight: PlateInk.tap, alignment: .center)
            .contentShape(Rectangle())
    }
}

/// Role: Presentation. Title + Close live in the body so a snapshot sees them.
struct PlateSheetHeader: View {
    var title: String
    var close: () -> Void
    @Environment(\.sizeCategory) private var sizeCategory

    var body: some View {
        HStack(alignment: .center, spacing: PlateInk.space(1)) {
            Text(title)
                .plateText(.plate, category: sizeCategory)
                .lineLimit(2)
                .minimumScaleFactor(0.7)
            Spacer(minLength: PlateInk.space(1))
            Button(action: close) {
                Text("Close")
                    .plateText(.token, category: sizeCategory)
                    .padding(.horizontal, PlateInk.space(2))
                    .frame(minWidth: PlateInk.tap, minHeight: PlateInk.tap)
                    .background(PlateInk.surface)
                    .overlay(Rectangle().stroke(PlateInk.ink, lineWidth: 1.5))
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Close")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// Role: Presentation. Ink-stroked 44pt well. Chrome lives inside the label.
struct PlateInkWell: View {
    var system: String

    var body: some View {
        Image(systemName: system)
            .foregroundStyle(PlateInk.ink)
            .frame(width: PlateInk.tap, height: PlateInk.tap)
            .overlay(Rectangle().stroke(PlateInk.ink, lineWidth: 1.5))
            .contentShape(Rectangle())
    }
}

/// Role: Presentation. Full-width stroked row. Hit is the whole fill.
struct PlateStrokeRow<Content: View>: View {
    var accent: Bool = false
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .frame(maxWidth: .infinity, minHeight: PlateInk.tap, alignment: .leading)
            .padding(.horizontal, PlateInk.space(2))
            .background(PlateInk.surface)
            .overlay(Rectangle().stroke(accent ? PlateInk.accent : PlateInk.ink, lineWidth: 1.5))
            .contentShape(Rectangle())
    }
}

/// Role: Presentation. Full-width filled CTA. Chrome is inside the label.
struct PlatePrimaryButton: View {
    var title: String
    var action: () -> Void
    @Environment(\.sizeCategory) private var sizeCategory

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(PlateInk.font(.token, sizeCategory: sizeCategory))
                .foregroundStyle(Color(uiColor: PlateInk.surfaceUI))
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity, minHeight: PlateInk.tap)
                .background(Color(uiColor: PlateInk.inkUI))
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
