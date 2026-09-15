import Foundation

/// Role: Data. Reduced tape/clino/brg in east / north / up.
struct CartesianOffset: Hashable, Sendable, Equatable {
    var east: Double
    var north: Double
    var up: Double

    static let zero = CartesianOffset(east: 0, north: 0, up: 0)

    var magnitude: Double {
        (east * east + north * north + up * up).squareRoot()
    }

    var negated: CartesianOffset {
        CartesianOffset(east: -east, north: -north, up: -up)
    }

    func scaled(by factor: Double) -> CartesianOffset {
        CartesianOffset(east: east * factor, north: north * factor, up: up * factor)
    }

    static func + (lhs: CartesianOffset, rhs: CartesianOffset) -> CartesianOffset {
        CartesianOffset(east: lhs.east + rhs.east, north: lhs.north + rhs.north, up: lhs.up + rhs.up)
    }
}

/// Role: Data. One walk of a measured block around a cycle.
struct AlignmentLeg: Hashable, Sendable, Equatable {
    var blockID: UUID
    var fromMilepost: String
    var toMilepost: String
    var tape: Double
    var clino: Double
    var brg: Double
    var reversed: Bool
}

/// Role: Data. One independent loop: misclosure, Bowditch adjustments, relative error.
struct ClosedLoop: Hashable, Sendable, Equatable {
    var mileposts: [String]
    var legs: [AlignmentLeg]
    var offsets: [CartesianOffset]
    var adjusted: [CartesianOffset]
    var misclosure: CartesianOffset
    var totalLength: Double
    var relativeError: Double
}

/// Role: Data. Family calculator — reduce tape/clino/brg → xyz; DFS cycles; −mis*(legLen/total).
enum LoopClosure {
    static func reduce(tape: Double, clino: Double, brg: Double) -> CartesianOffset {
        let clinoRad = clino * .pi / 180
        let brgRad = brg * .pi / 180
        let horizontal = tape * cos(clinoRad)
        return CartesianOffset(
            east: horizontal * sin(brgRad),
            north: horizontal * cos(brgRad),
            up: tape * sin(clinoRad)
        )
    }

    static func relativeError(misclosure: CartesianOffset, total: Double) -> Double {
        guard total > 0, misclosure.magnitude.isFinite else { return 0 }
        return misclosure.magnitude / total
    }

    static func close(_ legs: [AlignmentLeg]) -> ClosedLoop {
        var offsets: [CartesianOffset] = []
        var mileposts: [String] = []
        var total = 0.0
        for (index, leg) in legs.enumerated() {
            if index == 0 {
                mileposts.append(leg.fromMilepost)
            }
            mileposts.append(leg.toMilepost)
            let raw = reduce(tape: leg.tape, clino: leg.clino, brg: leg.brg)
            offsets.append(leg.reversed ? raw.negated : raw)
            total += leg.tape
        }
        let misclosure = offsets.reduce(CartesianOffset.zero, +)
        let adjusted = zip(offsets, legs).map { offset, leg in
            let weight = total > 0 ? leg.tape / total : 0
            return offset + misclosure.negated.scaled(by: weight)
        }
        return ClosedLoop(
            mileposts: mileposts,
            legs: legs,
            offsets: offsets,
            adjusted: adjusted,
            misclosure: misclosure,
            totalLength: total,
            relativeError: relativeError(misclosure: misclosure, total: total)
        )
    }

    static func cycles(in blocks: [SingleLineBlock]) -> [ClosedLoop] {
        let usable = blocks.filter { $0.tape.isFinite && $0.tape > 0 && $0.clino.isFinite && $0.brg.isFinite }
        var adjacency: [String: [(to: String, block: SingleLineBlock, reversed: Bool)]] = [:]
        for block in usable {
            adjacency[block.fromMilepost, default: []].append((block.toMilepost, block, false))
            adjacency[block.toMilepost, default: []].append((block.fromMilepost, block, true))
        }
        for key in adjacency.keys {
            adjacency[key]?.sort { lhs, rhs in
                if lhs.to != rhs.to { return lhs.to < rhs.to }
                return lhs.block.id.uuidString < rhs.block.id.uuidString
            }
        }

        var visited: Set<String> = []
        var usedBlocks: Set<UUID> = []
        var parent: [String: (node: String, block: SingleLineBlock, reversed: Bool)] = [:]
        var found: [ClosedLoop] = []

        func dfs(_ node: String, parentNode: String?) {
            visited.insert(node)
            for edge in adjacency[node] ?? [] {
                if edge.to == parentNode { continue }
                if usedBlocks.contains(edge.block.id) { continue }
                if !visited.contains(edge.to) {
                    usedBlocks.insert(edge.block.id)
                    parent[edge.to] = (node, edge.block, edge.reversed)
                    dfs(edge.to, parentNode: node)
                } else if let loop = reconstruct(
                    from: node,
                    to: edge.to,
                    closing: (edge.block, edge.reversed),
                    parent: parent
                ) {
                    usedBlocks.insert(edge.block.id)
                    found.append(loop)
                }
            }
        }

        let stations = Set(usable.flatMap { [$0.fromMilepost, $0.toMilepost] }).sorted()
        for start in stations where !visited.contains(start) {
            dfs(start, parentNode: nil)
        }
        return found
    }

    private static func reconstruct(
        from start: String,
        to end: String,
        closing: (block: SingleLineBlock, reversed: Bool),
        parent: [String: (node: String, block: SingleLineBlock, reversed: Bool)]
    ) -> ClosedLoop? {
        var steps: [(from: String, to: String, block: SingleLineBlock, reversed: Bool)] = []
        var current = start
        var hops = 0
        while current != end {
            guard let step = parent[current], hops <= parent.count else { return nil }
            steps.append((step.node, current, step.block, step.reversed))
            current = step.node
            hops += 1
        }
        steps.reverse()
        steps.append((start, end, closing.block, closing.reversed))
        let legs = steps.map { step in
            AlignmentLeg(
                blockID: step.block.id,
                fromMilepost: step.from,
                toMilepost: step.to,
                tape: step.block.tape,
                clino: step.block.clino,
                brg: step.block.brg,
                reversed: step.reversed
            )
        }
        return close(legs)
    }
}
