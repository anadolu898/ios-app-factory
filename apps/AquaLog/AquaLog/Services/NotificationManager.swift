import Foundation
import UserNotifications

@MainActor
final class NotificationManager {
    static let shared = NotificationManager()

    private init() {}

    // MARK: - Permission

    func requestPermission() async -> Bool {
        do {
            return try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            return false
        }
    }

    func checkPermission() async -> UNAuthorizationStatus {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        return settings.authorizationStatus
    }

    // MARK: - Schedule Reminders

    func scheduleReminders(
        intervalMinutes: Int,
        startHour: Int,
        endHour: Int
    ) async {
        // Remove existing reminders first
        cancelAllReminders()

        let status = await checkPermission()
        guard status == .authorized else { return }

        let center = UNUserNotificationCenter.current()

        // Schedule for the next 6 days (max 64 notifications)
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)

        let messages = [
            String(localized: "Time for a drink! Stay hydrated."),
            String(localized: "Don't forget to drink water!"),
            String(localized: "Your body needs water. Take a sip!"),
            String(localized: "Hydration check! Have you had water recently?"),
            String(localized: "A glass of water keeps you going!"),
            String(localized: "Quick reminder to stay hydrated.")
        ]

        var notificationCount = 0
        let maxNotifications = 60 // Leave room under the 64 limit

        for dayOffset in 0..<7 {
            guard notificationCount < maxNotifications else { break }

            guard let day = calendar.date(byAdding: .day, value: dayOffset, to: today) else { continue }

            var currentHour = startHour
            var currentMinute = 0

            while currentHour < endHour && notificationCount < maxNotifications {
                var dateComponents = calendar.dateComponents([.year, .month, .day], from: day)
                dateComponents.hour = currentHour
                dateComponents.minute = currentMinute

                guard let fireDate = calendar.date(from: dateComponents),
                      fireDate > .now else {
                    currentMinute += intervalMinutes
                    if currentMinute >= 60 {
                        currentHour += currentMinute / 60
                        currentMinute = currentMinute % 60
                    }
                    continue
                }

                let content = UNMutableNotificationContent()
                content.title = String(localized: "AquaLog")
                content.body = messages[notificationCount % messages.count]
                content.sound = .default
                content.categoryIdentifier = "HYDRATION_REMINDER"

                let trigger = UNCalendarNotificationTrigger(
                    dateMatching: calendar.dateComponents(
                        [.year, .month, .day, .hour, .minute],
                        from: fireDate
                    ),
                    repeats: false
                )

                let request = UNNotificationRequest(
                    identifier: "reminder-\(dayOffset)-\(currentHour)-\(currentMinute)",
                    content: content,
                    trigger: trigger
                )

                do {
                    try await center.add(request)
                    notificationCount += 1
                } catch {
                    // Skip failed notification
                }

                currentMinute += intervalMinutes
                if currentMinute >= 60 {
                    currentHour += currentMinute / 60
                    currentMinute = currentMinute % 60
                }
            }
        }
    }

    // MARK: - Cancel

    func cancelAllReminders() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
}
