import SwiftUI
import SwiftData
import Sentry

@main
struct AquaLogApp: App {
    let modelContainer: ModelContainer

    init() {
        // Initialize Sentry crash reporting
        SentrySDK.start { options in
            options.dsn = "https://a158f91e4538efa909e8c600547baa69@o4511124056244225.ingest.de.sentry.io/4511124072235088"
            options.tracesSampleRate = 0.2
            options.enableAutoSessionTracking = true
            options.attachScreenshot = true
            #if DEBUG
            options.enabled = false // Disable in debug builds
            #endif
        }

        // Initialize RevenueCat
        StoreManager.shared.configure()

        // Initialize SwiftData
        do {
            let schema = Schema([
                WaterLog.self,
                UserSettings.self
            ])
            let modelConfiguration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false
            )
            modelContainer = try ModelContainer(
                for: schema,
                configurations: [modelConfiguration]
            )
        } catch {
            fatalError("Could not initialize ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(modelContainer)
    }
}
