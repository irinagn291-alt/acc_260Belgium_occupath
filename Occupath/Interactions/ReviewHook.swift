import Foundation

/// Role: Interaction. `-ReviewScreen today|log|goals`. Read once, only after onboarding.
enum ReviewHook: String, Equatable, Sendable {
    case today
    case log
    case goals

    static func consume(
        arguments: [String],
        onboarded: Bool,
        consumed: inout Bool
    ) -> ReviewHook? {
        guard onboarded, !consumed else { return nil }
        consumed = true
        guard let index = arguments.firstIndex(of: "-ReviewScreen") else { return nil }
        let next = arguments.index(after: index)
        guard arguments.indices.contains(next) else { return nil }
        return ReviewHook(rawValue: arguments[next])
    }
}
