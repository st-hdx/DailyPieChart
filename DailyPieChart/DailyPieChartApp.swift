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
        // UIColor(Color) は生成時のトレイトで固定されるため、ダークモードに
        // 追従するよう動的な UIColor をここで組み立てる。
        tabBar.backgroundColor = UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(red: 0.09, green: 0.10, blue: 0.16, alpha: 1)
                : UIColor(red: 0.99, green: 0.96, blue: 0.85, alpha: 1)
        }
        UITabBar.appearance().standardAppearance = tabBar
        UITabBar.appearance().scrollEdgeAppearance = tabBar
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
