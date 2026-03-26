import SwiftUI

struct ContentView: View {
    @StateObject private var store = StoreManager()

    var body: some View {
        TabView {
            PersonListView()
                .tabItem {
                    Label("偉人", systemImage: "person.3.fill")
                }
            MyScheduleView()
                .tabItem {
                    Label("マイスケジュール", systemImage: "chart.pie.fill")
                }
        }
        .environmentObject(store)
        .preferredColorScheme(.light)
    }
}
