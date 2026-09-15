import Foundation

/// Role: Data. Subject — a named consist. Path is passing times, not a row. Views never mutate.
struct Train: Identifiable, Hashable, Sendable, Codable, Equatable {
    var id: UUID
    var name: String
    var length: Double
    var passingTimes: [PassingTime]

    init(
        id: UUID = UUID(),
        name: String,
        length: Double,
        passingTimes: [PassingTime] = []
    ) {
        self.id = id
        self.name = name
        self.length = length
        self.passingTimes = passingTimes
    }

    func seconds(at milepost: String) -> Double? {
        passingTimes.first(where: { $0.milepost == milepost })?.secondsFromMidnight
    }
}

func validateTrain(_ train: Train) throws {
    guard !train.name.isEmpty else { throw BoardError.emptyName }
    guard train.length.isFinite, train.length > 0 else { throw BoardError.invalidLength }
    for stamp in train.passingTimes {
        guard !stamp.milepost.isEmpty else { throw BoardError.emptyMilepost }
        guard stamp.secondsFromMidnight.isFinite else { throw BoardError.invalidTime }
    }
}
