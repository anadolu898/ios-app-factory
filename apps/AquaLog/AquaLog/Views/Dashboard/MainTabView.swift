import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            Tab(String(localized: "Today"), systemImage: "drop.fill") {
                DashboardView()
            }
            Tab(String(localized: "History"), systemImage: "calendar") {
                HistoryView()
            }
            Tab(String(localized: "Settings"), systemImage: "gearshape.fill") {
                SettingsView()
            }
        }
    }
}

#Preview {
    MainTabView()
        .modelContainer(for: [WaterLog.self, UserSettings.self], inMemory: true)
}
