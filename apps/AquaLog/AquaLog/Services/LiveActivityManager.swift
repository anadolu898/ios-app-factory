import ActivityKit
import Foundation

/// Manages the all-day hydration Live Activity on Lock Screen and Dynamic Island
@MainActor
final class LiveActivityManager {
    static let shared = LiveActivityManager()
    private init() {}

    private var currentActivity: Activity<HydrationActivityAttributes>?

    /// Start a new Live Activity for today's hydration tracking
    func startTracking(currentML: Int, goalML: Int) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }

        // End any existing activity first
        Task { await endTracking() }

        let attributes = HydrationActivityAttributes()
        let state = HydrationActivityAttributes.ContentState(
            currentML: currentML,
            goalML: goalML
        )

        do {
            currentActivity = try Activity<HydrationActivityAttributes>.request(
                attributes: attributes,
                content: .init(state: state, staleDate: nil),
                pushType: nil
            )
        } catch {
            // Live Activity not supported or failed
        }
    }

    /// Update the Live Activity with new hydration data
    func updateProgress(currentML: Int, goalML: Int) {
        guard let activity = currentActivity else {
            // No active Live Activity, start one
            startTracking(currentML: currentML, goalML: goalML)
            return
        }

        let state = HydrationActivityAttributes.ContentState(
            currentML: currentML,
            goalML: goalML
        )

        Task {
            await activity.update(.init(state: state, staleDate: nil))
        }
    }

    /// End the Live Activity
    func endTracking() async {
        for activity in Activity<HydrationActivityAttributes>.activities {
            await activity.end(nil, dismissalPolicy: .immediate)
        }
        currentActivity = nil
    }
}
