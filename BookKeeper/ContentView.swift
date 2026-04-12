import SwiftUI

struct ContentView: View {
    @EnvironmentObject var bookVM: BookViewModel
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            QuickEntryView()
                .tabItem {
                    Label("Record", systemImage: "plus.circle")
                }
                .tag(0)

            BillListView()
                .tabItem {
                    Label("Bills", systemImage: "list.bullet")
                }
                .tag(1)

            StatisticsView()
                .tabItem {
                    Label("Stats", systemImage: "chart.pie")
                }
                .tag(2)

            BookManagementView()
                .tabItem {
                    Label("Ledgers", systemImage: "book")
                }
                .tag(3)

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
                .tag(4)
        }
        .tint(.accentColor)
    }
}

