import XCTest
@testable import Occupath

final class TokenMarkTests: XCTestCase {
    func test_heldAndFreeHaveDifferentVoiceOverCopy() {
        let block = SingleLineBlock(fromMilepost: "MP10", toMilepost: "MP20", tape: 10, clino: 0, brg: 0)
        XCTAssertEqual(
            TokenMarkCopy.label(holderName: "Pilot", block: block),
            "Token held by Pilot on MP10 to MP20"
        )
        XCTAssertEqual(
            TokenMarkCopy.label(holderName: nil, block: block),
            "Token at the block MP10 to MP20"
        )
        XCTAssertNotEqual(
            TokenMarkCopy.label(holderName: "Pilot", block: block),
            TokenMarkCopy.label(holderName: nil, block: block)
        )
    }

    func test_tokenPointLivesOnThePlateMath() {
        let published = OccupationInk.published(from: DeskSeed.legalOccupationBoard())
        let token = published.board.tokens.first { $0.holderID != nil }
        let point = token.flatMap { MareyPlate.tokenPoint(token: $0, in: MareyPlate.contentSize, published: published) }
        XCTAssertNotNil(point)
        XCTAssertGreaterThan(point?.x ?? 0, 0)
        XCTAssertGreaterThan(point?.y ?? 0, 0)
    }
}
