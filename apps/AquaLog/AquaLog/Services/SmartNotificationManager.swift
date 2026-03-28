import Foundation
import UserNotifications

/// Context-aware notification system that sends personalized reminders
/// based on hydration progress, streaks, caffeine timing, and health milestones
@MainActor
final class SmartNotificationManager {
    static let shared = SmartNotificationManager()
    private init() {}

    // MARK: - Notification Categories

    enum NotificationType: String {
        case hydrationReminder     // Regular "drink water" reminders
        case progressUpdate        // "You're at 60% — keep going!"
        case caffeineWarning       // "Time to switch to water"
        case streakMotivation      // "5 day streak! Don't break it"
        case milestoneUnlocked     // "7 days — your kidneys thank you"
        case alcoholRecovery       // "Drink extra water after last night"
        case goalReached           // "Goal hit! Great job"
    }

    // MARK: - Smart Messages

    /// Context-aware reminder messages based on time of day and progress
    static func smartMessage(
        progress: Double,
        currentStreak: Int,
        caffeineMG: Double,
        hour: Int
    ) -> (title: String, body: String, type: NotificationType) {
        // Morning (6-10)
        if hour >= 6 && hour < 10 {
            if currentStreak > 0 {
                return (
                    String(localized: "Good morning! 🌅"),
                    String(localized: "Day \(currentStreak + 1) of your streak. Start with a glass of water — your body lost moisture overnight."),
                    .streakMotivation
                )
            }
            return (
                String(localized: "Rise & Hydrate"),
                String(localized: "Your body is mildly dehydrated after sleep. A glass of water now kickstarts your metabolism."),
                .hydrationReminder
            )
        }

        // Mid-morning (10-12) — caffeine check
        if hour >= 10 && hour < 12 {
            if caffeineMG > 200 {
                return (
                    String(localized: "Caffeine Check"),
                    String(localized: "You've had \(Int(caffeineMG))mg caffeine. Balance it with water — caffeine is a mild diuretic."),
                    .caffeineWarning
                )
            }
            if progress < 0.25 {
                return (
                    String(localized: "Slow Start Today"),
                    String(localized: "You're only at \(Int(progress * 100))%. Try to drink 500mL before lunch."),
                    .progressUpdate
                )
            }
        }

        // Afternoon (12-17)
        if hour >= 12 && hour < 17 {
            if progress >= 0.75 {
                return (
                    String(localized: "Almost There!"),
                    String(localized: "You're at \(Int(progress * 100))% — just a few more glasses to hit your goal."),
                    .progressUpdate
                )
            }
            if progress < 0.50 {
                return (
                    String(localized: "Afternoon Check-in"),
                    String(localized: "Half the day gone, but only \(Int(progress * 100))% hydrated. Time to catch up!"),
                    .progressUpdate
                )
            }
        }

        // Evening (17-21)
        if hour >= 17 && hour < 21 {
            if progress >= 1.0 {
                return (
                    String(localized: "Goal Reached!"),
                    String(localized: "You hit \(Int(progress * 100))% today. \(currentStreak > 1 ? "That's \(currentStreak) days in a row!" : "Keep it up tomorrow!")"),
                    .goalReached
                )
            }
            let remaining = max(0, 100 - Int(progress * 100))
            return (
                String(localized: "Evening Reminder"),
                String(localized: "You need \(remaining)% more to hit today's goal. A couple of glasses will do it."),
                .progressUpdate
            )
        }

        // Default
        return (
            String(localized: "Stay Hydrated"),
            String(localized: "Your body works best when properly hydrated. Take a moment to drink some water."),
            .hydrationReminder
        )
    }

    // MARK: - Milestone Notifications

    static func milestoneNotification(
        streakDays: Int
    ) -> (title: String, body: String)? {
        switch streakDays {
        case 3:
            return (
                String(localized: "3 Day Streak!"),
                String(localized: "Your brain is performing better — studies show hydration improves reaction time by 12%. Keep going!")
            )
        case 7:
            return (
                String(localized: "One Week Strong!"),
                String(localized: "7 days of optimal hydration. Your skin and kidneys are already benefiting. Check your Health Timeline for details.")
            )
        case 14:
            return (
                String(localized: "Two Weeks!"),
                String(localized: "Your exercise performance has likely improved 10-20%. Your body is thanking you. View your health insights.")
            )
        case 30:
            return (
                String(localized: "30 Day Champion!"),
                String(localized: "One month of consistent hydration. Your heart disease risk factors are improving. You've built a real habit.")
            )
        case 60:
            return (
                String(localized: "Habit Formed!"),
                String(localized: "66 days is the science-backed threshold for automatic habits. Hydration is now part of who you are.")
            )
        case 90:
            return (
                String(localized: "90 Day Legend"),
                String(localized: "Three months of optimal hydration. Your kidney function, skin health, and cardiovascular markers have all benefited. Incredible commitment.")
            )
        default:
            return nil
        }
    }

    // MARK: - Schedule Smart Notifications

    func scheduleSmartReminders(
        settings: UserSettings,
        todayProgress: Double,
        todayCaffeineMG: Double
    ) async {
        let center = UNUserNotificationCenter.current()
        let status = await center.notificationSettings()
        guard status.authorizationStatus == .authorized else { return }

        // Remove old smart notifications
        center.removePendingNotificationRequests(withIdentifiers: ["smart-next"])

        let calendar = Calendar.current
        let now = Date.now
        let currentHour = calendar.component(.hour, from: now)

        // Schedule next smart notification (2 hours from now, within waking hours)
        let nextHour = currentHour + 2
        guard nextHour >= settings.reminderStartHour && nextHour < settings.reminderEndHour else { return }

        let message = Self.smartMessage(
            progress: todayProgress,
            currentStreak: settings.currentStreak,
            caffeineMG: todayCaffeineMG,
            hour: nextHour
        )

        let content = UNMutableNotificationContent()
        content.title = message.title
        content.body = message.body
        content.sound = .default
        content.categoryIdentifier = message.type.rawValue

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 7200, repeats: false)
        let request = UNNotificationRequest(identifier: "smart-next", content: content, trigger: trigger)

        try? await center.add(request)
    }

    /// Schedule a milestone notification for immediate or near-future delivery
    func scheduleMilestoneNotification(streakDays: Int) async {
        guard let milestone = Self.milestoneNotification(streakDays: streakDays) else { return }

        let center = UNUserNotificationCenter.current()
        let content = UNMutableNotificationContent()
        content.title = milestone.title
        content.body = milestone.body
        content.sound = .default
        content.categoryIdentifier = NotificationType.milestoneUnlocked.rawValue

        // Fire in 5 seconds (feels like a real-time achievement)
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
        let request = UNNotificationRequest(
            identifier: "milestone-\(streakDays)",
            content: content,
            trigger: trigger
        )

        try? await center.add(request)
    }
}
