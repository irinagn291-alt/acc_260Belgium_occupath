import Foundation

/// Role: Data. Failures of desk verbs. Never crash the graph.
enum BoardError: Error, Equatable, Sendable {
    case emptyName
    case emptyMilepost
    case sameMilepost
    case invalidTape
    case invalidAngle
    case invalidLength
    case invalidTime
    case invalidInterval
    case unknownTrain
    case unknownBlock
    case duplicateBlock
    case missingPassingTimes
    case tokenHeld
}

/// Role: Data. Session — one working timetable for an ISO week. In-memory source of truth.
struct WorkingTimetable: Identifiable, Hashable, Sendable, Codable, Equatable {
    var id: UUID
    var isoWeek: ISOWeekDate
    var trains: [Train]
    var blocks: [SingleLineBlock]
    var tokens: [Token]
    var occupations: [Occupation]

    init(
        id: UUID = UUID(),
        isoWeek: ISOWeekDate,
        trains: [Train] = [],
        blocks: [SingleLineBlock] = [],
        tokens: [Token] = [],
        occupations: [Occupation] = []
    ) {
        self.id = id
        self.isoWeek = isoWeek
        self.trains = trains
        self.blocks = blocks
        self.tokens = tokens
        self.occupations = occupations
    }

    func train(id: UUID) -> Train? {
        trains.first(where: { $0.id == id })
    }

    func block(id: UUID) -> SingleLineBlock? {
        blocks.first(where: { $0.id == id })
    }

    func token(for blockID: UUID) -> Token? {
        tokens.first(where: { $0.blockID == blockID })
    }
}

func openingBoard(id: UUID = UUID(), isoWeek: ISOWeekDate) -> WorkingTimetable {
    WorkingTimetable(id: id, isoWeek: isoWeek)
}

