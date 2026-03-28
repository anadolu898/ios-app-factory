import SwiftUI
import SwiftData
import Charts

struct CaffeineChartView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var settingsQuery: [UserSettings]

    @State private var caffeineState: CaffeineTracker.CaffeineState?
    @State private var decayCurve: [(date: Date, mg: Double)] = []
    @State private var todayDrinks: [(caffeineeMG: Double, timestamp: Date)] = []

    private var settings: UserSettings? { settingsQuery.first }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    currentLevelCard
                    decayChartSection
                    sleepImpactCard
                    if let cutoff = caffeineState?.cutoffRecommendation {
                        cutoffCard(cutoff)
                    }
                }
                .padding()
            }
            .navigationTitle(String(localized: "Caffeine Tracker"))
            .onAppear { loadData() }
        }
    }

    // MARK: - Current Level

    private var currentLevelCard: some View {
        VStack(spacing: 8) {
            Text(String(localized: "In Your System Now"))
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            Text("\(Int(caffeineState?.currentMG ?? 0))")
                .font(.system(size: 56, weight: .bold, design: .rounded))
                .foregroundStyle(.brown)
                .contentTransition(.numericText())

            Text(String(localized: "mg caffeine"))
                .font(.subheadline)
                .foregroundStyle(.secondary)

            if let clearBy = caffeineState?.clearByTime {
                Text(String(localized: "Clears by \(clearBy.formatted(date: .omitted, time: .shortened))"))
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }

            HStack(spacing: 24) {
                VStack(spacing: 2) {
                    Text("\(Int(caffeineState?.totalConsumedMG ?? 0))")
                        .font(.title3.bold().monospacedDigit())
                    Text(String(localized: "Total today"))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                VStack(spacing: 2) {
                    Text("\(Int(CaffeineTracker.dailyLimitMG))")
                        .font(.title3.bold().monospacedDigit())
                        .foregroundStyle(.tertiary)
                    Text(String(localized: "FDA limit"))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.regularMaterial)
        )
        .accessibilityElement(children: .combine)
    }

    // MARK: - Decay Chart

    private var decayChartSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(String(localized: "Caffeine Over Time"))
                .font(.headline)

            if decayCurve.isEmpty {
                Text(String(localized: "No caffeine consumed today"))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 180)
            } else {
                Chart {
                    ForEach(decayCurve, id: \.date) { point in
                        AreaMark(
                            x: .value("Time", point.date),
                            y: .value("mg", point.mg)
                        )
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.brown.opacity(0.3), .brown.opacity(0.05)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )

                        LineMark(
                            x: .value("Time", point.date),
                            y: .value("mg", point.mg)
                        )
                        .foregroundStyle(.brown)
                        .lineStyle(StrokeStyle(lineWidth: 2))
                    }

                    // "Now" marker
                    RuleMark(x: .value("Now", Date.now))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 3]))
                        .foregroundStyle(.blue.opacity(0.5))
                        .annotation(position: .top, alignment: .center) {
                            Text(String(localized: "Now"))
                                .font(.caption2)
                                .foregroundStyle(.blue)
                        }

                    // FDA limit line
                    RuleMark(y: .value("Limit", CaffeineTracker.dailyLimitMG))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [3, 3]))
                        .foregroundStyle(.red.opacity(0.4))
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: .hour, count: 3)) { value in
                        AxisValueLabel(format: .dateTime.hour(.defaultDigits(amPM: .abbreviated)))
                    }
                }
                .chartYAxis {
                    AxisMarks { value in
                        AxisGridLine()
                        AxisValueLabel {
                            if let intValue = value.as(Int.self) {
                                Text("\(intValue)")
                                    .font(.caption2)
                            }
                        }
                    }
                }
                .frame(height: 200)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.regularMaterial)
        )
    }

    // MARK: - Sleep Impact

    private var sleepImpactCard: some View {
        HStack(spacing: 14) {
            Image(systemName: sleepIcon)
                .font(.title2)
                .foregroundStyle(sleepColor)
                .frame(width: 40)

            VStack(alignment: .leading, spacing: 4) {
                Text(String(localized: "Sleep Impact"))
                    .font(.subheadline.weight(.semibold))
                Text(caffeineState?.sleepImpact.displayName ?? String(localized: "No impact"))
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if let bedtimeMG = caffeineState?.atBedtimeMG, bedtimeMG > 5 {
                    Text(String(localized: "~\(Int(bedtimeMG)) mg at bedtime"))
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }

            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(.regularMaterial)
        )
        .accessibilityElement(children: .combine)
    }

    private var sleepIcon: String {
        guard let impact = caffeineState?.sleepImpact else { return "moon.zzz.fill" }
        switch impact {
        case .none: return "moon.zzz.fill"
        case .mild: return "moon.fill"
        case .moderate: return "moon.haze.fill"
        case .severe: return "exclamationmark.triangle.fill"
        }
    }

    private var sleepColor: Color {
        guard let impact = caffeineState?.sleepImpact else { return .green }
        switch impact {
        case .none: return .green
        case .mild: return .yellow
        case .moderate: return .orange
        case .severe: return .red
        }
    }

    private func cutoffCard(_ message: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "clock.badge.exclamationmark")
                .foregroundStyle(.orange)
            Text(message)
                .font(.caption)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.orange.opacity(0.1))
        )
    }

    // MARK: - Data Loading

    private func loadData() {
        guard let modelContext = Optional(ModelContext(modelContext.container)) else { return }

        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: .now)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? .now

        let predicate = #Predicate<WaterLog> { log in
            log.timestamp >= startOfDay && log.timestamp < endOfDay
        }

        let descriptor = FetchDescriptor<WaterLog>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.timestamp)]
        )

        guard let logs = try? modelContext.fetch(descriptor) else { return }

        todayDrinks = logs.compactMap { log in
            let profile = NutrientDatabase.profile(for: log.beverageType)
            let caffeine = (profile?.caffeineMgPer250mL ?? CaffeineInfo.caffeinePerServing(beverage: log.beverageType, amountML: log.amount))
            let mg = profile != nil ? caffeine * (Double(log.amount) / 250.0) : caffeine
            guard mg > 0 else { return nil }
            return (caffeineeMG: mg, timestamp: log.timestamp)
        }

        let bedtimeHour = settings?.bedtimeHour ?? 23
        let bedtimeMinute = settings?.bedtimeMinute ?? 0

        caffeineState = CaffeineTracker.shared.calculateState(
            drinks: todayDrinks,
            bedtimeHour: bedtimeHour,
            bedtimeMinute: bedtimeMinute
        )

        decayCurve = CaffeineTracker.shared.decayCurve(drinks: todayDrinks)
    }
}

#Preview {
    CaffeineChartView()
        .modelContainer(for: [WaterLog.self, UserSettings.self], inMemory: true)
}
