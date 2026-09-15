import Foundation

/// Role: Persistence. JSON envelope for one working timetable. Data never sees this type.
struct TimetableDocument: Codable, Equatable, Sendable {
    var schemaVersion: Int
    var id: UUID
    var isoWeek: String
    var trains: [Train]
    var blocks: [SingleLineBlock]
    var tokens: [Token]
    var occupations: [Occupation]
}

/// Role: Persistence. Schema switch and board ↔ document mapping. No FileManager.
enum TimetableCodec {
    static let currentSchema = 1

    enum Failure: Error, Equatable {
        case unsupportedSchema(Int)
        case corrupt
    }

    static func document(from board: WorkingTimetable) -> TimetableDocument {
        TimetableDocument(
            schemaVersion: currentSchema,
            id: board.id,
            isoWeek: board.isoWeek.daykey,
            trains: board.trains,
            blocks: board.blocks,
            tokens: board.tokens,
            occupations: board.occupations
        )
    }

    static func board(from document: TimetableDocument) -> WorkingTimetable? {
        guard let isoWeek = ISOWeekDate.parse(daykey: document.isoWeek) else { return nil }
        return WorkingTimetable(
            id: document.id,
            isoWeek: isoWeek,
            trains: document.trains,
            blocks: document.blocks,
            tokens: document.tokens,
            occupations: document.occupations
        )
    }

    static func encode(_ board: WorkingTimetable) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        return try encoder.encode(document(from: board))
    }

    static func decode(_ data: Data) throws -> WorkingTimetable {
        let decoder = JSONDecoder()
        let probe: SchemaProbe
        do {
            probe = try decoder.decode(SchemaProbe.self, from: data)
        } catch {
            throw Failure.corrupt
        }
        switch probe.schemaVersion {
        case 1:
            do {
                let document = try decoder.decode(TimetableDocument.self, from: data)
                guard let board = board(from: document) else { throw Failure.corrupt }
                return board
            } catch let failure as Failure {
                throw failure
            } catch {
                throw Failure.corrupt
            }
        default:
            throw Failure.unsupportedSchema(probe.schemaVersion)
        }
    }
}

private struct SchemaProbe: Decodable {
    var schemaVersion: Int
}
