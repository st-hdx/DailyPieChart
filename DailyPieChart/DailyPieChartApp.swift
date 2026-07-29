import SwiftUI

@main
struct DailyPieChartApp: App {
    init() {
        // v1.0 は UserDefaults.standard に保存していたので、App Group へ移す。
        AppGroup.migrateFromStandardIfNeeded()

        // タブバーが透過のままだとリストの内容が透けてタブ名と重なるため、
        // テーマの背景色で不透明にする。
        let tabBar = UITabBarAppearance()
        tabBar.configureWithOpaqueBackground()
        tabBar.backgroundColor = UIColor(Theme.background)
        UITabBar.appearance().standardAppearance = tabBar
        UITabBar.appearance().scrollEdgeAppearance = tabBar
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
