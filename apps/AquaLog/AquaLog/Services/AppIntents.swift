import AppIntents
import SwiftData

// MARK: - Log Water Intent

struct LogWaterIntent: AppIntent {
    static let title: LocalizedStringResource = "Log Water"
    static let description = IntentDescription("Log a glass of water to AquaLog")
    static let openAppWhenRun = false

    @Parameter(title: "Amount (mL)", default: 250)
    var amount: Int

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let defaults = UserDefaults(suiteName: "group.com.anadolu898.aqualog")
        let current = defaults?.integer(forKey: "todayIntakeML") ?? 0
        defaults?.set(current + amount, forKey: "todayIntakeML")

        return .result(dialog: "Logged \(amount) mL of water. Total today: \(current + amount) mL")
    }
}

// MARK: - Log Coffee Intent

struct LogCoffeeIntent: AppIntent {
    static let title: LocalizedStringResource = "Log Coffee"
    static let description = IntentDescription("Log a cup of coffee to AquaLog")
    static let openAppWhenRun = false

    @Parameter(title: "Amount (mL)", default: 250)
    var amount: Int

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let defaults = UserDefaults(suiteName: "group.com.anadolu898.aqualog")
        let current = defaults?.integer(forKey: "todayIntakeML") ?? 0
        defaults?.set(current + amount, forKey: "todayIntakeML")

        let caffeine = Int(95.0 * Double(amount) / 250.0)
        return .result(dialog: "Logged \(amount) mL coffee (\(caffeine) mg caffeine). Total today: \(current + amount) mL")
    }
}

// MARK: - Log Wine Intent

struct LogWineIntent: AppIntent {
    static let title: LocalizedStringResource = "Log Wine"
    static let description = IntentDescription("Log a glass of wine and see its dehydration impact")
    static let openAppWhenRun = false

    @Parameter(title: "Amount (mL)", default: 150)
    var amount: Int

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let defaults = UserDefaults(suiteName: "group.com.anadolu898.aqualog")
        let current = defaults?.integer(forKey: "todayIntakeML") ?? 0

        let net = NutrientDatabase.netHydration(beverageId: "wine_red", volumeML: amount)
        defaults?.set(current + net.netML, forKey: "todayIntakeML")

        return .result(dialog: "Logged \(amount) mL wine. Net hydration: only \(net.netML) mL. Drink \(net.waterDebt) mL extra water to compensate!")
    }
}

// MARK: - Check Hydration Intent

struct CheckHydrationIntent: AppIntent {
    static let title: LocalizedStringResource = "Check Hydration"
    static let description = IntentDescription("See your current hydration progress")
    static let openAppWhenRun = false

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let defaults = UserDefaults(suiteName: "group.com.anadolu898.aqualog")
        let current = defaults?.integer(forKey: "todayIntakeML") ?? 0
        let goal = defaults?.integer(forKey: "dailyGoalML") ?? 2500
        let percent = goal > 0 ? Int(Double(current) / Double(goal) * 100) : 0

        if current >= goal {
            return .result(dialog: "You've hit your goal! \(current) mL of \(goal) mL (\(percent)%). Great job!")
        } else {
            let remaining = goal - current
            return .result(dialog: "You're at \(percent)% — \(current) mL of \(goal) mL. Drink \(remaining) mL more to hit your goal.")
        }
    }
}

// MARK: - Shortcuts Provider

struct AquaLogShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: LogWaterIntent(),
            phrases: [
                "Log water in \(.applicationName)",
                "Add water to \(.applicationName)",
                "I drank water with \(.applicationName)"
            ],
            shortTitle: "Log Water",
            systemImageName: "drop.fill"
        )

        AppShortcut(
            intent: LogCoffeeIntent(),
            phrases: [
                "Log coffee in \(.applicationName)",
                "I had a coffee in \(.applicationName)",
                "Add coffee to \(.applicationName)"
            ],
            shortTitle: "Log Coffee",
            systemImageName: "mug.fill"
        )

        AppShortcut(
            intent: LogWineIntent(),
            phrases: [
                "Log wine in \(.applicationName)",
                "I had a glass of wine in \(.applicationName)",
                "Log alcohol in \(.applicationName)"
            ],
            shortTitle: "Log Wine",
            systemImageName: "wineglass.fill"
        )

        AppShortcut(
            intent: CheckHydrationIntent(),
            phrases: [
                "Check hydration in \(.applicationName)",
                "How much water in \(.applicationName)",
                "Show my water intake in \(.applicationName)"
            ],
            shortTitle: "Check Hydration",
            systemImageName: "chart.bar.fill"
        )
    }
}
