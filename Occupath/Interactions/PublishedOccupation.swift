import Foundation

/// Role: Interaction. One station on the reduced traverse — depth section ink.
struct SurveyStation: Hashable, Sendable, Equatable, Identifiable {
    var milepost: String
    var chainage: Double
    var offset: CartesianOffset

    var id: String { "\(milepost)-\(chainage)" }
}

/// Role: Interaction. Published occupation the desk redraws. Views never mutate the graph.
struct PublishedOccupation: Equatable, Sendable {
    var board: WorkingTimetable
    var chainage: [String: Double]
    var maxChainage: Double
    var timeStart: Double
    var timeEnd: Double
    var conflicts: [ConflictMark]
    var loops: [ClosedLoop]
    var stations: [SurveyStation]
    var tokenHops: Int
    var loopFeasible: Bool

    static let empty = PublishedOccupation(
        board: openingBoard(isoWeek: ISOWeekDate(year: 2026, week: 35)),
        chainage: [:],
        maxChainage: 1,
        timeStart: 0,
        timeEnd: 86_400,
        conflicts: [],
        loops: [],
        stations: [],
        tokenHops: 0,
        loopFeasible: true
    )
}

/// Interaction. Runs LoopCheck roles and projects ink so SwiftUI can redraw.
enum OccupationInk {
    static func published(from board: WorkingTimetable) -> PublishedOccupation {
        let check = LoopCheck.bind(blocks: board.blocks, trains: board.trains)
        let loops = check.traverse.close()
        let chainage = stationChainages(blocks: board.blocks)
        let maxChainage = max(chainage.values.max() ?? 0, 1)
        let times = board.occupations.flatMap { [$0.start, $0.end] }
            + board.trains.flatMap { $0.passingTimes.map(\.secondsFromMidnight) }
        var timeStart = times.min() ?? 21_600
        var timeEnd = times.max() ?? 72_000
        if timeEnd <= timeStart {
            timeEnd = timeStart + 3_600
        }
        timeStart = max(0, timeStart - 1_800)
        timeEnd = min(86_400, timeEnd + 1_800)
        let loopLen = loops.map(\.totalLength).max() ?? 0
        let feasible: Bool
        if board.trains.isEmpty {
            feasible = true
        } else if loops.isEmpty {
            feasible = false
        } else {
            feasible = check.consist.feasible(loopLen: loopLen)
        }
        return PublishedOccupation(
            board: board,
            chainage: chainage,
            maxChainage: maxChainage,
            timeStart: timeStart,
            timeEnd: timeEnd,
            conflicts: refusedOccupations(on: board),
            loops: loops,
            stations: stations(from: loops, blocks: board.blocks),
            tokenHops: board.occupations.count,
            loopFeasible: feasible
        )
    }

    static func stationChainages(blocks: [SingleLineBlock]) -> [String: Double] {
        var adjacency: [String: [(String, Double)]] = [:]
        for block in blocks {
            adjacency[block.fromMilepost, default: []].append((block.toMilepost, block.tape))
            adjacency[block.toMilepost, default: []].append((block.fromMilepost, block.tape))
        }
        var chainage: [String: Double] = [:]
        guard let start = blocks.first?.fromMilepost else { return chainage }
        var queue = [start]
        chainage[start] = 0
        var index = 0
        while index < queue.count {
            let node = queue[index]
            index += 1
            let base = chainage[node] ?? 0
            for (next, tape) in adjacency[node] ?? [] where chainage[next] == nil {
                chainage[next] = base + tape
                queue.append(next)
            }
        }
        return chainage
    }

    static func stations(from loops: [ClosedLoop], blocks: [SingleLineBlock]) -> [SurveyStation] {
        if let loop = loops.first {
            return stations(from: loop)
        }
        return openTraverse(blocks: blocks)
    }

    static func stations(from loop: ClosedLoop) -> [SurveyStation] {
        var chain = 0.0
        var position = CartesianOffset.zero
        var result: [SurveyStation] = [
            SurveyStation(milepost: loop.mileposts.first ?? "", chainage: 0, offset: .zero),
        ]
        for (index, offset) in loop.adjusted.enumerated() {
            position = position + offset
            chain += loop.legs[index].tape
            let name = index + 1 < loop.mileposts.count ? loop.mileposts[index + 1] : ""
            result.append(SurveyStation(milepost: name, chainage: chain, offset: position))
        }
        return result
    }

    static func openTraverse(blocks: [SingleLineBlock]) -> [SurveyStation] {
        guard !blocks.isEmpty else { return [] }
        var chain = 0.0
        var position = CartesianOffset.zero
        var result: [SurveyStation] = [
            SurveyStation(milepost: blocks[0].fromMilepost, chainage: 0, offset: .zero),
        ]
        var seen: Set<String> = [blocks[0].fromMilepost]
        for block in blocks {
            let offset = LoopClosure.reduce(tape: block.tape, clino: block.clino, brg: block.brg)
            position = position + offset
            chain += block.tape
            if !seen.contains(block.toMilepost) {
                seen.insert(block.toMilepost)
                result.append(SurveyStation(milepost: block.toMilepost, chainage: chain, offset: position))
            }
        }
        return result
    }

    static func succeedingWeek(_ week: ISOWeekDate) -> ISOWeekDate {
        let calendar = ISOWeekDate.iso8601Calendar()
        var parts = DateComponents()
        parts.yearForWeekOfYear = week.year
        parts.weekOfYear = week.week
        parts.weekday = 2
        guard let date = calendar.date(from: parts),
              let next = calendar.date(byAdding: .weekOfYear, value: 1, to: date)
        else {
            return ISOWeekDate(year: week.year, week: week.week + 1)
        }
        return ISOWeekDate.of(next, calendar: calendar)
    }
}
