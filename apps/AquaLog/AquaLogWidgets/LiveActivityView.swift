import SwiftUI
import WidgetKit
import ActivityKit

/// Live Activity UI — shows on Lock Screen and Dynamic Island all day
struct HydrationLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: HydrationActivityAttributes.self) { context in
            // Lock Screen / Notification banner view
            lockScreenView(state: context.state)
        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded view
                DynamicIslandExpandedRegion(.leading) {
                    Image(systemName: "drop.fill")
                        .foregroundStyle(.cyan)
                        .font(.title2)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(context.state.percentText)
                        .font(.system(.title2, design: .rounded, weight: .bold))
                        .foregroundStyle(.cyan)
                }
                DynamicIslandExpandedRegion(.center) {
                    Text("\(context.state.currentML) / \(context.state.goalML) mL")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    // Quick-add buttons in expanded Dynamic Island
                    HStack(spacing: 16) {
                        Button(intent: QuickAddWaterIntent(amount: 150)) {
                            Text("150 mL")
                                .font(.caption2.bold())
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(.blue.opacity(0.2), in: Capsule())
                        }
                        .buttonStyle(.plain)

                        Button(intent: QuickAddWaterIntent(amount: 250)) {
                            Text("250 mL")
                                .font(.caption2.bold())
                                .foregroundStyle(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(.blue, in: Capsule())
                        }
                        .buttonStyle(.plain)

                        Button(intent: QuickAddWaterIntent(amount: 500)) {
                            Text("500 mL")
                                .font(.caption2.bold())
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(.blue.opacity(0.2), in: Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
            } compactLeading: {
                Image(systemName: "drop.fill")
                    .foregroundStyle(.cyan)
            } compactTrailing: {
                Text(context.state.percentText)
                    .font(.system(.caption, design: .rounded, weight: .bold))
                    .foregroundStyle(.cyan)
            } minimal: {
                Image(systemName: "drop.fill")
                    .foregroundStyle(.cyan)
            }
        }
    }

    private func lockScreenView(state: HydrationActivityAttributes.ContentState) -> some View {
        HStack(spacing: 16) {
            // Progress ring
            ZStack {
                Circle()
                    .stroke(Color.cyan.opacity(0.2), lineWidth: 6)

                Circle()
                    .trim(from: 0, to: state.progress)
                    .stroke(
                        LinearGradient(colors: [.cyan, .blue], startPoint: .topLeading, endPoint: .bottomTrailing),
                        style: StrokeStyle(lineWidth: 6, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))

                Text(state.percentText)
                    .font(.system(.caption, design: .rounded, weight: .bold))
                    .foregroundStyle(.cyan)
            }
            .frame(width: 50, height: 50)

            VStack(alignment: .leading, spacing: 4) {
                Text(state.goalReached ? String(localized: "Goal Reached!") : String(localized: "Stay Hydrated"))
                    .font(.subheadline.bold())

                Text("\(state.currentML) / \(state.goalML) mL")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // Quick-add from lock screen
            Button(intent: QuickAddWaterIntent(amount: 250)) {
                Image(systemName: "plus.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.cyan)
            }
            .buttonStyle(.plain)
        }
        .padding()
    }
}
