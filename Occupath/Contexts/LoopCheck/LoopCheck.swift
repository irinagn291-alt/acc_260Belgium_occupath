import Foundation

/// Role: Context. Binds Traverse, Consist, and Surveyor for one loop check, then dies.
struct LoopCheck {
    /// Role: the reduced tape/clino/brg walk.
    struct Traverse {
        var blocks: [SingleLineBlock]

        func close() -> [ClosedLoop] {
            LoopClosure.cycles(in: blocks)
        }
    }

    /// Role: the consists that must fit the loop.
    struct Consist {
        var trains: [Train]

        func feasible(loopLen: Double) -> Bool {
            guard let shorter = trains.map(\.length).min() else { return true }
            return Self.feasible(loopLen: loopLen, shorterTrain: shorter)
        }

        static func feasible(loopLen: Double, shorterTrain: Double) -> Bool {
            loopLen.isFinite && shorterTrain.isFinite && loopLen >= shorterTrain
        }
    }

    /// Role: the desk entering a measurement. Plays against the bound board.
    struct Surveyor {
        var board: WorkingTimetable

        func record(_ block: SingleLineBlock) throws -> WorkingTimetable {
            try validateBlock(block)
            guard !board.blocks.contains(where: { $0.id == block.id }) else {
                throw BoardError.duplicateBlock
            }
            var next = board
            next.blocks.append(block)
            next.tokens.append(Token(blockID: block.id, holderID: nil))
            return next
        }
    }

    var traverse: Traverse
    var consist: Consist
    var surveyor: Surveyor

    init(blocks: [SingleLineBlock], trains: [Train] = [], board: WorkingTimetable? = nil) {
        traverse = Traverse(blocks: blocks)
        consist = Consist(trains: trains)
        surveyor = Surveyor(
            board: board ?? WorkingTimetable(isoWeek: ISOWeekDate(year: 2026, week: 35), trains: trains, blocks: blocks)
        )
    }

    static func bind(blocks: [SingleLineBlock], trains: [Train] = []) -> LoopCheck {
        LoopCheck(blocks: blocks, trains: trains)
    }

    static func bind(_ board: WorkingTimetable) -> LoopCheck {
        LoopCheck(blocks: board.blocks, trains: board.trains, board: board)
    }

    static func loopFeasible(loopLen: Double, shorterTrain: Double) -> Bool {
        Consist.feasible(loopLen: loopLen, shorterTrain: shorterTrain)
    }

    static func loopFeasible(loopLen: Double, trains: [Train]) -> Bool {
        Consist(trains: trains).feasible(loopLen: loopLen)
    }
}
