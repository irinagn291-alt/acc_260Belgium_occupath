import SwiftUI
@testable import Occupath

enum ScreenCatalog {
    @MainActor
    static var shots: [(String, AnyView)] {
        [
            ("mareydesk", AnyView(MareyDeskView())),
            ("weekledger", AnyView(WeekLedgerView())),
            ("settings", AnyView(SettingsView()))
        ]
    }
}
