import SwiftUI

struct ContentView: View {
    @StateObject private var store = StoreManager()

    var body: some View {
        TabView {
            PersonListView()
                .tabItem {
                    Label("tab.persons", systemImage: "person.3.fill")
                }
            MyScheduleView()
                .tabItem {
                    Label("tab.my_schedule", systemImage: "chart.pie.fill")
                }
        }
        .environmentObject(store)
        .preferredColorScheme(.light)
    }
}
