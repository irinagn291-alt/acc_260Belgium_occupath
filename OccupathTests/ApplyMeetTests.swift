import XCTest
@testable import Occupath

final class ApplyMeetTests: XCTestCase {
    private let week = ISOWeekDate(year: 2026, week: 35)

    func test_meetRewritesLaterPathAndTransfersToken() throws {
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
        let later = Train(
            name: "Relief",
            length: 6,
            passingTimes: [
                PassingTime(milepost: "MP10", secondsFromMidnight: 12),
                PassingTime(milepost: "MP20", secondsFromMidnight: 22),
            ]
        )
        board = try arrive(first, on: board)
        board = try arrive(later, on: board)
        board = try occupierTakes(trainID: first.id, blockID: block.id, on: board)

        XCTAssertEqual(refusedOccupations(on: board).count, 1)
        let context = try XCTUnwrap(ApplyMeet.bind(laterTrainID: later.id, blockID: block.id, on: board))
        let offer: MeetOffer = try XCTUnwrap(context.laterPath.offer())
        XCTAssertEqual(offer.tokenReturn, 20, accuracy: 1e-9)
        XCTAssertEqual(offer.rewritten.seconds(at: "MP10") ?? 0, 20, accuracy: 1e-9)
        XCTAssertEqual(offer.rewritten.seconds(at: "MP20") ?? 0, 30, accuracy: 1e-9)

        let originalLater = later
        let next = try context.laterPath.accept()
        XCTAssertEqual(later.seconds(at: "MP10"), originalLater.seconds(at: "MP10"))
        XCTAssertEqual(next.train(id: later.id)?.seconds(at: "MP10") ?? 0, 20, accuracy: 1e-9)
        XCTAssertEqual(next.token(for: block.id)?.holderID, later.id)
        XCTAssertTrue(refusedOccupations(on: next).isEmpty)
    }

    func test_offerNilWhenTokenFree() throws {
        let block = SingleLineBlock(fromMilepost: "A", toMilepost: "B", tape: 10, clino: 0, brg: 0)
        var board = try surveyLeg(block, on: openingBoard(isoWeek: week))
        let train = Train(
            name: "Pilot",
            length: 8,
            passingTimes: [
                PassingTime(milepost: "A", secondsFromMidnight: 1),
                PassingTime(milepost: "B", secondsFromMidnight: 2),
            ]
        )
        board = try arrive(train, on: board)
        XCTAssertNil(ApplyMeet.bind(laterTrainID: train.id, blockID: block.id, on: board))
    }
}
