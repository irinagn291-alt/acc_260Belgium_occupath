import SwiftUI
import UIKit

/// Role: Presentation. CATiledLayer backing. Draw runs off the main thread; snapshot is copied.
final class MareyTiledLayer: CATiledLayer {
    private let gate = NSLock()
    private var _published = PublishedOccupation.empty
    private var _size = MareyPlate.contentSize

    override class func fadeDuration() -> CFTimeInterval { 0 }

    override init() {
        super.init()
        tileSize = CGSize(width: 256, height: 256)
        levelsOfDetail = 4
        levelsOfDetailBias = 3
    }

    override init(layer: Any) {
        super.init(layer: layer)
        if let other = layer as? MareyTiledLayer {
            _published = other.lockedPublished()
            _size = other.lockedSize()
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        return nil
    }

    func publish(_ published: PublishedOccupation, size: CGSize) {
        gate.lock()
        _published = published
        _size = size
        gate.unlock()
        setNeedsDisplay()
    }

    override func draw(in ctx: CGContext) {
        let published = lockedPublished()
        let size = lockedSize()
        MareyPlate.draw(in: ctx, dirty: ctx.boundingBoxOfClipPath, size: size, published: published)
    }

    private func lockedPublished() -> PublishedOccupation {
        gate.lock()
        defer { gate.unlock() }
        return _published
    }

    private func lockedSize() -> CGSize {
        gate.lock()
        defer { gate.unlock() }
        return _size
    }
}

/// Role: Presentation. Pinch-zoom Marey host. Hits start Contexts through the interaction.
final class MareySurfaceView: UIView, UIScrollViewDelegate {
    var onConflict: ((ConflictMark) -> Void)?
    var onTrain: ((Train) -> Void)?
    var onBlock: ((SingleLineBlock) -> Void)?
    var onViewport: ((CGPoint, CGFloat, CGSize) -> Void)?

    private let scroll = UIScrollView()
    private let canvas = MareyCanvasView()
    private var published = PublishedOccupation.empty

    private var fittedHost = CGSize.zero
    private var didCenterSeed = false
    private var lastBoardID: UUID?

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = PlateInk.backgroundUI
        scroll.delegate = self
        scroll.minimumZoomScale = 1
        scroll.maximumZoomScale = 4
        scroll.backgroundColor = PlateInk.backgroundUI
        scroll.showsHorizontalScrollIndicator = true
        scroll.showsVerticalScrollIndicator = true
        canvas.frame = CGRect(origin: .zero, size: MareyPlate.contentSize)
        scroll.addSubview(canvas)
        addSubview(scroll)
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        canvas.addGestureRecognizer(tap)
        canvas.isUserInteractionEnabled = true
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        return nil
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        scroll.frame = bounds
        fitCanvasIfNeeded()
        canvas.publish(published)
        paintNow()
        if !didCenterSeed {
            centerSeed()
        }
        reportViewport()
    }

    func apply(_ published: PublishedOccupation) {
        let boardChanged = published.board.id != lastBoardID
        self.published = published
        lastBoardID = published.board.id
        fitCanvasIfNeeded()
        canvas.publish(published)
        paintNow()
        if boardChanged || !didCenterSeed {
            centerSeed()
        }
        reportViewport()
    }

    func scrollTo(seconds: Double, chainage: Double) {
        let size = canvas.bounds.size.width > 1 ? canvas.bounds.size : bounds.size
        let point = MareyPlate.point(
            chainage: chainage,
            seconds: seconds,
            in: size,
            published: published
        )
        let zoom = scroll.zoomScale
        let x = point.x * zoom - bounds.width / 2
        let y = point.y * zoom - bounds.height / 2
        let offset = CGPoint(
            x: max(0, min(x, scroll.contentSize.width - bounds.width)),
            y: max(0, min(y, scroll.contentSize.height - bounds.height))
        )
        scroll.setContentOffset(offset, animated: false)
        reportViewport()
    }

    private func fitCanvasIfNeeded() {
        let host = bounds.size
        guard host.width > 1, host.height > 1 else { return }
        if fittedHost == host, canvas.bounds.size == host { return }
        fittedHost = host
        canvas.frame = CGRect(origin: .zero, size: host)
        scroll.zoomScale = 1
        scroll.contentSize = host
        canvas.setNeedsDisplay()
    }

    private func paintNow() {
        canvas.setNeedsDisplay()
        canvas.layer.displayIfNeeded()
    }

    private func centerSeed() {
        guard bounds.width > 1, bounds.height > 1 else { return }
        didCenterSeed = true
        if let occupation = published.board.occupations.first,
           let block = published.board.block(id: occupation.blockID)
        {
            let mid = (
                (published.chainage[block.fromMilepost] ?? 0)
                    + (published.chainage[block.toMilepost] ?? 0)
            ) / 2
            scrollTo(seconds: occupation.start, chainage: mid)
        }
    }

    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        canvas
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        reportViewport()
    }

    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        reportViewport()
    }

    private func reportViewport() {
        onViewport?(scroll.contentOffset, scroll.zoomScale, canvas.bounds.size)
    }

    @objc
    private func handleTap(_ gesture: UITapGestureRecognizer) {
        let location = gesture.location(in: canvas)
        let size = canvas.bounds.size
        if let mark = MareyPlate.conflict(at: location, size: size, published: published) {
            onConflict?(mark)
        } else if let train = MareyPlate.train(at: location, size: size, published: published) {
            onTrain?(train)
        } else if let block = MareyPlate.block(at: location, size: size, published: published) {
            onBlock?(block)
        }
    }
}

final class MareyCanvasView: UIView {
    private var published = PublishedOccupation.empty

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = PlateInk.backgroundUI
        isOpaque = true
        contentMode = .redraw
        layer.needsDisplayOnBoundsChange = true
        layer.drawsAsynchronously = false
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        return nil
    }

    override func draw(_ rect: CGRect) {
        guard let ctx = UIGraphicsGetCurrentContext() else { return }
        let size = bounds.size.width > 1 ? bounds.size : MareyPlate.contentSize
        MareyPlate.draw(in: ctx, dirty: CGRect(origin: .zero, size: size), size: size, published: published)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        setNeedsDisplay()
    }

    func publish(_ published: PublishedOccupation) {
        self.published = published
        contentScaleFactor = max(traitCollection.displayScale, 1)
        layer.drawsAsynchronously = false
        setNeedsDisplay()
        layer.displayIfNeeded()
    }
}

/// Role: Presentation. SwiftUI host for the tiled Marey. Chrome stays in SwiftUI.
struct MareySurfaceHost: UIViewRepresentable {
    var published: PublishedOccupation
    var playhead: Double
    var chainage: Double
    var interaction: Binding<DeskInteraction>
    var onViewport: ((CGPoint, CGFloat, CGSize) -> Void)? = nil

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> MareySurfaceView {
        MareySurfaceView()
    }

    func updateUIView(_ view: MareySurfaceView, context: Context) {
        view.onConflict = { mark in
            var desk = interaction.wrappedValue
            if let context = ApplyMeet.bind(
                laterTrainID: mark.trainID,
                blockID: mark.blockID,
                on: desk.board
            ) {
                desk.meetOffer = context.laterPath.offer()
                desk.selectedTrainID = context.laterPath.train.id
                desk.selectedBlockID = context.block.id
                desk.sheet = desk.meetOffer == nil ? desk.sheet : .meet
                if desk.meetOffer == nil {
                    desk.fault = "The token is still out."
                }
            } else {
                desk.presentMeet(mark)
            }
            interaction.wrappedValue = desk
        }
        view.onTrain = { train in
            var desk = interaction.wrappedValue
            desk.select(trainID: train.id, blockID: nil)
            interaction.wrappedValue = desk
        }
        view.onBlock = { block in
            var desk = interaction.wrappedValue
            desk.select(trainID: nil, blockID: block.id)
            interaction.wrappedValue = desk
        }
        view.onViewport = onViewport
        view.apply(published)
        if !context.coordinator.didCenter {
            view.scrollTo(seconds: playhead, chainage: chainage)
            context.coordinator.didCenter = true
            context.coordinator.playhead = playhead
            context.coordinator.chainage = chainage
        }
    }

    final class Coordinator {
        var didCenter = false
        var playhead: Double = -1
        var chainage: Double = -1
    }
}
