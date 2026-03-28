import SwiftUI
import SwiftData
import Charts

struct BodyReportView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var settingsQuery: [UserSettings]
    @Query(sort: \WaterLog.timestamp, order: .reverse) private var allLogs: [WaterLog]

    private var settings: UserSettings? { settingsQuery.first }

    private var last7DaysData: [(date: Date, totalML: Int, goalML: Int)] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        let goal = settings?.dailyGoalML ?? 2500

        return (0..<7).reversed().map { offset in
            let date = calendar.date(byAdding: .day, value: -offset, to: today) ?? today
            let dayLogs = allLogs.filter { calendar.isDate($0.timestamp, inSameDayAs: date) }
            let total = dayLogs.reduce(0) { $0 + $1.amount }
            return (date: date, totalML: total, goalML: goal)
        }
    }

    private var weekCaffeine: Double {
        let calendar = Calendar.current
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: .now) ?? .now
        return allLogs
            .filter { $0.timestamp >= weekAgo }
            .reduce(0.0) { $0 + CaffeineInfo.caffeinePerServing(beverage: $1.beverageType, amountML: $1.amount) }
    }

    private var weekAlcoholDrinks: Double {
        let calendar = Calendar.current
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: .now) ?? .now
        return allLogs
            .filter { $0.timestamp >= weekAgo }
            .reduce(0.0) { total, log in
                let profile = NutrientDatabase.profile(for: log.beverageType)
                guard let p = profile, p.alcoholABV > 0 else { return total }
                let grams = Double(log.amount) * p.alcoholABV * 0.789
                return total + (grams / 14.0) // standard drinks
            }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    weekChartSection
                    statsGrid
                    insightsSection
                }
                .padding()
            }
            .navigationTitle(String(localized: "Weekly Report"))
        }
    }

    // MARK: - Week Chart

    private var weekChartSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(String(localized: "This Week"))
                .font(.headline)

            Chart(last7DaysData, id: \.date) { day in
                BarMark(
                    x: .value("Day", day.date, unit: .day),
                    y: .value("mL", day.totalML)
                )
                .foregroundStyle(
                    day.totalML >= day.goalML
                        ? Color.blue
                        : Color.blue.opacity(0.4)
                )
                .cornerRadius(4)

                RuleMark(y: .value("Goal", day.goalML))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 3]))
                    .foregroundStyle(.secondary.opacity(0.4))
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .day)) { _ in
                    AxisValueLabel(format: .dateTime.weekday(.abbreviated))
                }
            }
            .frame(height: 180)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.regularMaterial)
        )
    }

    // MARK: - Stats Grid

    private var statsGrid: some View {
        let daysOnGoal = last7DaysData.filter { $0.totalML >= $0.goalML }.count
        let totalIntake = last7DaysData.reduce(0) { $0 + $1.totalML }
        let avgDaily = totalIntake / max(last7DaysData.count, 1)

        return LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 12) {
            statCard(value: "\(daysOnGoal)/7", label: String(localized: "Days on Goal"), icon: "checkmark.circle.fill", color: .green)
            statCard(value: avgDaily.volumeString(unitSystem: settings?.unitSystem ?? "metric"), label: String(localized: "Daily Avg"), icon: "drop.fill", color: .blue)
            statCard(value: "\(Int(weekCaffeine))", label: String(localized: "mg Caffeine"), icon: "mug.fill", color: .brown)

            statCard(value: String(format: "%.1f", weekAlcoholDrinks), label: String(localized: "Drinks"), icon: "wineglass.fill", color: .purple)
            statCard(value: totalIntake.volumeString(unitSystem: settings?.unitSystem ?? "metric"), label: String(localized: "Total"), icon: "chart.bar.fill", color: .cyan)
            statCard(value: "\(allLogs.filter { $0.timestamp >= Calendar.current.date(byAdding: .day, value: -7, to: .now) ?? .now }.count)", label: String(localized: "Entries"), icon: "list.bullet", color: .orange)
        }
    }

    private func statCard(value: String, label: String, icon: String, color: Color) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(color)
            Text(value)
                .font(.subheadline.bold().monospacedDigit())
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.regularMaterial)
        )
        .accessibilityElement(children: .combine)
    }

    // MARK: - Insights

    private var insightsSection: some View {
        let report = HealthInsightsGenerator.shared.generateReport(
            currentStreak: settings?.currentStreak ?? 0,
            longestStreak: settings?.longestStreak ?? 0,
            weekLogs: last7DaysData,
            weekCaffeineMG: weekCaffeine,
            weekAlcoholDrinks: weekAlcoholDrinks
        )

        return VStack(alignment: .leading, spacing: 12) {
            Text(String(localized: "Insights"))
                .font(.headline)

            if let summary = report.weekSummary {
                ForEach(summary.insights, id: \.self) { insight in
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "lightbulb.fill")
                            .foregroundStyle(.yellow)
                            .font(.caption)
                            .padding(.top, 2)
                        Text(insight)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.yellow.opacity(0.06))
                    )
                }
            }
        }
    }
}

#Preview {
    BodyReportView()
        .modelContainer(for: [WaterLog.self, UserSettings.self], inMemory: true)
}
