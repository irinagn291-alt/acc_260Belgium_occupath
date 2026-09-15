import XCTest
@testable import Occupath

/// Placeholder. Replace with the cases required by SPEC.md section 17.
final class OccupathTests: XCTestCase {
    func test_appModuleImports() {
        XCTAssertEqual(String(describing: OccupathApp.self), "OccupathApp")
    }
}
