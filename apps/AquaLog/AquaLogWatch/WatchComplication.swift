import WidgetKit
import SwiftUI

struct AquaLogWatchWidget: Widget {
    let kind = "AquaLogWatchWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: WatchTimelineProvider()) { entry in
            WatchComplicationView(entry: entry)
        }
        .configurationDisplayName("AquaLog")
        .description(String(localized: "Track your hydration progress"))
        .supportedFamilies([
            .accessoryCircular,
            .accessoryCorner,
            .accessoryInline,
            .accessoryRectangular
        ])
    }
}

struct WatchTimelineEntry: TimelineEntry {
    let date: Date
    let intakeML: Int
    let goalML: Int

    var progress: Double {
        guard goalML > 0 else { return 0 }
        return min(Double(intakeML) / Double(goalML), 1.0)
    }
}

struct WatchTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> WatchTimelineEntry {
        WatchTimelineEntry(date: .now, intakeML: 1250, goalML: 2500)
    }

    func getSnapshot(in context: Context, completion: @escaping (WatchTimelineEntry) -> Void) {
        completion(currentEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<WatchTimelineEntry>) -> Void) {
        let entry = currentEntry()
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: .now) ?? .now
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }

    private func currentEntry() -> WatchTimelineEntry {
        let defaults = UserDefaults(suiteName: "group.com.anadolu898.aqualog")
        let intake = defaults?.integer(forKey: "todayIntakeML") ?? 0
        let goal = defaults?.integer(forKey: "dailyGoalML") ?? 2500
        return WatchTimelineEntry(date: .now, intakeML: intake, goalML: goal)
    }
}

struct WatchComplicationView: View {
    let entry: WatchTimelineEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .accessoryCircular:
            circularView
        case .accessoryRectangular:
            rectangularView
        case .accessoryInline:
            inlineView
        case .accessoryCorner:
            cornerView
        default:
            circularView
        }
    }

    private var circularView: some View {
        Gauge(value: entry.progress) {
            Image(systemName: "drop.fill")
        } currentValueLabel: {
            Text("\(Int(entry.progress * 100))")
                .font(.system(.body, design: .rounded).bold())
        }
        .gaugeStyle(.accessoryCircular)
        .tint(.cyan)
    }

    private var rectangularView: some View {
        HStack(spacing: 8) {
            Gauge(value: entry.progress) {
                Image(systemName: "drop.fill")
            }
            .gaugeStyle(.accessoryCircular)
            .tint(.cyan)

            VStack(alignment: .leading) {
                Text("\(Int(entry.progress * 100))%")
                    .font(.headline.bold())
                Text("\(entry.intakeML.watchVolumeString) / \(entry.goalML.watchVolumeString)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var inlineView: some View {
        Text("💧 \(Int(entry.progress * 100))% — \(entry.intakeML.watchVolumeString)")
    }

    private var cornerView: some View {
        Text("\(Int(entry.progress * 100))%")
            .font(.system(.title3, design: .rounded).bold())
            .foregroundStyle(.cyan)
            .widgetLabel {
                Gauge(value: entry.progress) {
                    Text("Water")
                }
                .gaugeStyle(.accessoryLinear)
                .tint(.cyan)
            }
    }
}

// Reuse the extension from WatchDashboardView
// (Int.watchVolumeString is defined there)

#Preview(as: .accessoryCircular) {
    AquaLogWatchWidget()
} timeline: {
    WatchTimelineEntry(date: .now, intakeML: 1250, goalML: 2500)
    WatchTimelineEntry(date: .now, intakeML: 2500, goalML: 2500)
}
