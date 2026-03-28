import SwiftUI
import SwiftData

struct ContentView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    var body: some View {
        if hasCompletedOnboarding {
            MainTabView()
        } else {
            SmartOnboardingView()
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [WaterLog.self, UserSettings.self], inMemory: true)
}
