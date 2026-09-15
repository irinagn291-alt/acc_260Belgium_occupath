import SwiftUI

/// Role: Presentation. Depth section of the reduced traverse. Home of the desk calculator.
struct DepthSectionView: View {
    var stations: [SurveyStation]

    var body: some View {
        Canvas { context, size in
            let ruling = Path { path in
                var x: CGFloat = 0
                while x < size.width {
                    path.move(to: CGPoint(x: x, y: 0))
                    path.addLine(to: CGPoint(x: x, y: size.height))
                    x += PlateInk.space(2)
                }
                var y: CGFloat = 0
                while y < size.height {
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: size.width, y: y))
                    y += PlateInk.space(2)
                }
            }
            context.stroke(ruling, with: .color(PlateInk.muted.opacity(0.35)), lineWidth: 0.5)
            guard stations.count >= 2 else { return }
            let maxChain = max(stations.map(\.chainage).max() ?? 1, 1)
            let ups = stations.map(\.offset.up)
            let minUp = ups.min() ?? 0
            let maxUp = ups.max() ?? 1
            let span = max(maxUp - minUp, 1)
            var path = Path()
            for (index, station) in stations.enumerated() {
                let x = CGFloat(station.chainage / maxChain) * size.width
                let y = size.height - CGFloat((station.offset.up - minUp) / span) * size.height
                if index == 0 {
                    path.move(to: CGPoint(x: x, y: y))
                } else {
                    path.addLine(to: CGPoint(x: x, y: y))
                }
            }
            context.stroke(path, with: .color(PlateInk.ink), lineWidth: 2)
        }
        .background(PlateInk.surface)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Depth section")
        .accessibilityValue(stations.isEmpty ? "No measurements" : "\(stations.count) stations")
    }
}

/// Role: Presentation. Loop report — relative error and feasibility. Theme nouns are not the invariant.
struct LoopReportStrip: View {
    var published: PublishedOccupation
    var sizeCategory: ContentSizeCategory

    var body: some View {
        VStack(alignment: .leading, spacing: PlateInk.space(1)) {
            if published.loops.isEmpty {
                Text("No closed loop. Enter measurements until the traverse closes.")
                    .plateText(.caption, category: sizeCategory)
                    .foregroundStyle(PlateInk.muted)
            } else if let loop = published.loops.first {
                Text(reportLine(loop))
                    .plateText(.token, category: sizeCategory)
                Text(published.loopFeasible ? "Loop feasible — the board can clear." : "Exception — loop shorter than the consist.")
                    .plateText(.caption, category: sizeCategory)
                    .foregroundStyle(published.loopFeasible ? PlateInk.muted : PlateInk.accent)
                if published.conflicts.isEmpty == false {
                    Text("Conflicts \(OccupathFormatter.integer(published.conflicts.count)) · token hops \(OccupathFormatter.integer(published.tokenHops))")
                        .plateText(.caption, category: sizeCategory)
                        .foregroundStyle(PlateInk.accent)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, PlateInk.space(2))
        .padding(.vertical, PlateInk.space(1))
        .background(PlateInk.surface)
    }

    private func reportLine(_ loop: ClosedLoop) -> String {
        let rel = OccupathFormatter.decimal(loop.relativeError)
        let mis = OccupathFormatter.decimal(loop.misclosure.magnitude)
        let total = OccupathFormatter.decimal(loop.totalLength)
        return "Loop · rel \(rel) · |mis| \(mis) / \(total)"
    }
}
