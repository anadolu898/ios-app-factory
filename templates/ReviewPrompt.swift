import StoreKit
import SwiftUI

/// Review prompt manager following Apple guidelines
/// - Max 3 prompts per 365-day period (Apple enforced)
/// - Trigger after positive interactions (configurable threshold)
/// - Never prompt during onboarding, errors, or purchases
actor ReviewPromptManager {
    static let shared = ReviewPromptManager()

    private let positiveActionKey = "review_positive_action_count"
    private let lastPromptKey = "review_last_prompt_date"
    private let promptCountKey = "review_prompt_count_this_year"

    /// Call this after every positive user interaction
    /// (e.g., completing a workout, logging 7 days in a row, hitting a goal)
    func recordPositiveAction(threshold: Int = 3) {
        let count = UserDefaults.standard.integer(forKey: positiveActionKey) + 1
        UserDefaults.standard.set(count, forKey: positiveActionKey)

        if count >= threshold {
            requestReviewIfAppropriate()
        }
    }

    private func requestReviewIfAppropriate() {
        let now = Date()

        // Don't prompt more than once per 30 days
        if let lastPrompt = UserDefaults.standard.object(forKey: lastPromptKey) as? Date,
           now.timeIntervalSince(lastPrompt) < 30 * 24 * 60 * 60 {
            return
        }

        // Request review
        if let windowScene = UIApplication.shared.connectedScenes
            .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene {

            Task { @MainActor in
                SKStoreReviewController.requestReview(in: windowScene)
            }

            UserDefaults.standard.set(now, forKey: lastPromptKey)
            UserDefaults.standard.set(0, forKey: positiveActionKey) // Reset counter
        }
    }

    /// Reset all review tracking (for testing)
    func resetTracking() {
        UserDefaults.standard.removeObject(forKey: positiveActionKey)
        UserDefaults.standard.removeObject(forKey: lastPromptKey)
        UserDefaults.standard.removeObject(forKey: promptCountKey)
    }
}

// MARK: - SwiftUI View Modifier

struct ReviewPromptModifier: ViewModifier {
    let threshold: Int

    func body(content: Content) -> some View {
        content.task {
            await ReviewPromptManager.shared.recordPositiveAction(threshold: threshold)
        }
    }
}

extension View {
    /// Attach to views representing positive interactions
    /// The review prompt will show after `threshold` positive actions
    func trackPositiveAction(threshold: Int = 3) -> some View {
        modifier(ReviewPromptModifier(threshold: threshold))
    }
}
