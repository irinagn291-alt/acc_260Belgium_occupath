import SwiftUI
import XCTest
@testable import Occupath

final class PlateArtTests: XCTestCase {
    func test_artNamesCarryPrefix() {
        XCTAssertEqual(PlateArt.emptyHome, "ocp_EmptyHome")
        XCTAssertEqual(PlateArt.emptyList, "ocp_EmptyList")
        XCTAssertEqual(PlateArt.card, "ocp_CardBackdrop")
        XCTAssertEqual(PlateArt.control, "ocp_ControlFace")
        XCTAssertEqual(PlateArt.twist, "ocp_TwistHero")
        XCTAssertEqual(PlateArt.success, "ocp_SuccessMark")
        XCTAssertEqual(PlateArt.header, "ocp_HeaderDecor")
        XCTAssertEqual(PlateArt.splash, "ocp_Splash")
        XCTAssertEqual(PlateArt.onboarding(0), "ocp_Onboarding1")
        XCTAssertEqual(PlateArt.onboarding(1), "ocp_Onboarding2")
        XCTAssertEqual(PlateArt.onboarding(2), "ocp_Onboarding3")
    }

    @MainActor
    func test_twistScreenConstructsEmptyAndPopulated() {
        let empty = TokenOccupationView(interaction: .constant(.previewEmpty()))
        XCTAssertTrue(empty.interaction.published.board.blocks.isEmpty)
        let populated = TokenOccupationView()
        XCTAssertFalse(populated.interaction.published.board.tokens.isEmpty)
        XCTAssertEqual(DeskSheet.token.rawValue, "token")
    }

    func test_paletteTokensAreNamedColours() {
        XCTAssertEqual(PlateInk.face, "DIN Condensed")
        XCTAssertEqual(PlateInk.unit, 8)
        XCTAssertEqual(PlateInk.tap, 44)
        XCTAssertEqual(PlateInk.Step.allCases.count, 6)
    }

    func test_bodyUsesRegularAndDisplayUsesBold() {
        XCTAssertEqual(PlateInk.Step.body.postScript, "DINCondensed-Regular")
        XCTAssertEqual(PlateInk.Step.caption.postScript, "DINCondensed-Regular")
        XCTAssertEqual(PlateInk.Step.plate.postScript, "DINCondensed-Bold")
        XCTAssertEqual(PlateInk.Step.token.postScript, "DINCondensed-Bold")
        let fonts = Bundle.main.object(forInfoDictionaryKey: "UIAppFonts") as? [String] ?? []
        XCTAssertTrue(fonts.contains("DINCondensed-Bold.ttf"))
        XCTAssertTrue(fonts.contains("DINCondensed-Regular.ttf"))
        XCTAssertNotNil(Bundle.main.url(forResource: "DINCondensed-Bold", withExtension: "ttf"))
        XCTAssertNotNil(Bundle.main.url(forResource: "DINCondensed-Regular", withExtension: "ttf"))
    }
}
