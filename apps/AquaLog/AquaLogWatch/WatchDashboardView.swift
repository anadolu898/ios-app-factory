import SwiftUI

struct WatchDashboardView: View {
    @AppStorage("todayIntakeML", store: UserDefaults(suiteName: "group.com.anadolu898.aqualog"))
    private var todayIntake: Int = 0

    @AppStorage("dailyGoalML", store: UserDefaults(suiteName: "group.com.anadolu898.aqualog"))
    private var dailyGoal: Int = 2500

    private var progress: Double {
        guard dailyGoal > 0 else { return 0 }
        return min(Double(todayIntake) / Double(dailyGoal), 1.0)
    }

    private var percentText: String {
        "\(Int((progress * 100).rounded()))%"
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                // Progress ring
                ZStack {
                    Circle()
                        .stroke(Color(.darkGray), lineWidth: 10)

                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(
                            LinearGradient(
                                colors: [.cyan, .blue],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 10, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))

                    VStack(spacing: 2) {
                        Text(percentText)
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundStyle(.cyan)

                        if todayIntake >= dailyGoal {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                                .font(.caption)
                        }
                    }
                }
                .frame(width: 100, height: 100)
                .padding(.top, 4)

                // Intake text
                Text("\(todayIntake.watchVolumeString) / \(dailyGoal.watchVolumeString)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                // Quick add buttons
                HStack(spacing: 8) {
                    QuickAddButton(amount: 150, action: addDrink)
                    QuickAddButton(amount: 250, action: addDrink)
                    QuickAddButton(amount: 500, action: addDrink)
                }
            }
        }
        .navigationTitle("AquaLog")
    }

    private func addDrink(amount: Int) {
        todayIntake += amount
        // Haptic feedback on watch
        WKInterfaceDevice.current().play(.click)
    }
}

struct QuickAddButton: View {
    let amount: Int
    let action: (Int) -> Void

    var body: some View {
        Button {
            action(amount)
        } label: {
            VStack(spacing: 2) {
                Image(systemName: "drop.fill")
                    .font(.caption2)
                Text("\(amount)")
                    .font(.caption2.bold())
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
        }
        .buttonStyle(.bordered)
        .tint(.cyan)
    }
}

// Watch-specific volume formatting
extension Int {
    var watchVolumeString: String {
        if self >= 1000 {
            return String(format: "%.1fL", Double(self) / 1000.0)
        }
        return "\(self)mL"
    }
}

#Preview {
    WatchDashboardView()
}
