import SwiftUI

/// Role: Presentation. Home — Marey plate, depth section, loop report. Not a list.
struct MareyDeskView: View {
    @Binding var interaction: DeskInteraction
    @Environment(\.sizeCategory) private var sizeCategory
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var viewport = TokenViewport()

    init(interaction: Binding<DeskInteraction> = .constant(.previewPopulated())) {
        self._interaction = interaction
    }

    var body: some View {
        let published = interaction.published
        VStack(spacing: 0) {
            header
            if let fault = interaction.fault {
                faultBanner(fault)
            }
            HStack(spacing: 0) {
                PlayheadRail(
                    seconds: Binding(
                        get: { interaction.playhead },
                        set: { interaction.playhead = $0 }
                    ),
                    range: published.timeStart ... published.timeEnd
                )
                VStack(spacing: 0) {
                    ZStack {
                        MareySurfaceHost(
                            published: published,
                            playhead: interaction.playhead,
                            chainage: interaction.chainage,
                            interaction: $interaction,
                            onViewport: { offset, zoom, canvas in
                                let next = TokenViewport(offset: offset, zoom: zoom, canvas: canvas)
                                if next != viewport {
                                    viewport = next
                                }
                            }
                        )
                        TokenMarkOverlay(interaction: $interaction, viewport: viewport)
                        if published.board.blocks.isEmpty {
                            emptyOverlay
                        }
                        if interaction.busy {
                            PlateInk.surface.opacity(0.7)
                            ProgressView()
                                .tint(PlateInk.ink)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    MilepostRail(
                        chainage: Binding(
                            get: { interaction.chainage },
                            set: { interaction.chainage = $0 }
                        ),
                        range: 0 ... published.maxChainage
                    )
                    DepthSectionView(stations: published.stations)
                        .frame(height: PlateInk.space(11))
                    LoopReportStrip(published: published, sizeCategory: sizeCategory)
                }
            }
        }
        .background(PlateInk.background.ignoresSafeArea())
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: PlateInk.space(1)) {
            VStack(alignment: .leading, spacing: 0) {
                Text(interaction.published.board.isoWeek.daykey)
                    .plateText(.figure, category: sizeCategory)
                Text("Paint the path · Hand the token")
                    .plateText(.stamp, category: sizeCategory)
                    .foregroundStyle(PlateInk.muted)
                    .lineLimit(1)
            }
            HStack(spacing: PlateInk.space(1)) {
                headerButton("plus", label: "Enter measurement") {
                    interaction.sheet = .measurement
                }
                headerButton("point.topleft.down.to.point.bottomright.curvepath", label: "Place a path") {
                    interaction.sheet = .path
                }
                headerButton("circle.circle", label: "Token occupation") {
                    interaction.sheet = .token
                }
                Menu {
                    if horizontalSizeClass != .regular {
                        Button("Inspector", systemImage: "sidebar.right") {
                            interaction.sheet = .inspector
                        }
                    }
                    Button("Week ledger", systemImage: "calendar") {
                        interaction.sheet = .ledger
                    }
                    Button("Settings", systemImage: "gearshape") {
                        interaction.sheet = .settings
                    }
                } label: {
                    PlateInkWell(system: "ellipsis")
                }
                .buttonStyle(.plain)
                .accessibilityLabel("More")
                Spacer(minLength: 0)
                Button {
                    Task { await $interaction.commitBoard() }
                } label: {
                    Group {
                        if UIImage(named: "ocp_ControlFace") != nil {
                            Image("ocp_ControlFace")
                                .resizable()
                                .scaledToFit()
                                .padding(10)
                        } else {
                            Image(systemName: "checkmark")
                                .foregroundStyle(PlateInk.ink)
                        }
                    }
                    .frame(width: PlateInk.tap, height: PlateInk.tap)
                    .overlay(Rectangle().stroke(PlateInk.ink, lineWidth: 1.5))
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Commit the board")
                .disabled(interaction.commitBusy)
            }
        }
        .padding(.horizontal, PlateInk.space(2))
        .padding(.vertical, PlateInk.space(1))
        .background(PlateInk.surface)
    }

    private var emptyOverlay: some View {
        PlateEmpty(
            image: "ocp_EmptyHome",
            headline: "The desk is empty",
            line: "Enter the first measurement.",
            actionTitle: "Enter measurement",
            action: { interaction.sheet = .measurement }
        )
        .padding(PlateInk.space(3))
    }

    private func faultBanner(_ text: String) -> some View {
        HStack {
            Text(text)
                .plateText(.caption, category: sizeCategory)
                .foregroundStyle(PlateInk.accent)
            Spacer()
            Button("Retry") {
                Task { await $interaction.retry() }
            }
            .plateText(.caption, category: sizeCategory)
            .plateTap()
        }
        .padding(.horizontal, PlateInk.space(2))
        .background(PlateInk.surface)
    }

    private func headerButton(_ system: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            PlateInkWell(system: system)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }
}

/// Role: Presentation. Time scrubber. Time runs down. Navigation, not a haptic.
struct PlayheadRail: View {
    @Binding var seconds: Double
    var range: ClosedRange<Double>

    var body: some View {
        GeometryReader { geo in
            let span = max(range.upperBound - range.lowerBound, 1)
            let frac = (seconds - range.lowerBound) / span
            ZStack {
                PlateInk.surface
                Capsule()
                    .fill(PlateInk.muted.opacity(0.35))
                    .frame(width: 3)
                Circle()
                    .fill(PlateInk.accent)
                    .frame(width: 16, height: 16)
                    .position(x: geo.size.width / 2, y: geo.size.height * CGFloat(frac))
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        let t = min(max(value.location.y / max(geo.size.height, 1), 0), 1)
                        seconds = range.lowerBound + Double(t) * span
                    }
            )
        }
        .frame(width: PlateInk.tap)
        .accessibilityLabel("Playhead")
        .accessibilityValue(PlayheadClock.label(seconds))
        .accessibilityAdjustableAction { direction in
            let step = 300.0
            switch direction {
            case .increment: seconds = min(range.upperBound, seconds + step)
            case .decrement: seconds = max(range.lowerBound, seconds - step)
            @unknown default: break
            }
        }
    }
}

/// Role: Presentation. Milepost scrubber. Distance runs across.
struct MilepostRail: View {
    @Binding var chainage: Double
    var range: ClosedRange<Double>

    var body: some View {
        GeometryReader { geo in
            let span = max(range.upperBound - range.lowerBound, 1)
            let frac = (chainage - range.lowerBound) / span
            ZStack {
                PlateInk.surface
                Capsule()
                    .fill(PlateInk.muted.opacity(0.35))
                    .frame(height: 3)
                Circle()
                    .fill(PlateInk.ink)
                    .frame(width: 16, height: 16)
                    .position(x: geo.size.width * CGFloat(frac), y: geo.size.height / 2)
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        let t = min(max(value.location.x / max(geo.size.width, 1), 0), 1)
                        chainage = range.lowerBound + Double(t) * span
                    }
            )
        }
        .frame(height: PlateInk.tap)
        .accessibilityLabel("Milepost")
        .accessibilityValue(OccupathFormatter.decimal(chainage))
        .accessibilityAdjustableAction { direction in
            let step = max(range.upperBound / 20, 1)
            switch direction {
            case .increment: chainage = min(range.upperBound, chainage + step)
            case .decrement: chainage = max(range.lowerBound, chainage - step)
            @unknown default: break
            }
        }
    }
}

/// Role: Presentation. Empty plate: art, headline, line, CTA.
struct PlateEmpty: View {
    var image: String
    var headline: String
    var line: String
    var actionTitle: String
    var action: () -> Void
    @Environment(\.sizeCategory) private var sizeCategory

    var body: some View {
        VStack(spacing: PlateInk.space(2)) {
            Group {
                if UIImage(named: image) != nil {
                    Image(image)
                        .resizable()
                        .scaledToFit()
                } else {
                    Rectangle()
                        .fill(PlateInk.surface)
                        .overlay(
                            Rectangle().stroke(PlateInk.muted.opacity(0.4), lineWidth: 1)
                        )
                }
            }
            .frame(maxWidth: 220, maxHeight: 180)
            .accessibilityHidden(true)
            Text(headline)
                .plateText(.plate, category: sizeCategory)
                .multilineTextAlignment(.center)
            Text(line)
                .plateText(.body, category: sizeCategory)
                .foregroundStyle(PlateInk.muted)
                .multilineTextAlignment(.center)
            PlatePrimaryButton(title: actionTitle, action: action)
        }
        .padding(PlateInk.space(2))
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(PlateInk.background.opacity(0.92))
    }
}
