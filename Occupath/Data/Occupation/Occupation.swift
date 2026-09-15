import Foundation

/// Role: Data. Interval a holder occupies a single-line block. Computed from passing times.
struct Occupation: Identifiable, Hashable, Sendable, Codable, Equatable {
    var id: UUID
    var trainID: UUID
    var blockID: UUID
    var start: Double
    var end: Double

    init(
        id: UUID = UUID(),
        trainID: UUID,
        blockID: UUID,
        start: Double,
        end: Double
    ) {
        self.id = id
        self.trainID = trainID
        self.blockID = blockID
        self.start = start
        self.end = end
    }
}

func occupationsOverlap(_ lhs: Occupation, _ rhs: Occupation) -> Bool {
    lhs.blockID == rhs.blockID && lhs.start < rhs.end && rhs.start < lhs.end
}

func occupationInterval(train: Train, block: SingleLineBlock) -> (start: Double, end: Double)? {
    guard let first = train.seconds(at: block.fromMilepost),
          let second = train.seconds(at: block.toMilepost)
    else { return nil }
    return (min(first, second), max(first, second))
}
