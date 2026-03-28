import Foundation
import SwiftData

@Model
final class UserSettings {
    var dailyGoalML: Int
    var unitSystem: String // "metric" or "imperial"
    var reminderEnabled: Bool
    var reminderIntervalMinutes: Int
    var reminderStartHour: Int
    var reminderEndHour: Int
    var hasCompletedOnboarding: Bool
    var isPremium: Bool
    var createdAt: Date

    init(
        dailyGoalML: Int = 2500,
        unitSystem: String = "metric",
        reminderEnabled: Bool = true,
        reminderIntervalMinutes: Int = 60,
        reminderStartHour: Int = 8,
        reminderEndHour: Int = 22,
        hasCompletedOnboarding: Bool = false,
        isPremium: Bool = false
    ) {
        self.dailyGoalML = dailyGoalML
        self.unitSystem = unitSystem
        self.reminderEnabled = reminderEnabled
        self.reminderIntervalMinutes = reminderIntervalMinutes
        self.reminderStartHour = reminderStartHour
        self.reminderEndHour = reminderEndHour
        self.hasCompletedOnboarding = hasCompletedOnboarding
        self.isPremium = isPremium
        self.createdAt = .now
    }

    var dailyGoalDisplayString: String {
        if unitSystem == "imperial" {
            let oz = Double(dailyGoalML) / 29.5735
            return String(format: "%.0f oz", oz)
        }
        if dailyGoalML >= 1000 {
            return String(format: "%.1f L", Double(dailyGoalML) / 1000.0)
        }
        return "\(dailyGoalML) mL"
    }
}
