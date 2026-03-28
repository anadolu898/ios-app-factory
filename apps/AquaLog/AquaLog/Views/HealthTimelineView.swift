import SwiftUI
import SwiftData

struct HealthTimelineView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var settingsQuery: [UserSettings]
    @Query(sort: \WaterLog.timestamp, order: .reverse) private var allLogs: [WaterLog]

    private var settings: UserSettings? { settingsQuery.first }
    private var currentStreak: Int { settings?.currentStreak ?? 0 }
    private var longestStreak: Int { settings?.longestStreak ?? 0 }

    @State private var report: HealthInsightsGenerator.HealthReport?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    scoreCard
                    streakCard
                    quickLinksSection
                    timelineSection
                }
                .padding()
            }
            .navigationTitle(String(localized: "Health Timeline"))
            .onAppear { loadReport() }
        }
    }

    // MARK: - Quick Links

    private var quickLinksSection: some View {
        VStack(spacing: 10) {
            HStack(spacing: 12) {
                NavigationLink {
                    CaffeineChartView()
                } label: {
                    quickLinkButton(icon: "mug.fill", title: String(localized: "Caffeine"), color: .brown)
                }

                NavigationLink {
                    AlcoholImpactView()
                } label: {
                    quickLinkButton(icon: "wineglass.fill", title: String(localized: "Alcohol"), color: .purple)
                }
            }

            NavigationLink {
                BodyReportView()
            } label: {
                quickLinkButton(icon: "chart.bar.doc.horizontal", title: String(localized: "Weekly Report"), color: .blue)
            }
        }
    }

    private func quickLinkButton(icon: String, title: String, color: Color) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(color)
            Text(title)
                .font(.subheadline.weight(.medium))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(color.opacity(0.1))
        )
        .foregroundStyle(.primary)
    }

    // MARK: - Score Card

    private var scoreCard: some View {
        VStack(spacing: 12) {
            Text(String(localized: "Hydration Score"))
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            Text("\(report?.overallScore ?? 0)")
                .font(.system(size: 64, weight: .bold, design: .rounded))
                .foregroundStyle(scoreColor)
                .contentTransition(.numericText())

            Text(scoreLabel)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(scoreColor)

            if let summary = report?.weekSummary {
                VStack(spacing: 6) {
                    ForEach(summary.insights, id: \.self) { insight in
                        Text(insight)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding(.top, 4)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.regularMaterial)
        )
        .accessibilityElement(children: .combine)
    }

    private var scoreColor: Color {
        let score = report?.overallScore ?? 0
        switch score {
        case 80...: return .green
        case 60..<80: return .blue
        case 40..<60: return .orange
        default: return .red
        }
    }

    private var scoreLabel: String {
        let score = report?.overallScore ?? 0
        switch score {
        case 90...: return String(localized: "Excellent")
        case 75..<90: return String(localized: "Great")
        case 60..<75: return String(localized: "Good")
        case 40..<60: return String(localized: "Needs Improvement")
        default: return String(localized: "Let's Work on This")
        }
    }

    // MARK: - Streak Card

    private var streakCard: some View {
        HStack(spacing: 16) {
            VStack(spacing: 4) {
                Image(systemName: "flame.fill")
                    .font(.title2)
                    .foregroundStyle(.orange)
                Text("\(currentStreak)")
                    .font(.title.bold().monospacedDigit())
                Text(String(localized: "Current"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)

            Divider().frame(height: 50)

            VStack(spacing: 4) {
                Image(systemName: "trophy.fill")
                    .font(.title2)
                    .foregroundStyle(.yellow)
                Text("\(longestStreak)")
                    .font(.title.bold().monospacedDigit())
                Text(String(localized: "Best"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)

            Divider().frame(height: 50)

            VStack(spacing: 4) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.blue)
                Text("\(report?.daysToNextMilestone ?? 0)")
                    .font(.title.bold().monospacedDigit())
                Text(String(localized: "To Next"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.regularMaterial)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            String(localized: "Streak: \(currentStreak) days current, \(longestStreak) best")
        )
    }

    // MARK: - Timeline

    private var timelineSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(String(localized: "Your Health Journey"))
                .font(.headline)
                .padding(.bottom, 16)

            let allMilestones = HealthInsightsGenerator.HealthInsight.Milestone.allCases
            ForEach(Array(allMilestones.enumerated()), id: \.element.rawValue) { index, milestone in
                let insights = report?.unlockedInsights.filter { $0.milestone == milestone } ?? []
                let isUnlocked = currentStreak >= milestone.rawValue
                let isLast = index == allMilestones.count - 1

                timelineNode(
                    milestone: milestone,
                    insights: insights,
                    isUnlocked: isUnlocked,
                    isLast: isLast
                )
            }
        }
    }

    private func timelineNode(
        milestone: HealthInsightsGenerator.HealthInsight.Milestone,
        insights: [HealthInsightsGenerator.HealthInsight],
        isUnlocked: Bool,
        isLast: Bool
    ) -> some View {
        HStack(alignment: .top, spacing: 16) {
            // Timeline line + node
            VStack(spacing: 0) {
                Circle()
                    .fill(isUnlocked ? Color.blue : Color(.systemGray4))
                    .frame(width: 24, height: 24)
                    .overlay {
                        if isUnlocked {
                            Image(systemName: "checkmark")
                                .font(.caption2.bold())
                                .foregroundStyle(.white)
                        }
                    }

                if !isLast {
                    Rectangle()
                        .fill(isUnlocked ? Color.blue.opacity(0.3) : Color(.systemGray5))
                        .frame(width: 2)
                        .frame(minHeight: 60)
                }
            }

            // Content
            VStack(alignment: .leading, spacing: 8) {
                Text(String(localized: "Day \(milestone.rawValue)"))
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(isUnlocked ? .primary : .secondary)

                if isUnlocked {
                    ForEach(insights) { insight in
                        HStack(alignment: .top, spacing: 10) {
                            Image(systemName: insight.icon)
                                .font(.body)
                                .foregroundStyle(.blue)
                                .frame(width: 24)

                            VStack(alignment: .leading, spacing: 4) {
                                Text(insight.title)
                                    .font(.subheadline.weight(.semibold))
                                Text(insight.description)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text(insight.citation)
                                    .font(.caption2)
                                    .foregroundStyle(.tertiary)
                                    .italic()
                            }
                        }
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.blue.opacity(0.06))
                        )
                    }
                } else if insights.isEmpty {
                    HStack(spacing: 8) {
                        Image(systemName: "lock.fill")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(String(localized: "\(milestone.rawValue - currentStreak) more days to unlock"))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.systemGray6))
                    )
                } else {
                    ForEach(insights) { insight in
                        HStack(spacing: 8) {
                            Image(systemName: insight.isPremium ? "lock.fill" : "lock.open.fill")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(insight.title)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(.systemGray6))
                        )
                    }
                }
            }
            .padding(.bottom, isLast ? 0 : 8)
        }
    }

    // MARK: - Data Loading

    private func loadReport() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        let goal = settings?.dailyGoalML ?? 2500

        // Build last 7 days of data from actual logs
        let weekLogs: [(date: Date, totalML: Int, goalML: Int)] = (0..<7).reversed().map { offset in
            let date = calendar.date(byAdding: .day, value: -offset, to: today) ?? today
            let dayLogs = allLogs.filter { calendar.isDate($0.timestamp, inSameDayAs: date) }
            let total = dayLogs.reduce(0) { $0 + $1.amount }
            return (date: date, totalML: total, goalML: goal)
        }

        // Calculate week caffeine and alcohol
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: .now) ?? .now
        let weekCaffeine = allLogs.filter { $0.timestamp >= weekAgo }.reduce(0.0) {
            $0 + CaffeineInfo.caffeinePerServing(beverage: $1.beverageType, amountML: $1.amount)
        }
        let weekAlcohol = allLogs.filter { $0.timestamp >= weekAgo }.reduce(0.0) { total, log in
            guard let p = NutrientDatabase.profile(for: log.beverageType), p.alcoholABV > 0 else { return total }
            return total + (Double(log.amount) * p.alcoholABV * 0.789 / 14.0)
        }

        report = HealthInsightsGenerator.shared.generateReport(
            currentStreak: currentStreak,
            longestStreak: longestStreak,
            weekLogs: weekLogs,
            weekCaffeineMG: weekCaffeine,
            weekAlcoholDrinks: weekAlcohol
        )
    }
}

#Preview {
    HealthTimelineView()
        .modelContainer(for: [WaterLog.self, UserSettings.self], inMemory: true)
}
