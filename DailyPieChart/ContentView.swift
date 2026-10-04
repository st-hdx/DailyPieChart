import SwiftUI

struct ContentView: View {
    @StateObject private var store = StoreManager()
    /// オンボーディングから「偉人タブ」へ送るためにタブ選択を保持する。
    @State private var selectedTab = Tab.persons

    enum Tab: Hashable { case persons, mySchedule }

    var body: some View {
        TabView(selection: $selectedTab) {
            PersonListView()
                .tabItem {
                    Label("tab.persons", systemImage: "person.3.fill")
                }
                .tag(Tab.persons)
            MyScheduleView(selectedTab: $selectedTab)
                .tabItem {
                    Label("tab.my_schedule", systemImage: "chart.pie.fill")
                }
                .tag(Tab.mySchedule)
        }
        .environmentObject(store)
        #if DEBUG
        .onAppear {
            // シミュレータでの動作確認用: 起動引数 -selectedTab mySchedule でタブを指定して起動する
            if ProcessInfo.processInfo.arguments.contains("-selectedTab"),
               let idx = ProcessInfo.processInfo.arguments.firstIndex(of: "-selectedTab"),
               idx + 1 < ProcessInfo.processInfo.arguments.count,
               ProcessInfo.processInfo.arguments[idx + 1] == "mySchedule" {
                selectedTab = .mySchedule
            }
        }
        #endif
    }
}
