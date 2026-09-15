import Foundation

/// Role: Data. Measurement — one single-line block. Tape/clino/brg is the desk reading.
struct SingleLineBlock: Identifiable, Hashable, Sendable, Codable, Equatable {
    var id: UUID
    var fromMilepost: String
    var toMilepost: String
    var tape: Double
    var clino: Double
    var brg: Double

    init(
        id: UUID = UUID(),
        fromMilepost: String,
        toMilepost: String,
        tape: Double,
        clino: Double,
        brg: Double
    ) {
        self.id = id
        self.fromMilepost = fromMilepost
        self.toMilepost = toMilepost
        self.tape = tape
        self.clino = clino
        self.brg = brg
    }
}

func validateBlock(_ block: SingleLineBlock) throws {
    guard !block.fromMilepost.isEmpty, !block.toMilepost.isEmpty else {
        throw BoardError.emptyMilepost
    }
    guard block.fromMilepost != block.toMilepost else { throw BoardError.sameMilepost }
    guard block.tape.isFinite, block.tape > 0 else { throw BoardError.invalidTape }
    guard block.clino.isFinite, block.brg.isFinite else { throw BoardError.invalidAngle }
}
