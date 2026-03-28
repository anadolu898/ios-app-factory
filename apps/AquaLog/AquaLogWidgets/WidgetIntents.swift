import AppIntents
import WidgetKit

/// Quick-add intent that runs directly in the widget — no app launch needed
struct QuickAddWaterIntent: AppIntent {
    static let title: LocalizedStringResource = "Quick Add Water"
    static let description = IntentDescription("Add water from a widget without opening AquaLog")
    static let isDiscoverable = false

    @Parameter(title: "Amount (mL)", default: 250)
    var amount: Int

    init() {}

    init(amount: Int) {
        self.amount = amount
    }

    func perform() async throws -> some IntentResult {
        let defaults = UserDefaults(suiteName: "group.com.anadolu898.aqualog")
        let current = defaults?.integer(forKey: "todayIntakeML") ?? 0
        defaults?.set(current + amount, forKey: "todayIntakeML")

        // Reload all widget timelines to show updated progress
        WidgetCenter.shared.reloadAllTimelines()

        return .result()
    }
}

/// Control Center toggle intent (iOS 18+)
struct LogWaterControlIntent: AppIntent {
    static let title: LocalizedStringResource = "Log Water"
    static let description = IntentDescription("Quick-log 250mL of water")
    static let isDiscoverable = true
    static let openAppWhenRun = false

    func perform() async throws -> some IntentResult {
        let defaults = UserDefaults(suiteName: "group.com.anadolu898.aqualog")
        let current = defaults?.integer(forKey: "todayIntakeML") ?? 0
        defaults?.set(current + 250, forKey: "todayIntakeML")
        WidgetCenter.shared.reloadAllTimelines()
        return .result()
    }
}
