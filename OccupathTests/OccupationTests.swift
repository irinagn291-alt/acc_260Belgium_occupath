import XCTest
@testable import Occupath

/// Primary verb: take or hand the token. Twist: one token per block; loopFeasible iff loopLen >= shorter.
final class OccupationTests: XCTestCase {
    private let week = ISOWeekDate(year: 2026, week: 35)

    func test_occupy_emptyPopulatedInvalid() throws {
        let empty = openingBoard(isoWeek: week)
        XCTAssertTrue(empty.trains.isEmpty)
        XCTAssertTrue(empty.occupations.isEmpty)

        let block = SingleLineBlock(fromMilepost: "MP10", toMilepost: "MP20", tape: 10, clino: 0, brg: 0)
        var board = try surveyLeg(block, on: empty)
        let train = Train(
            name: "Pilot",
            length: 8,
            passingTimes: [
                PassingTime(milepost: "MP10", secondsFromMidnight: 36_000),
                PassingTime(milepost: "MP20", secondsFromMidnight: 36_600),
            ]
        )
        board = try arrive(train, on: board)
        let held = try occupierTakes(trainID: train.id, blockID: block.id, on: board)
        XCTAssertEqual(held.occupations.count, 1)
        XCTAssertEqual(held.token(for: block.id)?.holderID, train.id)
        XCTAssertEqual(held.occupations[0].start, 36_000)
        XCTAssertEqual(held.occupations[0].end, 36_600)

        let late = Train(
            name: "Relief",
            length: 6,
            passingTimes: [
                PassingTime(milepost: "MP10", secondsFromMidnight: 36_300),
                PassingTime(milepost: "MP20", secondsFromMidnight: 36_900),
            ]
        )
        board = try arrive(late, on: held)
        XCTAssertThrowsError(try occupierTakes(trainID: late.id, blockID: block.id, on: board)) { error in
            XCTAssertEqual(error as? BoardError, .tokenHeld)
        }

        XCTAssertThrowsError(
            try occupierTakes(trainID: train.id, blockID: block.id, on: openingBoard(isoWeek: week))
        ) { error in
            XCTAssertEqual(error as? BoardError, .unknownTrain)
        }
        XCTAssertThrowsError(try surveyLeg(
            SingleLineBlock(fromMilepost: "MP10", toMilepost: "MP20", tape: 0, clino: 0, brg: 0),
            on: empty
        )) { error in
            XCTAssertEqual(error as? BoardError, .invalidTape)
        }
        XCTAssertThrowsError(try arrive(Train(name: "Pilot", length: -1), on: empty)) { error in
            XCTAssertEqual(error as? BoardError, .invalidLength)
        }
    }

    func test_handToken_freesBlockForLaterTrain() throws {
        let block = SingleLineBlock(fromMilepost: "MP10", toMilepost: "MP20", tape: 10, clino: 0, brg: 0)
        var board = try surveyLeg(block, on: openingBoard(isoWeek: week))
        let first = Train(
            name: "Pilot",
            length: 8,
            passingTimes: [
                PassingTime(milepost: "MP10", secondsFromMidnight: 10),
                PassingTime(milepost: "MP20", secondsFromMidnight: 20),
            ]
        )
        let second = Train(
            name: "Relief",
            length: 7,
            passingTimes: [
                PassingTime(milepost: "MP10", secondsFromMidnight: 30),
                PassingTime(milepost: "MP20", secondsFromMidnight: 40),
            ]
        )
        board = try arrive(first, on: board)
        board = try arrive(second, on: board)
        board = try occupierTakes(trainID: first.id, blockID: block.id, on: board)
        board = try holderReturns(blockID: block.id, on: board)
        XCTAssertNil(board.token(for: block.id)?.holderID)
        board = try occupierTakes(trainID: second.id, blockID: block.id, on: board)
        XCTAssertEqual(board.token(for: block.id)?.holderID, second.id)
        XCTAssertEqual(board.occupations.count, 2)
    }

    func test_occupationsOverlap_sameBlockOnly() {
        let block = UUID()
        let other = UUID()
        let first = Occupation(trainID: UUID(), blockID: block, start: 10, end: 20)
        let overlapping = Occupation(trainID: UUID(), blockID: block, start: 15, end: 25)
        let later = Occupation(trainID: UUID(), blockID: block, start: 20, end: 30)
        let elsewhere = Occupation(trainID: UUID(), blockID: other, start: 10, end: 20)
        XCTAssertTrue(occupationsOverlap(first, overlapping))
        XCTAssertFalse(occupationsOverlap(first, later))
        XCTAssertFalse(occupationsOverlap(first, elsewhere))
    }

    func test_loopFeasibleIffLoopLenAtLeastShorterTrain() {
        XCTAssertTrue(LoopCheck.loopFeasible(loopLen: 40, shorterTrain: 8))
        XCTAssertTrue(LoopCheck.loopFeasible(loopLen: 8, shorterTrain: 8))
        XCTAssertFalse(LoopCheck.loopFeasible(loopLen: 7, shorterTrain: 8))
        let trains = [
            Train(name: "Pilot", length: 12),
            Train(name: "Relief", length: 8),
        ]
        XCTAssertTrue(LoopCheck.loopFeasible(loopLen: 8, trains: trains))
        XCTAssertFalse(LoopCheck.loopFeasible(loopLen: 7.9, trains: trains))
    }

    func test_occupyReturnsNewBoardLeavingOriginalUnchanged() throws {
        let block = SingleLineBlock(fromMilepost: "MP10", toMilepost: "MP20", tape: 10, clino: 0, brg: 0)
        var board = try surveyLeg(block, on: openingBoard(isoWeek: week))
        let train = Train(
            name: "Pilot",
            length: 8,
            passingTimes: [
                PassingTime(milepost: "MP10", secondsFromMidnight: 1),
                PassingTime(milepost: "MP20", secondsFromMidnight: 2),
            ]
        )
        board = try arrive(train, on: board)
        let occupied = try occupierTakes(trainID: train.id, blockID: block.id, on: board)
        XCTAssertTrue(board.occupations.isEmpty)
        XCTAssertNil(board.token(for: block.id)?.holderID)
        XCTAssertEqual(occupied.occupations.count, 1)
        XCTAssertEqual(occupied.token(for: block.id)?.holderID, train.id)
    }

    func test_isoWeekUsesISO8601Calendar() {
        var calendar = Calendar(identifier: .iso8601)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .gmt
        var parts = DateComponents()
        parts.year = 2026
        parts.month = 8
        parts.day = 29
        let saturday = calendar.date(from: parts) ?? Date(timeIntervalSince1970: 1_787_961_600)
        let week = ISOWeekDate.of(saturday, calendar: calendar)
        XCTAssertEqual(week.year, 2026)
        XCTAssertEqual(week.week, 35)
        XCTAssertEqual(week.daykey, "2026-W35")
        XCTAssertEqual(ISOWeekDate.parse(daykey: "2026-W35"), week)
        XCTAssertEqual(ISOWeekDate.current(on: saturday).week, week.week)
    }
}
