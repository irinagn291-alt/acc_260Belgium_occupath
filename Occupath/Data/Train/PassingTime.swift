import Foundation

/// Role: Data. Instant a consist passes a milepost. Seconds from midnight, full precision.
struct PassingTime: Hashable, Sendable, Codable, Equatable {
    var milepost: String
    var secondsFromMidnight: Double
}
