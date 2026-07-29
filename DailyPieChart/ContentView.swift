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
        .preferredColorScheme(.light)
    }
}
