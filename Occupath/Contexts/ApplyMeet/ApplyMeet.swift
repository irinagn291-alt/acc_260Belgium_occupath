import Foundation

/// Role: Data for one verb. Latest departure that returns the token before the later consist arrives.
struct MeetOffer: Identifiable, Hashable, Sendable, Equatable {
    var id: UUID
    var laterTrainID: UUID
    var earlierTrainID: UUID
    var blockID: UUID
    var tokenReturn: Double
    var rewritten: Train
}

/// Role: Data. A refused occupation — second consist on a held token, not a wash on a valid chart.
struct ConflictMark: Identifiable, Hashable, Sendable, Equatable {
    var trainID: UUID
    var blockID: UUID
    var start: Double
    var end: Double

    var id: String { "\(trainID.uuidString)-\(blockID.uuidString)" }
}

/// Role: Context. Binds LaterPath and Holder for one meet, then dies.
struct ApplyMeet {
    /// Role: the later consist whose path is rewritten.
    struct LaterPath {
        var train: Train
        var block: SingleLineBlock
        var heldOccupation: Occupation
        var holder: TokenHolder
        var board: WorkingTimetable

        func rewrite() -> Train? {
            guard let interval = occupationInterval(train: train, block: block) else { return nil }
            let delta = heldOccupation.end - interval.start
            var rewritten = train
            rewritten.passingTimes = train.passingTimes.map { stamp in
                PassingTime(
                    milepost: stamp.milepost,
                    secondsFromMidnight: stamp.secondsFromMidnight + delta
                )
            }
            return rewritten
        }

        func offer() -> MeetOffer? {
            guard let rewritten = rewrite() else { return nil }
            return MeetOffer(
                id: UUID(),
                laterTrainID: train.id,
                earlierTrainID: holder.trainID,
                blockID: block.id,
                tokenReturn: heldOccupation.end,
                rewritten: rewritten
            )
        }

        func accept() throws -> WorkingTimetable {
            guard let rewritten = rewrite() else { throw BoardError.tokenHeld }
            var next = try OccupyBlock.Occupier(train: rewritten, board: board).arrive()
            next = try HandToken.bind(blockID: block.id, on: next).issuedToken.release()
            let occupy = try OccupyBlock.bind(trainID: rewritten.id, blockID: block.id, on: next)
            return try occupy.occupier.take()
        }
    }

    /// Role: the consist that still holds the token.
    struct Holder {
        var tokenHolder: TokenHolder
    }

    var laterPath: LaterPath
    var holder: Holder
    var block: SingleLineBlock
    var board: WorkingTimetable

    static func bind(laterTrainID: UUID, blockID: UUID, on board: WorkingTimetable) -> ApplyMeet? {
        guard let later = board.train(id: laterTrainID),
              let block = board.block(id: blockID),
              let token = board.token(for: blockID),
              let tokenHolder = token.holder,
              tokenHolder.trainID != laterTrainID,
              let heldOccupation = board.occupations.first(where: {
                  $0.blockID == blockID && $0.trainID == tokenHolder.trainID
              }),
              occupationInterval(train: later, block: block) != nil
        else { return nil }
        return ApplyMeet(
            laterPath: LaterPath(
                train: later,
                block: block,
                heldOccupation: heldOccupation,
                holder: tokenHolder,
                board: board
            ),
            holder: Holder(tokenHolder: tokenHolder),
            block: block,
            board: board
        )
    }
}

func refusedOccupations(on board: WorkingTimetable) -> [ConflictMark] {
    var marks: [ConflictMark] = []
    for train in board.trains {
        for block in board.blocks {
            if board.occupations.contains(where: { $0.trainID == train.id && $0.blockID == block.id }) {
                continue
            }
            guard let interval = occupationInterval(train: train, block: block) else { continue }
            let proposed = Occupation(
                trainID: train.id,
                blockID: block.id,
                start: interval.start,
                end: interval.end
            )
            let holder = board.token(for: block.id)?.holder
            let held = holder != nil && holder?.trainID != train.id
            let overlap = board.occupations.contains { existing in
                existing.trainID != train.id && occupationsOverlap(existing, proposed)
            }
            if held || overlap {
                marks.append(
                    ConflictMark(
                        trainID: train.id,
                        blockID: block.id,
                        start: interval.start,
                        end: interval.end
                    )
                )
            }
        }
    }
    return marks
}
