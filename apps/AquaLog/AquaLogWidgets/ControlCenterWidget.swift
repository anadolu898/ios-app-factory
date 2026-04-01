import WidgetKit
import SwiftUI

/// iOS 18 Control Center widget — one tap from Control Center, Lock Screen, or Action Button
@available(iOS 18.0, *)
struct AquaLogControlWidget: ControlWidget {
    let kind = "AquaLogControlWidget"

    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(kind: kind) {
            ControlWidgetButton(action: LogWaterControlIntent()) {
                Label {
                    Text(currentProgressText())
                } icon: {
                    Image(systemName: "drop.fill")
                }
            }
        }
        .displayName("Log Water")
        .description("Quick-log 250 mL of water with one tap")
    }

    private func currentProgressText() -> String {
        let defaults = UserDefaults(suiteName: "group.com.rightbehind.aqualog")
        let current = defaults?.integer(forKey: "todayIntakeML") ?? 0
        let goal = defaults?.integer(forKey: "dailyGoalML") ?? 2500
        let percent = goal > 0 ? Int(Double(current) / Double(goal) * 100) : 0
        return "\(percent)%"
    }
}
