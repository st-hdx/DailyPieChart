import SwiftUI

@main
struct DailyPieChartApp: App {
    init() {
        // v1.0 は UserDefaults.standard に保存していたので、App Group へ移す。
        AppGroup.migrateFromStandardIfNeeded()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
