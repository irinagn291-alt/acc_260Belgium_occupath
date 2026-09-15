import XCTest
@testable import Occupath

@MainActor
final class DeskInteractionTests: XCTestCase {
    func test_interactionStartsContextAndDoesNotMutateThroughViews() throws {
        var desk = DeskInteraction.previewEmpty()
        XCTAssertTrue(desk.published.board.occupations.isEmpty)
        let block = SingleLineBlock(fromMilepost: "A", toMilepost: "B", tape: 10, clino: 0, brg: 0)
        desk.adopt(try LoopCheck.bind(desk.board).surveyor.record(block))
        XCTAssertEqual(desk.published.board.blocks.count, 1)
        let train = Train(
            name: "Pilot",
            length: 8,
            passingTimes: [
                PassingTime(milepost: "A", secondsFromMidnight: 10),
                PassingTime(milepost: "B", secondsFromMidnight: 20),
            ]
        )
        var next = try OccupyBlock.Occupier(train: train, board: desk.board).arrive()
        let occupy = try OccupyBlock.bind(trainID: train.id, blockID: block.id, on: next)
        next = try occupy.occupier.take()
        desk.adopt(next)
        XCTAssertEqual(desk.published.board.occupations.count, 1)
        XCTAssertEqual(desk.published.tokenHops, 1)
        XCTAssertEqual(desk.published.board.tokens.first?.holderID, desk.published.board.trains.first?.id)
    }

    func test_reviewHookOpensLedgerAfterOnboarding() {
        var desk = DeskInteraction.previewPopulated()
        var consumed = false
        XCTAssertEqual(
            ReviewHook.consume(
                arguments: ["-ReviewScreen", "log"],
                onboarded: desk.onboarded,
                consumed: &consumed
            ),
            .log
        )
        desk.sheet = .ledger
        XCTAssertEqual(desk.sheet, .ledger)
        desk.sheet = .settings
        XCTAssertEqual(desk.sheet, .settings)
        desk.sheet = .token
        XCTAssertEqual(desk.sheet, .token)
    }

    func test_occupyBlockBindsRolesAndDiesLeavingBoardUnchanged() throws {
        let week = ISOWeekDate(year: 2026, week: 35)
        let block = SingleLineBlock(fromMilepost: "A", toMilepost: "B", tape: 10, clino: 0, brg: 0)
        var board = try surveyLeg(block, on: openingBoard(isoWeek: week))
        let train = Train(
            name: "Pilot",
            length: 8,
            passingTimes: [
                PassingTime(milepost: "A", secondsFromMidnight: 10),
                PassingTime(milepost: "B", secondsFromMidnight: 20),
            ]
        )
        board = try arrive(train, on: board)
        let context = try OccupyBlock.bind(trainID: train.id, blockID: block.id, on: board)
        XCTAssertEqual(context.occupier.train.id, train.id)
        XCTAssertEqual(context.block.id, block.id)
        XCTAssertEqual(context.issuedToken.token.blockID, block.id)
        XCTAssertNil(context.issuedToken.holder)
        let next = try context.occupier.take()
        XCTAssertTrue(board.occupations.isEmpty)
        XCTAssertNil(board.token(for: block.id)?.holder)
        XCTAssertEqual(next.occupations.count, 1)
        XCTAssertEqual(next.token(for: block.id)?.holder, TokenHolder(trainID: train.id, blockID: block.id))
        XCTAssertEqual(
            try HandToken.bind(blockID: block.id, on: next).holder?.tokenHolder,
            TokenHolder(trainID: train.id, blockID: block.id)
        )
    }

    func test_swiftUIStartsContextAndRunsOccupierRole() throws {
        var desk = DeskInteraction.previewEmpty()
        let recorded = SingleLineBlock(fromMilepost: "A", toMilepost: "B", tape: 10, clino: 0, brg: 0)
        desk.adopt(try LoopCheck.bind(desk.board).surveyor.record(recorded))
        let train = Train(
            name: "Pilot",
            length: 8,
            passingTimes: [
                PassingTime(milepost: "A", secondsFromMidnight: 10),
                PassingTime(milepost: "B", secondsFromMidnight: 20),
            ]
        )
        desk.board = try arrive(train, on: desk.board)
        let block = try XCTUnwrap(desk.board.blocks.first)
        let context = try OccupyBlock.bind(trainID: train.id, blockID: block.id, on: desk.board)
        desk.adopt(try context.occupier.take())
        XCTAssertEqual(desk.published.board.occupations.count, 1)
        XCTAssertEqual(desk.published.board.token(for: block.id)?.holder?.trainID, train.id)
    }

    func test_publishedLoopUsesFamilyCalculator() {
        let desk = DeskInteraction.previewPopulated()
        XCTAssertEqual(desk.published.loops.count, 1)
        XCTAssertEqual(desk.published.loops.first?.relativeError ?? 1, 0, accuracy: 1e-9)
        XCTAssertTrue(desk.published.loopFeasible)
        XCTAssertFalse(desk.published.stations.isEmpty)
    }
}
