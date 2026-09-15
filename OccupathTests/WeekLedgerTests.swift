import XCTest
@testable import Occupath

final class WeekLedgerTests: XCTestCase {
    private var directory: URL!
    private var suiteName: String!
    private var defaults: UserDefaults!

    override func setUpWithError() throws {
        directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        suiteName = "ocp.test.\(UUID().uuidString)"
        defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defaults.removePersistentDomain(forName: suiteName)
    }

    override func tearDownWithError() throws {
        if let directory {
            try? FileManager.default.removeItem(at: directory)
        }
        if let suiteName {
            defaults?.removePersistentDomain(forName: suiteName)
        }
        directory = nil
        defaults = nil
        suiteName = nil
    }

    func test_roundTrip_reloadPreservesOccupation() async throws {
        let ledger = makeLedger()
        var board = openingBoard(isoWeek: ISOWeekDate(year: 2026, week: 35))
        let block = SingleLineBlock(fromMilepost: "MP10", toMilepost: "MP20", tape: 10, clino: 0, brg: 45)
        board = try surveyLeg(block, on: board)
        let train = Train(
            name: "Pilot",
            length: 8,
            passingTimes: [
                PassingTime(milepost: "MP10", secondsFromMidnight: 36_000),
                PassingTime(milepost: "MP20", secondsFromMidnight: 36_600),
            ]
        )
        board = try arrive(train, on: board)
        board = try occupierTakes(trainID: train.id, blockID: block.id, on: board)
        try await ledger.save(board)

        let relaunched = makeLedger()
        let loaded = await relaunched.load()
        XCTAssertNil(loaded.warning)
        XCTAssertEqual(loaded.boards.count, 1)
        let restored = try XCTUnwrap(loaded.boards.first)
        XCTAssertEqual(restored.id, board.id)
        XCTAssertEqual(restored.isoWeek.daykey, "2026-W35")
        XCTAssertEqual(restored.blocks.first?.tape, 10)
        XCTAssertEqual(restored.blocks.first?.clino, 0)
        XCTAssertEqual(restored.blocks.first?.brg, 45)
        XCTAssertEqual(restored.occupations.count, 1)
        XCTAssertEqual(restored.occupations[0].start, 36_000)
        XCTAssertEqual(restored.token(for: block.id)?.holderID, train.id)
    }

    func test_corruptFileFallsBackToBackup() async throws {
        let ledger = makeLedger()
        let board = openingBoard(
            id: UUID(uuidString: "AAAAAAAA-AAAA-4AAA-8AAA-AAAAAAAAAAAA") ?? UUID(),
            isoWeek: ISOWeekDate(year: 2026, week: 12)
        )
        try await ledger.save(board)
        let url = directory.appendingPathComponent("2026-W12.json")
        let backup = url.appendingPathExtension("backup")
        try FileManager.default.copyItem(at: url, to: backup)
        try Data("{not-json".utf8).write(to: url)

        let relaunched = makeLedger()
        let loaded = await relaunched.load()
        XCTAssertEqual(loaded.warning, .recoveredFromBackup)
        XCTAssertEqual(loaded.boards.first?.id, board.id)
    }

    func test_corruptFileWithoutBackupStartsEmpty() async throws {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let url = directory.appendingPathComponent("2026-W01.json")
        try Data("nope".utf8).write(to: url)
        let loaded = await makeLedger().load()
        XCTAssertEqual(loaded.warning, .startedEmpty)
        XCTAssertTrue(loaded.boards.isEmpty)
    }

    func test_resetAllData_deletesBoardFolder() async throws {
        let ledger = makeLedger()
        try await ledger.save(openingBoard(isoWeek: ISOWeekDate(year: 2026, week: 1)))
        try await ledger.resetAllData()
        let loaded = await ledger.load()
        XCTAssertTrue(loaded.boards.isEmpty)
        let leftovers = try FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)
        XCTAssertTrue(leftovers.filter { $0.pathExtension == "json" }.isEmpty)
    }

    func test_codecSwitchesOnSchemaVersion() throws {
        let board = openingBoard(isoWeek: ISOWeekDate(year: 2026, week: 8))
        let data = try TimetableCodec.encode(board)
        let decoded = try TimetableCodec.decode(data)
        XCTAssertEqual(decoded.id, board.id)
        XCTAssertEqual(decoded.isoWeek.week, 8)

        let future = Data("{\"schemaVersion\":99}".utf8)
        XCTAssertThrowsError(try TimetableCodec.decode(future)) { error in
            XCTAssertEqual(error as? TimetableCodec.Failure, .unsupportedSchema(99))
        }
        XCTAssertThrowsError(try TimetableCodec.decode(Data("[]".utf8))) { error in
            XCTAssertEqual(error as? TimetableCodec.Failure, .corrupt)
        }
    }

    func test_formatterUsesNumberFormatter() {
        let locale = Locale(identifier: "en_US")
        XCTAssertEqual(OccupathFormatter.integer(12, locale: locale), "12")
        XCTAssertFalse(OccupathFormatter.decimal(1.25, locale: locale).isEmpty)
    }

    #if targetEnvironment(simulator)
    func test_simulatorSeedWritesLegalOccupationOnce() async throws {
        let ledger = makeLedger()
        try await ledger.seedDemoIfNeeded()
        try await ledger.seedDemoIfNeeded()
        let loaded = await ledger.load()
        XCTAssertEqual(loaded.boards.count, 1)
        let board = try XCTUnwrap(loaded.boards.first)
        XCTAssertEqual(board.id, DeskSeed.boardID)
        XCTAssertEqual(board.isoWeek, DeskSeed.week)
        XCTAssertEqual(board.blocks.count, 4)
        XCTAssertEqual(board.occupations.count, 1)
        XCTAssertEqual(board.token(for: DeskSeed.blockAB)?.holderID, DeskSeed.trainID)
        XCTAssertEqual(LoopClosure.cycles(in: board.blocks).count, 1)
        XCTAssertEqual(LoopClosure.cycles(in: board.blocks).first?.relativeError ?? 1, 0, accuracy: 1e-9)
        XCTAssertTrue(defaults.bool(forKey: PreferenceKey.demoSeed))
        XCTAssertTrue(defaults.bool(forKey: PreferenceKey.onboardingComplete))
        let url = directory.appendingPathComponent("2026-W35.json")
        XCTAssertTrue(FileManager.default.fileExists(atPath: url.path))
    }
    #endif

    private func makeLedger() -> WeekLedger {
        WeekLedger(
            directory: directory,
            defaultsSuiteName: suiteName,
            writeDelayNanoseconds: 0
        )
    }
}
