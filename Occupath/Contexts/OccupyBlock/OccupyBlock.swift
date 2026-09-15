import Foundation

/// Role: Context. Binds Occupier to IssuedToken and Block for one take, then dies.
struct OccupyBlock {
    /// Role: the consist that arrives and takes the bound token.
    struct Occupier {
        var train: Train
        var issuedToken: IssuedToken
        var block: SingleLineBlock
        var board: WorkingTimetable

        init(train: Train, issuedToken: IssuedToken, block: SingleLineBlock, board: WorkingTimetable) {
            self.train = train
            self.issuedToken = issuedToken
            self.block = block
            self.board = board
        }

        /// Occupier playing arrival — token roles are bound when OccupyBlock.bind runs.
        init(train: Train, board: WorkingTimetable) {
            self.train = train
            self.board = board
            self.issuedToken = IssuedToken(token: Token(blockID: board.id, holderID: nil), holder: nil)
            self.block = SingleLineBlock(fromMilepost: "·", toMilepost: "··", tape: 1, clino: 0, brg: 0)
        }

        func arrive() throws -> WorkingTimetable {
            try validateTrain(train)
            var next = board
            if let index = next.trains.firstIndex(where: { $0.id == train.id }) {
                next.trains[index] = train
            } else {
                next.trains.append(train)
            }
            return next
        }

        func take(occupationID: UUID = UUID()) throws -> WorkingTimetable {
            if issuedToken.held(byOtherThan: train.id) {
                throw BoardError.tokenHeld
            }
            guard let interval = occupationInterval(train: train, block: block) else {
                throw BoardError.missingPassingTimes
            }
            guard interval.start < interval.end else { throw BoardError.invalidInterval }

            let occupation = Occupation(
                id: occupationID,
                trainID: train.id,
                blockID: block.id,
                start: interval.start,
                end: interval.end
            )
            if board.occupations.contains(where: { existing in
                existing.trainID != train.id && occupationsOverlap(existing, occupation)
            }) {
                throw BoardError.tokenHeld
            }

            let nextToken = issuedToken.issued(to: train.id)
            var next = board
            next.tokens = board.tokens.map { $0.blockID == block.id ? nextToken : $0 }
            next.occupations.append(occupation)
            return next
        }
    }

    /// Role: the one token the block has issued. Plays for the life of this Context.
    struct IssuedToken {
        var token: Token
        var holder: TokenHolder?

        func held(byOtherThan trainID: UUID) -> Bool {
            guard let holder else { return false }
            return holder.trainID != trainID
        }

        func issued(to trainID: UUID) -> Token {
            var next = token
            next.holderID = trainID
            return next
        }
    }

    var occupier: Occupier
    var issuedToken: IssuedToken
    var block: SingleLineBlock
    var board: WorkingTimetable

    static func bind(trainID: UUID, blockID: UUID, on board: WorkingTimetable) throws -> OccupyBlock {
        guard let train = board.train(id: trainID) else { throw BoardError.unknownTrain }
        guard let block = board.block(id: blockID) else { throw BoardError.unknownBlock }
        guard let token = board.token(for: blockID) else { throw BoardError.unknownBlock }
        let issued = IssuedToken(token: token, holder: token.holder)
        let occupier = Occupier(train: train, issuedToken: issued, block: block, board: board)
        return OccupyBlock(occupier: occupier, issuedToken: issued, block: block, board: board)
    }
}
