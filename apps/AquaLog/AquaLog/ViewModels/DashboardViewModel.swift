import Foundation
import SwiftData
import SwiftUI
import WidgetKit

@Observable @MainActor
final class DashboardViewModel {

    // MARK: - Properties

    private var modelContext: ModelContext?

    var todayLogs: [WaterLog] = []
    var settings: UserSettings?

    var todayTotal: Int {
        todayLogs.reduce(0) { $0 + $1.amount }
    }

    var dailyGoal: Int {
        settings?.dailyGoalML ?? 2500
    }

    var todayProgress: Double {
        guard dailyGoal > 0 else { return 0 }
        return Double(todayTotal) / Double(dailyGoal)
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

    // MARK: - Setup

    func setup(modelContext: ModelContext) {
        self.modelContext = modelContext
        fetchTodayLogs()
        fetchSettings()
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
        syncToWidgets()
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

    // MARK: - Haptics

    private func triggerHaptic() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }
}
