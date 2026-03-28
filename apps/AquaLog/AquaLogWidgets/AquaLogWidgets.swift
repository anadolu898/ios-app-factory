import WidgetKit
import SwiftUI

// MARK: - Widget Entry

struct HydrationEntry: TimelineEntry {
    let date: Date
    let currentML: Int
    let goalML: Int

    var progress: Double {
        guard goalML > 0 else { return 0 }
        return min(Double(currentML) / Double(goalML), 1.0)
    }

    var percentText: String {
        "\(Int((progress * 100).rounded()))%"
    }

    static var placeholder: HydrationEntry {
        HydrationEntry(date: .now, currentML: 1250, goalML: 2500)
    }
}

// MARK: - Timeline Provider

struct HydrationTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> HydrationEntry {
        .placeholder
    }

    func getSnapshot(in context: Context, completion: @escaping (HydrationEntry) -> Void) {
        let entry = loadCurrentEntry()
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<HydrationEntry>) -> Void) {
        let entry = loadCurrentEntry()
        // Refresh every 15 minutes
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: .now) ?? .now
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }

    private func loadCurrentEntry() -> HydrationEntry {
        let defaults = UserDefaults(suiteName: "group.com.anadolu898.aqualog")
        let currentML = defaults?.integer(forKey: "todayIntakeML") ?? 0
        let goalML = defaults?.integer(forKey: "dailyGoalML") ?? 2500
        return HydrationEntry(date: .now, currentML: currentML, goalML: goalML)
    }
}

// MARK: - Small Widget View (Interactive)

struct SmallWidgetView: View {
    let entry: HydrationEntry

    var body: some View {
        ZStack {
            // Progress ring
            Circle()
                .stroke(Color.cyan.opacity(0.2), lineWidth: 8)

            Circle()
                .trim(from: 0, to: entry.progress)
                .stroke(
                    LinearGradient(colors: [.cyan, .blue], startPoint: .topLeading, endPoint: .bottomTrailing),
                    style: StrokeStyle(lineWidth: 8, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))

            VStack(spacing: 2) {
                Text(entry.percentText)
                    .font(.system(.title3, design: .rounded, weight: .bold))
                    .foregroundStyle(.blue)

                // Interactive: tap to add 250mL without opening app
                Button(intent: QuickAddWaterIntent(amount: 250)) {
                    Label("250", systemImage: "plus")
                        .font(.system(.caption2, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Capsule().fill(.blue))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(10)
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

// MARK: - Medium Widget View (Interactive)

struct MediumWidgetView: View {
    let entry: HydrationEntry

    var body: some View {
        HStack(spacing: 12) {
            // Progress ring
            ZStack {
                Circle()
                    .stroke(Color.cyan.opacity(0.2), lineWidth: 8)

                Circle()
                    .trim(from: 0, to: entry.progress)
                    .stroke(
                        LinearGradient(colors: [.cyan, .blue], startPoint: .topLeading, endPoint: .bottomTrailing),
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))

                Text(entry.percentText)
                    .font(.system(.title3, design: .rounded, weight: .bold))
                    .foregroundStyle(.blue)
            }
            .frame(width: 70, height: 70)

            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text("\(entry.currentML.volumeString(unitSystem: "metric")) / \(entry.goalML.volumeString(unitSystem: "metric"))")
                    .font(.subheadline.weight(.medium))

                if entry.progress >= 1.0 {
                    Label(String(localized: "Goal reached!"), systemImage: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundStyle(.green)
                } else {
                    let remaining = max(0, entry.goalML - entry.currentML)
                    Text(String(localized: "\(remaining.volumeString(unitSystem: "metric")) to go"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            // Interactive quick-add buttons — NO app launch
            VStack(spacing: 6) {
                Button(intent: QuickAddWaterIntent(amount: 150)) {
                    Text("150")
                        .font(.caption2.bold())
                        .frame(width: 44, height: 28)
                        .background(Color.blue.opacity(0.15), in: RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)

                Button(intent: QuickAddWaterIntent(amount: 250)) {
                    Text("250")
                        .font(.caption2.bold())
                        .frame(width: 44, height: 28)
                        .background(Color.blue, in: RoundedRectangle(cornerRadius: 8))
                        .foregroundStyle(.white)
                }
                .buttonStyle(.plain)

                Button(intent: QuickAddWaterIntent(amount: 500)) {
                    Text("500")
                        .font(.caption2.bold())
                        .frame(width: 44, height: 28)
                        .background(Color.blue.opacity(0.15), in: RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
            }
        }
        .padding()
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

// MARK: - Lock Screen Widget View

struct LockScreenWidgetView: View {
    let entry: HydrationEntry

    var body: some View {
        Gauge(value: entry.progress) {
            Image(systemName: "drop.fill")
        } currentValueLabel: {
            Text(entry.percentText)
                .font(.system(.caption2, design: .rounded, weight: .bold))
        }
        .gaugeStyle(.accessoryCircular)
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

// MARK: - Widget Definitions

struct HydrationSmallWidget: Widget {
    let kind = "HydrationSmallWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: HydrationTimelineProvider()) { entry in
            SmallWidgetView(entry: entry)
        }
        .configurationDisplayName(String(localized: "Hydration"))
        .description(String(localized: "Track your daily water intake"))
        .supportedFamilies([.systemSmall])
    }
}

struct HydrationMediumWidget: Widget {
    let kind = "HydrationMediumWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: HydrationTimelineProvider()) { entry in
            MediumWidgetView(entry: entry)
        }
        .configurationDisplayName(String(localized: "Hydration Details"))
        .description(String(localized: "Track your daily water intake with details"))
        .supportedFamilies([.systemMedium])
    }
}

struct HydrationLockScreenWidget: Widget {
    let kind = "HydrationLockScreenWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: HydrationTimelineProvider()) { entry in
            LockScreenWidgetView(entry: entry)
        }
        .configurationDisplayName(String(localized: "Hydration"))
        .description(String(localized: "See your hydration progress at a glance"))
        .supportedFamilies([.accessoryCircular])
    }
}

// MARK: - Widget Bundle

@main
struct AquaLogWidgetBundle: WidgetBundle {
    var body: some Widget {
        HydrationSmallWidget()
        HydrationMediumWidget()
        HydrationLockScreenWidget()
        if #available(iOS 18.0, *) {
            AquaLogControlWidget()
        }
        HydrationLiveActivity()
    }
}

// MARK: - Int Extension for Widget

extension Int {
    func volumeString(unitSystem: String = "metric") -> String {
        if unitSystem == "imperial" {
            let oz = Double(self) / 29.5735
            if oz >= 10 {
                return String(format: "%.0f oz", oz)
            }
            return String(format: "%.1f oz", oz)
        }
        if self >= 1000 {
            return String(format: "%.1f L", Double(self) / 1000.0)
        }
        return "\(self) mL"
    }
}
