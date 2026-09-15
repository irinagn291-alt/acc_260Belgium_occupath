import UIKit

/// Role: Presentation. Coordinate math and ink for the Marey plate. No SwiftUI Path.
enum MareyPlate {
    static let pad: CGFloat = 36
    static let contentSize = CGSize(width: 640, height: 1440)
    static let hitSlop: CGFloat = 22

    static func point(
        chainage: Double,
        seconds: Double,
        in size: CGSize,
        published: PublishedOccupation
    ) -> CGPoint {
        let maxC = max(published.maxChainage, 1)
        let span = max(published.timeEnd - published.timeStart, 1)
        let x = pad + CGFloat(chainage / maxC) * (size.width - pad * 2)
        let y = pad + CGFloat((seconds - published.timeStart) / span) * (size.height - pad * 2)
        return CGPoint(x: x, y: y)
    }

    static func draw(
        in ctx: CGContext,
        dirty: CGRect,
        size: CGSize,
        published: PublishedOccupation
    ) {
        ctx.saveGState()
        ctx.setFillColor(PlateInk.backgroundUI.cgColor)
        ctx.fill(dirty)

        drawRuling(in: ctx, size: size, published: published)
        drawOccupations(in: ctx, size: size, published: published)
        drawConflicts(in: ctx, size: size, published: published)
        drawTrains(in: ctx, size: size, published: published)
        ctx.restoreGState()
    }

    static func tokenPoint(
        token: Token,
        in size: CGSize,
        published: PublishedOccupation
    ) -> CGPoint? {
        guard let block = published.board.block(id: token.blockID) else { return nil }
        let mid = ((published.chainage[block.fromMilepost] ?? 0) + (published.chainage[block.toMilepost] ?? 0)) / 2
        let seconds = published.board.occupations.first(where: { $0.blockID == token.blockID })?.start
            ?? published.timeStart
        return point(chainage: mid, seconds: seconds, in: size, published: published)
    }

    static func conflict(
        at point: CGPoint,
        size: CGSize,
        published: PublishedOccupation
    ) -> ConflictMark? {
        published.conflicts.first { mark in
            rect(for: mark.blockID, start: mark.start, end: mark.end, size: size, published: published)
                .insetBy(dx: -hitSlop, dy: -hitSlop)
                .contains(point)
        }
    }

    static func train(
        at point: CGPoint,
        size: CGSize,
        published: PublishedOccupation
    ) -> Train? {
        published.board.trains.first { train in
            let points = polyline(for: train, size: size, published: published)
            return distance(from: point, to: points) < hitSlop
        }
    }

    static func block(
        at point: CGPoint,
        size: CGSize,
        published: PublishedOccupation
    ) -> SingleLineBlock? {
        published.board.blocks.first { block in
            band(for: block, size: size, published: published)
                .insetBy(dx: -hitSlop, dy: 0)
                .contains(point)
        }
    }

    private static func drawRuling(in ctx: CGContext, size: CGSize, published: PublishedOccupation) {
        ctx.setStrokeColor(PlateInk.inkUI.withAlphaComponent(0.55).cgColor)
        ctx.setLineWidth(1)
        var hour = published.timeStart
        while hour <= published.timeEnd {
            let y = point(chainage: 0, seconds: hour, in: size, published: published).y
            ctx.move(to: CGPoint(x: pad, y: y))
            ctx.addLine(to: CGPoint(x: size.width - pad, y: y))
            hour += 1_800
        }
        for (_, chain) in published.chainage {
            let x = point(chainage: chain, seconds: published.timeStart, in: size, published: published).x
            ctx.move(to: CGPoint(x: x, y: pad))
            ctx.addLine(to: CGPoint(x: x, y: size.height - pad))
        }
        ctx.strokePath()
        ctx.setStrokeColor(PlateInk.inkUI.cgColor)
        ctx.setLineWidth(1.5)
        ctx.stroke(CGRect(x: pad, y: pad, width: size.width - pad * 2, height: size.height - pad * 2))
    }

    private static func drawOccupations(in ctx: CGContext, size: CGSize, published: PublishedOccupation) {
        ctx.setFillColor(PlateInk.inkUI.withAlphaComponent(0.28).cgColor)
        ctx.setStrokeColor(PlateInk.inkUI.cgColor)
        ctx.setLineWidth(2)
        for occupation in published.board.occupations {
            let box = rect(for: occupation.blockID, start: occupation.start, end: occupation.end, size: size, published: published)
            ctx.fill(box)
            ctx.stroke(box)
        }
    }

    private static func drawConflicts(in ctx: CGContext, size: CGSize, published: PublishedOccupation) {
        ctx.setFillColor(PlateInk.accentUI.withAlphaComponent(0.18).cgColor)
        ctx.setStrokeColor(PlateInk.accentUI.cgColor)
        ctx.setLineWidth(1.5)
        for mark in published.conflicts {
            let box = rect(for: mark.blockID, start: mark.start, end: mark.end, size: size, published: published)
            ctx.fill(box)
            ctx.stroke(box)
            var x = box.minX
            ctx.setLineWidth(1)
            while x < box.maxX {
                ctx.move(to: CGPoint(x: x, y: box.minY))
                ctx.addLine(to: CGPoint(x: x + 8, y: box.maxY))
                x += 8
            }
            ctx.strokePath()
        }
    }

    private static func drawTrains(in ctx: CGContext, size: CGSize, published: PublishedOccupation) {
        ctx.setStrokeColor(PlateInk.inkUI.cgColor)
        ctx.setLineWidth(3.5)
        ctx.setLineJoin(.round)
        ctx.setLineCap(.round)
        for train in published.board.trains {
            let points = polyline(for: train, size: size, published: published)
            guard let first = points.first else { continue }
            ctx.move(to: first)
            for next in points.dropFirst() {
                ctx.addLine(to: next)
            }
            ctx.strokePath()
        }
    }

    private static func polyline(
        for train: Train,
        size: CGSize,
        published: PublishedOccupation
    ) -> [CGPoint] {
        train.passingTimes
            .sorted { $0.secondsFromMidnight < $1.secondsFromMidnight }
            .compactMap { stamp in
                guard let chain = published.chainage[stamp.milepost] else { return nil }
                return point(chainage: chain, seconds: stamp.secondsFromMidnight, in: size, published: published)
            }
    }

    private static func rect(
        for blockID: UUID,
        start: Double,
        end: Double,
        size: CGSize,
        published: PublishedOccupation
    ) -> CGRect {
        guard let block = published.board.block(id: blockID) else { return .zero }
        let a = published.chainage[block.fromMilepost] ?? 0
        let b = published.chainage[block.toMilepost] ?? 0
        let p0 = point(chainage: min(a, b), seconds: start, in: size, published: published)
        let p1 = point(chainage: max(a, b), seconds: end, in: size, published: published)
        return CGRect(x: p0.x, y: p0.y, width: max(p1.x - p0.x, 8), height: max(p1.y - p0.y, 8))
    }

    private static func band(
        for block: SingleLineBlock,
        size: CGSize,
        published: PublishedOccupation
    ) -> CGRect {
        let a = published.chainage[block.fromMilepost] ?? 0
        let b = published.chainage[block.toMilepost] ?? 0
        let p0 = point(chainage: min(a, b), seconds: published.timeStart, in: size, published: published)
        let p1 = point(chainage: max(a, b), seconds: published.timeEnd, in: size, published: published)
        return CGRect(x: p0.x, y: p0.y, width: max(p1.x - p0.x, 8), height: max(p1.y - p0.y, 8))
    }

    private static func distance(from point: CGPoint, to polyline: [CGPoint]) -> CGFloat {
        guard polyline.count >= 2 else {
            return polyline.first.map { hypot($0.x - point.x, $0.y - point.y) } ?? .greatestFiniteMagnitude
        }
        var best = CGFloat.greatestFiniteMagnitude
        for index in 0 ..< (polyline.count - 1) {
            best = min(best, distance(from: point, a: polyline[index], b: polyline[index + 1]))
        }
        return best
    }

    private static func distance(from point: CGPoint, a: CGPoint, b: CGPoint) -> CGFloat {
        let dx = b.x - a.x
        let dy = b.y - a.y
        let length = dx * dx + dy * dy
        guard length > 0 else { return hypot(point.x - a.x, point.y - a.y) }
        let t = max(0, min(1, ((point.x - a.x) * dx + (point.y - a.y) * dy) / length))
        return hypot(point.x - (a.x + t * dx), point.y - (a.y + t * dy))
    }
}
