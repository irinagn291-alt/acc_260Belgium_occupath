import Foundation

/// Role: Context. Binds Holder to IssuedToken for one return, then dies.
struct HandToken {
    /// Role: the consist returning the bound token.
    struct Holder {
        var tokenHolder: TokenHolder
        var issuedToken: IssuedToken

        func returnToken() -> WorkingTimetable {
            issuedToken.release()
        }
    }

    /// Role: the token sitting on the block. Plays for the life of this Context.
    struct IssuedToken {
        var token: Token
        var block: SingleLineBlock
        var board: WorkingTimetable

        func release() -> WorkingTimetable {
            var next = board
            next.tokens = board.tokens.map { item in
                var copy = item
                if copy.blockID == block.id {
                    copy.holderID = nil
                }
                return copy
            }
            return next
        }
    }

    var holder: Holder?
    var issuedToken: IssuedToken
    var block: SingleLineBlock
    var board: WorkingTimetable

    static func bind(blockID: UUID, on board: WorkingTimetable) throws -> HandToken {
        guard let block = board.block(id: blockID) else { throw BoardError.unknownBlock }
        guard let token = board.token(for: blockID) else { throw BoardError.unknownBlock }
        let issued = IssuedToken(token: token, block: block, board: board)
        let holder = token.holder.map { Holder(tokenHolder: $0, issuedToken: issued) }
        return HandToken(holder: holder, issuedToken: issued, block: block, board: board)
    }
}
