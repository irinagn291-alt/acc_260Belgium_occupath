import XCTest
@testable import Occupath

/// Family invariant: reduce tape/clino/brg → xyz; DFS cycles; −mis*(legLen/total). relativeError=|mis|/total.
final class LoopClosureTests: XCTestCase {
    func test_reduceTapeClinoBrgToXYZ() {
        let north = LoopClosure.reduce(tape: 10, clino: 0, brg: 0)
        XCTAssertEqual(north.east, 0, accuracy: 1e-9)
        XCTAssertEqual(north.north, 10, accuracy: 1e-9)
        XCTAssertEqual(north.up, 0, accuracy: 1e-9)

        let east = LoopClosure.reduce(tape: 10, clino: 0, brg: 90)
        XCTAssertEqual(east.east, 10, accuracy: 1e-9)
        XCTAssertEqual(east.north, 0, accuracy: 1e-9)

        let up = LoopClosure.reduce(tape: 10, clino: 90, brg: 0)
        XCTAssertEqual(up.east, 0, accuracy: 1e-9)
        XCTAssertEqual(up.north, 0, accuracy: 1e-9)
        XCTAssertEqual(up.up, 10, accuracy: 1e-9)

        let inclined = LoopClosure.reduce(tape: 10, clino: 30, brg: 0)
        XCTAssertEqual(inclined.east, 0, accuracy: 1e-9)
        XCTAssertEqual(inclined.north, 10 * cos(30 * .pi / 180), accuracy: 1e-9)
        XCTAssertEqual(inclined.up, 5, accuracy: 1e-9)
    }

    func test_distributeMisclosureAndRelativeError() {
        let legs = [
            AlignmentLeg(blockID: UUID(), fromMilepost: "A", toMilepost: "B", tape: 10, clino: 0, brg: 0, reversed: false),
            AlignmentLeg(blockID: UUID(), fromMilepost: "B", toMilepost: "C", tape: 10, clino: 0, brg: 90, reversed: false),
            AlignmentLeg(blockID: UUID(), fromMilepost: "C", toMilepost: "A", tape: 10, clino: 0, brg: 180, reversed: false),
        ]
        let loop = LoopClosure.close(legs)
        XCTAssertEqual(loop.misclosure.east, 10, accuracy: 1e-9)
        XCTAssertEqual(loop.misclosure.north, 0, accuracy: 1e-9)
        XCTAssertEqual(loop.misclosure.up, 0, accuracy: 1e-9)
        XCTAssertEqual(loop.totalLength, 30, accuracy: 1e-9)
        XCTAssertEqual(loop.relativeError, 10.0 / 30.0, accuracy: 1e-9)
        XCTAssertEqual(
            LoopClosure.relativeError(misclosure: loop.misclosure, total: loop.totalLength),
            loop.misclosure.magnitude / loop.totalLength,
            accuracy: 1e-9
        )

        let share = 10.0 / 30.0
        XCTAssertEqual(loop.adjusted[0].east, 0 - 10 * share, accuracy: 1e-9)
        XCTAssertEqual(loop.adjusted[1].east, 10 - 10 * share, accuracy: 1e-9)
        XCTAssertEqual(loop.adjusted[2].east, 0 - 10 * share, accuracy: 1e-9)

        let closed = loop.adjusted.reduce(CartesianOffset.zero, +)
        XCTAssertEqual(closed.east, 0, accuracy: 1e-9)
        XCTAssertEqual(closed.north, 0, accuracy: 1e-9)
        XCTAssertEqual(closed.up, 0, accuracy: 1e-9)
    }

    func test_closedSquareHasZeroRelativeError() throws {
        let blocks = squareBlocks()
        let cycles = LoopCheck.bind(blocks: blocks).traverse.close()
        XCTAssertEqual(cycles.count, 1)
        let loop = try XCTUnwrap(cycles.first)
        XCTAssertEqual(loop.relativeError, 0, accuracy: 1e-9)
        XCTAssertEqual(loop.misclosure.magnitude, 0, accuracy: 1e-9)
        let residual = loop.adjusted.reduce(CartesianOffset.zero, +)
        XCTAssertEqual(residual.magnitude, 0, accuracy: 1e-9)
    }

    func test_dfsFindsIndependentCycles() {
        let ab = SingleLineBlock(fromMilepost: "A", toMilepost: "B", tape: 10, clino: 0, brg: 0)
        let bc = SingleLineBlock(fromMilepost: "B", toMilepost: "C", tape: 10, clino: 0, brg: 90)
        let ca = SingleLineBlock(fromMilepost: "C", toMilepost: "A", tape: 10, clino: 0, brg: 180)
        let ad = SingleLineBlock(fromMilepost: "A", toMilepost: "D", tape: 10, clino: 0, brg: 270)
        let dc = SingleLineBlock(fromMilepost: "D", toMilepost: "C", tape: 10, clino: 0, brg: 90)
        let cycles = LoopClosure.cycles(in: [ab, bc, ca, ad, dc])
        XCTAssertEqual(cycles.count, 2)
        XCTAssertEqual(Set(cycles.map(\.legs.count)), [3, 4])
    }

    func test_emptyAndOpenTraverseHaveNoCycle() {
        XCTAssertTrue(LoopClosure.cycles(in: []).isEmpty)
        let lone = SingleLineBlock(fromMilepost: "A", toMilepost: "B", tape: 10, clino: 0, brg: 0)
        XCTAssertTrue(LoopClosure.cycles(in: [lone]).isEmpty)
    }

    private func squareBlocks() -> [SingleLineBlock] {
        [
            SingleLineBlock(fromMilepost: "MP10", toMilepost: "MP20", tape: 10, clino: 0, brg: 0),
            SingleLineBlock(fromMilepost: "MP20", toMilepost: "MP30", tape: 10, clino: 0, brg: 90),
            SingleLineBlock(fromMilepost: "MP30", toMilepost: "MP40", tape: 10, clino: 0, brg: 180),
            SingleLineBlock(fromMilepost: "MP40", toMilepost: "MP10", tape: 10, clino: 0, brg: 270),
        ]
    }
}
