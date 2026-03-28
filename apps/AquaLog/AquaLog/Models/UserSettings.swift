import Foundation
import SwiftData

@Model
final class UserSettings {
    // Core settings
    var dailyGoalML: Int
    var unitSystem: String // "metric" or "imperial"
    var reminderEnabled: Bool
    var reminderIntervalMinutes: Int
    var reminderStartHour: Int
    var reminderEndHour: Int
    var hasCompletedOnboarding: Bool
    var isPremium: Bool
    var createdAt: Date

    // Profile (from smart onboarding)
    var weightKg: Double
    var age: Int
    var gender: String // "male", "female", "other"
    var activityLevel: String // rawValue of HydrationCalculator.ActivityLevel
    var wakeUpHour: Int
    var wakeUpMinute: Int
    var bedtimeHour: Int
    var bedtimeMinute: Int
    var isPregnant: Bool
    var isBreastfeeding: Bool

    // AI-calculated
    var aiCalculatedGoalML: Int // The goal AI recommended
    var lastWeatherAdjustment: Date? // When we last adjusted for weather
    var climateOverride: String? // Manual climate setting

    // Streaks
    var currentStreak: Int
    var longestStreak: Int
    var lastGoalMetDate: Date?

    init(
        dailyGoalML: Int = 2500,
        unitSystem: String = "metric",
        reminderEnabled: Bool = true,
        reminderIntervalMinutes: Int = 60,
        reminderStartHour: Int = 8,
        reminderEndHour: Int = 22,
        hasCompletedOnboarding: Bool = false,
        isPremium: Bool = false,
        weightKg: Double = 70,
        age: Int = 30,
        gender: String = "other",
        activityLevel: String = "moderate",
        wakeUpHour: Int = 7,
        wakeUpMinute: Int = 0,
        bedtimeHour: Int = 23,
        bedtimeMinute: Int = 0,
        isPregnant: Bool = false,
        isBreastfeeding: Bool = false
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
        self.weightKg = weightKg
        self.age = age
        self.gender = gender
        self.activityLevel = activityLevel
        self.wakeUpHour = wakeUpHour
        self.wakeUpMinute = wakeUpMinute
        self.bedtimeHour = bedtimeHour
        self.bedtimeMinute = bedtimeMinute
        self.isPregnant = isPregnant
        self.isBreastfeeding = isBreastfeeding
        self.aiCalculatedGoalML = dailyGoalML
        self.currentStreak = 0
        self.longestStreak = 0
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
