import SwiftUI

/// Role: Presentation. Viewport of the tiled Marey, for token overlays only.
struct TokenViewport: Equatable {
    var offset: CGPoint = .zero
    var zoom: CGFloat = 1
    var canvas: CGSize = MareyPlate.contentSize
}

/// Role: Presentation. Token marks as SwiftUI overlays so VoiceOver can name the twist.
struct TokenMarkOverlay: View {
    @Binding var interaction: DeskInteraction
    var viewport: TokenViewport
    @Environment(\.sizeCategory) private var sizeCategory

    var body: some View {
        GeometryReader { _ in
            ForEach(marks) { mark in
                TokenMarkButton(mark: mark, sizeCategory: sizeCategory) {
                    activate(mark)
                }
                .position(
                    x: mark.point.x * viewport.zoom - viewport.offset.x,
                    y: mark.point.y * viewport.zoom - viewport.offset.y
                )
            }
        }
    }

    private var marks: [TokenOverlayItem] {
        let published = interaction.published
        let size = viewport.canvas.width > 0 ? viewport.canvas : MareyPlate.contentSize
        return published.board.tokens.compactMap { token in
            guard let block = published.board.block(id: token.blockID),
                  let point = MareyPlate.tokenPoint(token: token, in: size, published: published)
            else { return nil }
            let name = token.holder.flatMap { published.board.train(id: $0.trainID)?.name }
            return TokenOverlayItem(token: token, block: block, point: point, holderName: name)
        }
    }

    private func activate(_ mark: TokenOverlayItem) {
        if mark.token.holder != nil {
            if let context = try? HandToken.bind(blockID: mark.block.id, on: interaction.board) {
                interaction.adopt(context.holder?.returnToken() ?? context.issuedToken.release())
            }
            return
        }
        let trainID = interaction.selectedTrainID ?? interaction.published.board.trains.first?.id
        if let trainID,
           let context = try? OccupyBlock.bind(trainID: trainID, blockID: mark.block.id, on: interaction.board)
        {
            do {
                interaction.adopt(try context.occupier.take())
            } catch BoardError.tokenHeld {
                interaction.presentMeet(trainID: context.occupier.train.id, blockID: context.block.id)
            } catch {
                interaction.fault = plateCopy(error)
            }
        } else {
            interaction.select(trainID: nil, blockID: mark.block.id)
        }
    }
}

struct TokenOverlayItem: Identifiable, Equatable {
    var token: Token
    var block: SingleLineBlock
    var point: CGPoint
    var holderName: String?

    var id: UUID { token.blockID }
}

/// Role: Presentation. Held = square ticket with H. Free = ring with T. Colour is not the only signal.
struct TokenMarkButton: View {
    var mark: TokenOverlayItem
    var sizeCategory: ContentSizeCategory
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                if mark.token.holder != nil {
                    Rectangle()
                        .fill(PlateInk.ink)
                        .frame(width: 18, height: 18)
                    Rectangle()
                        .stroke(PlateInk.accent, lineWidth: 2)
                        .frame(width: 18, height: 18)
                    Text("H")
                        .plateText(.stamp, category: sizeCategory)
                        .foregroundStyle(PlateInk.surface)
                } else {
                    Circle()
                        .stroke(PlateInk.ink, lineWidth: 2)
                        .frame(width: 18, height: 18)
                    Text("T")
                        .plateText(.stamp, category: sizeCategory)
                }
            }
            .frame(width: PlateInk.tap, height: PlateInk.tap)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(TokenMarkCopy.label(holderName: mark.holderName, block: mark.block))
        .accessibilityHint(mark.token.holder != nil ? "Hands the token back to the block" : "Takes the token for the selected consist")
        .accessibilityAddTraits(.isButton)
    }
}

enum TokenMarkCopy {
    static func label(holderName: String?, block: SingleLineBlock) -> String {
        let span = "\(block.fromMilepost) to \(block.toMilepost)"
        if let holderName {
            return "Token held by \(holderName) on \(span)"
        }
        return "Token at the block \(span)"
    }
}
