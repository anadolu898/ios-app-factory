import SwiftUI
import SwiftData
import Charts

struct HistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \WaterLog.timestamp, order: .reverse) private var allLogs: [WaterLog]
    @Query private var settingsQuery: [UserSettings]

    private var dailyGoal: Int {
        settingsQuery.first?.dailyGoalML ?? 2500
    }

    private var groupedByDay: [(date: Date, logs: [WaterLog], total: Int)] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: allLogs) { log in
            calendar.startOfDay(for: log.timestamp)
        }

        return grouped
            .map { (date: $0.key, logs: $0.value, total: $0.value.reduce(0) { $0 + $1.amount }) }
            .sorted { $0.date > $1.date }
    }

    private var last7Days: [(date: Date, total: Int)] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)

        return (0..<7).reversed().map { offset in
            let date = calendar.date(byAdding: .day, value: -offset, to: today) ?? today
            let dayTotal = groupedByDay.first(where: { calendar.isDate($0.date, inSameDayAs: date) })?.total ?? 0
            return (date: date, total: dayTotal)
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if allLogs.isEmpty {
                    emptyState
                } else {
                    logList
                }
            }
            .navigationTitle(String(localized: "History"))
        }
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label(String(localized: "No History Yet"), systemImage: "calendar.badge.clock")
        } description: {
            Text(String(localized: "Your hydration history will appear here once you start logging drinks."))
        }
    }

    private var weeklyChart: some View {
        Section {
            VStack(alignment: .leading, spacing: 8) {
                Text(String(localized: "This Week"))
                    .font(.headline)

                Chart(last7Days, id: \.date) { day in
                    BarMark(
                        x: .value("Day", day.date, unit: .day),
                        y: .value("mL", day.total)
                    )
                    .foregroundStyle(
                        day.total >= dailyGoal
                            ? Color.accentColor
                            : Color.accentColor.opacity(0.5)
                    )
                    .cornerRadius(4)

                    RuleMark(y: .value("Goal", dailyGoal))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 3]))
                        .foregroundStyle(.secondary.opacity(0.5))
                        .annotation(position: .trailing, alignment: .trailing) {
                            Text(String(localized: "Goal"))
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day)) { value in
                        AxisValueLabel(format: .dateTime.weekday(.abbreviated))
                    }
                }
                .chartYAxis {
                    AxisMarks { value in
                        AxisGridLine()
                        AxisValueLabel {
                            if let intValue = value.as(Int.self) {
                                Text(intValue.volumeString(unitSystem: "metric"))
                                    .font(.caption2)
                            }
                        }
                    }
                }
                .frame(height: 180)
                .accessibilityLabel(String(localized: "Weekly hydration chart"))
            }
            .padding(.vertical, 8)
        }
    }

    private var logList: some View {
        List {
            weeklyChart

            ForEach(groupedByDay, id: \.date) { day in
                Section {
                    ForEach(day.logs, id: \.id) { log in
                        let beverage = Beverage(rawValue: log.beverageType.lowercased())
                        let beverageName = beverage?.displayName ?? log.beverageType
                        HStack {
                            Image(systemName: beverage?.icon ?? "drop.fill")
                                .foregroundStyle(Color.accentColor)

                            VStack(alignment: .leading) {
                                Text(beverageName)
                                    .font(.subheadline)
                                Text(log.timestamp, style: .time)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            Text(log.amount.volumeString(unitSystem: "metric"))
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(.secondary)
                        }
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel(
                            "\(beverageName), \(log.amount.volumeString(unitSystem: "metric")) at \(log.timestamp.formatted(date: .omitted, time: .shortened))"
                        )
                    }
                } header: {
                    HStack {
                        Text(day.date, style: .date)
                        Spacer()
                        Text(String(localized: "Total: \(day.total.volumeString(unitSystem: "metric"))"))
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Color.accentColor)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }
}

#Preview {
    HistoryView()
        .modelContainer(for: [WaterLog.self, UserSettings.self], inMemory: true)
}
