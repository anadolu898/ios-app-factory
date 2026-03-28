import ActivityKit
import Foundation

struct HydrationActivityAttributes: ActivityAttributes {
    // No dynamic attributes needed — the activity is always "today's hydration"

    struct ContentState: Codable, Hashable {
        let currentML: Int
        let goalML: Int

        var progress: Double {
            guard goalML > 0 else { return 0 }
            return min(Double(currentML) / Double(goalML), 1.0)
        }

        var percentText: String {
            "\(Int((progress * 100).rounded()))%"
        }

        var remainingML: Int {
            max(0, goalML - currentML)
        }

        var goalReached: Bool {
            currentML >= goalML
        }
    }
}
