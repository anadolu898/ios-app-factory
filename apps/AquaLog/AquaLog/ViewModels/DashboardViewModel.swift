import CoreLocation
import Foundation
import SwiftData
import SwiftUI
import WidgetKit

@Observable @MainActor
final class DashboardViewModel {

    // MARK: - Properties

    private var modelContext: ModelContext?

    // Stored properties — must be stored (not computed) for @Observable to track changes
    var todayLogs: [WaterLog] = []
    var settings: UserSettings?
    var todayTotal: Int = 0
    var todayProgress: Double = 0
    var todayCaffeineMG: Double = 0
    var currentStreak: Int = 0
    var longestStreak: Int = 0

    // Weather
    var currentClimate: HydrationCalculator.Climate = .temperate
    var weatherAdjustmentML: Int = 0

    var dailyGoal: Int {
        settings?.dailyGoalML ?? 2500
    }

    var unitSystem: String {
        settings?.unitSystem ?? "metric"
    }

    var progressText: String {
        "\(todayTotal.volumeString(unitSystem: unitSystem)) / \(dailyGoal.volumeString(unitSystem: unitSystem))"
    }

    var percentageText: String {
        let pct = Int((todayProgress * 100).rounded())
        return "\(pct)%"
    }

    var goalReached: Bool {
        todayTotal >= dailyGoal
    }

    var caffeineStatus: (message: String, severity: CaffeineInfo.CaffeineSeverity)? {
        CaffeineInfo.statusMessage(totalCaffeineMG: todayCaffeineMG)
    }

    var weatherMessage: String? {
        guard currentClimate != .temperate && currentClimate != .cool else { return nil }
        return String(localized: "It's \(currentClimate.displayName.lowercased()) today — drink \(weatherAdjustmentML) mL extra!")
    }

    // MARK: - Setup

    func setup(modelContext: ModelContext) {
        self.modelContext = modelContext
        fetchTodayLogs()
        fetchSettings()
        updateStreak()
        syncHealthKit()
    }

    // MARK: - Fetch

    func fetchTodayLogs() {
        guard let modelContext else { return }

        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: .now)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? .now

        let predicate = #Predicate<WaterLog> { log in
            log.timestamp >= startOfDay && log.timestamp < endOfDay
        }

        let descriptor = FetchDescriptor<WaterLog>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )

        do {
            todayLogs = try modelContext.fetch(descriptor)
        } catch {
            todayLogs = []
        }

        recalculate()
    }

    func fetchSettings() {
        guard let modelContext else { return }

        let descriptor = FetchDescriptor<UserSettings>()
        do {
            let allSettings = try modelContext.fetch(descriptor)
            if let existing = allSettings.first {
                settings = existing
            } else {
                let newSettings = UserSettings()
                modelContext.insert(newSettings)
                try? modelContext.save()
                settings = newSettings
            }
        } catch {
            settings = nil
        }

        recalculate()
    }

    /// Recalculate all derived stored properties from current data
    private func recalculate() {
        let total = todayLogs.reduce(0) { $0 + $1.amount }
        let goal = dailyGoal

        withAnimation(.easeInOut(duration: 0.5)) {
            todayTotal = total
            todayProgress = goal > 0 ? Double(total) / Double(goal) : 0
        }

        todayCaffeineMG = todayLogs.reduce(0.0) { acc, log in
            acc + CaffeineInfo.caffeinePerServing(beverage: log.beverageType, amountML: log.amount)
        }

        currentStreak = settings?.currentStreak ?? 0
        longestStreak = settings?.longestStreak ?? 0
    }

    // MARK: - Actions

    func addDrink(amount: Int, beverageType: String = "water", note: String? = nil) {
        guard let modelContext else { return }

        let log = WaterLog(amount: amount, beverageType: beverageType, note: note)
        modelContext.insert(log)

        do {
            try modelContext.save()
        } catch {
            // Save failed silently for now
        }

        fetchTodayLogs()
        updateStreak()
        syncToWidgets()
        saveToHealthKit(amount: amount)
        scheduleSmartNotifications()
        triggerHaptic()
    }

    func deleteDrink(_ log: WaterLog) {
        guard let modelContext else { return }

        modelContext.delete(log)

        do {
            try modelContext.save()
        } catch {
            // Delete failed silently
        }

        fetchTodayLogs()
    }

    // MARK: - Widget Sync

    private func syncToWidgets() {
        let defaults = UserDefaults(suiteName: "group.com.anadolu898.aqualog")
        defaults?.set(todayTotal, forKey: "todayIntakeML")
        defaults?.set(dailyGoal, forKey: "dailyGoalML")
        WidgetKit.WidgetCenter.shared.reloadAllTimelines()
    }

    // MARK: - Streak Management

    private func updateStreak() {
        guard let settings, let modelContext else { return }

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)

        // Check if we met today's goal
        if todayTotal >= dailyGoal {
            if let lastDate = settings.lastGoalMetDate {
                let lastDay = calendar.startOfDay(for: lastDate)
                if calendar.isDate(lastDay, inSameDayAs: today) {
                    // Already updated today
                    return
                }
                let yesterday = calendar.date(byAdding: .day, value: -1, to: today) ?? today
                if calendar.isDate(lastDay, inSameDayAs: yesterday) {
                    // Consecutive day — extend streak
                    settings.currentStreak += 1
                } else {
                    // Streak broken, start new
                    settings.currentStreak = 1
                }
            } else {
                settings.currentStreak = 1
            }

            settings.lastGoalMetDate = .now
            settings.longestStreak = max(settings.longestStreak, settings.currentStreak)
            try? modelContext.save()
        }
    }

    // MARK: - Smart Notifications

    private func scheduleSmartNotifications() {
        guard let settings, settings.reminderEnabled else { return }
        Task {
            // Schedule context-aware notification
            await SmartNotificationManager.shared.scheduleSmartReminders(
                settings: settings,
                todayProgress: todayProgress,
                todayCaffeineMG: todayCaffeineMG
            )

            // Check for milestone notification
            if goalReached {
                await SmartNotificationManager.shared.scheduleMilestoneNotification(
                    streakDays: settings.currentStreak
                )
            }

            // Also keep the regular interval reminders
            await NotificationManager.shared.scheduleReminders(
                intervalMinutes: settings.reminderIntervalMinutes,
                startHour: settings.reminderStartHour,
                endHour: settings.reminderEndHour
            )
        }
    }

    // MARK: - HealthKit

    private func syncHealthKit() {
        Task {
            let status = HealthKitManager.shared.authorizationStatus()
            guard status == .sharingAuthorized else { return }
            // Sync today's HealthKit water data as context (read-only for now)
            _ = await HealthKitManager.shared.todayWaterIntake()
        }
    }

    func saveToHealthKit(amount: Int) {
        Task {
            _ = await HealthKitManager.shared.saveWaterIntake(milliliters: amount)
        }
    }

    // MARK: - Haptics

    private func triggerHaptic() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }
}
