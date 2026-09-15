import Foundation

/// Role: Data. One token issued by a single-line block. Occupation is legal only for the holder.
struct Token: Hashable, Sendable, Codable, Equatable {
    var blockID: UUID
    var holderID: UUID?
}

/// Role: Data. The consist currently holding a block's token.
struct TokenHolder: Hashable, Sendable, Equatable {
    var trainID: UUID
    var blockID: UUID
}

extension Token {
    var holder: TokenHolder? {
        guard let holderID else { return nil }
        return TokenHolder(trainID: holderID, blockID: blockID)
    }
}
