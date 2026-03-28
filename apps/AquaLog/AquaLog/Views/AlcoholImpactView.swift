import SwiftUI
import SwiftData

struct AlcoholImpactView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var settingsQuery: [UserSettings]
    @Query(sort: \WaterLog.timestamp, order: .reverse) private var allLogs: [WaterLog]

    private var settings: UserSettings? { settingsQuery.first }

    private var todayAlcoholLogs: [WaterLog] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: .now)
        return allLogs.filter { log in
            log.timestamp >= startOfDay &&
            NutrientDatabase.profile(for: log.beverageType)?.alcoholABV ?? 0 > 0
        }
    }

    private var todayAlcoholGrams: Double {
        todayAlcoholLogs.reduce(0.0) { total, log in
            guard let profile = NutrientDatabase.profile(for: log.beverageType) else { return total }
            return total + Double(log.amount) * profile.alcoholABV * 0.789
        }
    }

    private var impact: AlcoholCalculator.AlcoholImpact {
        AlcoholCalculator.shared.calculateImpact(
            beverageId: todayAlcoholLogs.last?.beverageType ?? "beer",
            volumeML: todayAlcoholLogs.last?.amount ?? 0,
            weightKg: settings?.weightKg ?? 70,
            gender: HydrationCalculator.Gender(rawValue: settings?.gender ?? "other") ?? .other,
            existingAlcoholToday: max(0, todayAlcoholGrams - Double(todayAlcoholLogs.last?.amount ?? 0) * (NutrientDatabase.profile(for: todayAlcoholLogs.last?.beverageType ?? "")?.alcoholABV ?? 0) * 0.789)
        )
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    standardDrinksCard
                    if todayAlcoholGrams > 0 {
                        dehydrationCard
                        recoveryCard
                        recommendationsSection
                    } else {
                        emptyState
                    }
                    infoSection
                }
                .padding()
            }
            .navigationTitle(String(localized: "Alcohol Impact"))
        }
    }

    // MARK: - Standard Drinks Card

    private var standardDrinksCard: some View {
        VStack(spacing: 12) {
            Text(String(localized: "Today's Drinks"))
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            Text(String(format: "%.1f", impact.standardDrinks))
                .font(.system(size: 56, weight: .bold, design: .rounded))
                .foregroundStyle(riskColor)
                .contentTransition(.numericText())

            Text(String(localized: "standard drinks"))
                .font(.subheadline)
                .foregroundStyle(.secondary)

            // Risk level badge
            Text(riskLabel)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(Capsule().fill(riskColor))

            // Daily limit context
            let limit = (settings?.gender == "male") ? 2 : 1
            Text(String(localized: "Recommended limit: \(limit) drink\(limit > 1 ? "s" : "")/day"))
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.regularMaterial)
        )
    }

    // MARK: - Dehydration Card

    private var dehydrationCard: some View {
        HStack(spacing: 16) {
            VStack(spacing: 4) {
                Image(systemName: "drop.triangle.fill")
                    .font(.title2)
                    .foregroundStyle(.red)
                Text("\(impact.dehydrationML)")
                    .font(.title2.bold().monospacedDigit())
                Text(String(localized: "mL lost"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)

            Divider().frame(height: 50)

            VStack(spacing: 4) {
                Image(systemName: "drop.fill")
                    .font(.title2)
                    .foregroundStyle(.blue)
                Text("\(impact.dehydrationML)")
                    .font(.title2.bold().monospacedDigit())
                Text(String(localized: "mL to drink"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)

            Divider().frame(height: 50)

            VStack(spacing: 4) {
                Image(systemName: "clock.fill")
                    .font(.title2)
                    .foregroundStyle(.orange)
                Text(String(format: "%.1f", impact.recoveryTimeHours))
                    .font(.title2.bold().monospacedDigit())
                Text(String(localized: "hrs to process"))
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
    }

    // MARK: - Recovery Card

    private var recoveryCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "liver.fill")
                    .foregroundStyle(.brown)
                Text(String(localized: "Liver Processing"))
                    .font(.subheadline.weight(.semibold))
            }

            Text(String(localized: "Your liver processes ~7g of alcohol per hour. Based on today's intake (\(Int(todayAlcoholGrams))g), your body needs approximately \(String(format: "%.1f", impact.recoveryTimeHours)) hours to fully metabolize the alcohol."))
                .font(.caption)
                .foregroundStyle(.secondary)

            if impact.recoveryTimeHours > 0 {
                let clearTime = Date.now.addingTimeInterval(impact.recoveryTimeHours * 3600)
                HStack {
                    Image(systemName: "checkmark.circle")
                        .foregroundStyle(.green)
                    Text(String(localized: "Estimated clear by \(clearTime.formatted(date: .omitted, time: .shortened))"))
                        .font(.caption.weight(.medium))
                }
                .padding(.top, 4)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.brown.opacity(0.08))
        )
    }

    // MARK: - Recommendations

    private var recommendationsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(String(localized: "Recommendations"))
                .font(.headline)

            ForEach(impact.recommendations, id: \.self) { rec in
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "lightbulb.fill")
                        .foregroundStyle(.yellow)
                        .font(.caption)
                        .padding(.top, 2)
                    Text(rec)
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

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "wineglass")
                .font(.system(size: 40))
                .foregroundStyle(.tertiary)
            Text(String(localized: "No alcohol logged today"))
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text(String(localized: "When you log beer, wine, or spirits, you'll see their dehydration impact, BAC estimate, and recovery time here."))
                .font(.caption)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 30)
    }

    // MARK: - Info Section

    private var infoSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(String(localized: "How Alcohol Dehydrates"))
                .font(.subheadline.weight(.semibold))

            Text(String(localized: "Alcohol suppresses ADH (antidiuretic hormone), causing your kidneys to produce more urine. Each gram of alcohol results in roughly 10 mL of extra fluid loss. This is why you need to drink extra water when consuming alcoholic beverages."))
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(String(localized: "Source: Hobson & Maughan, 2010; NIAAA guidelines"))
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .italic()
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(.systemGray6))
        )
    }

    // MARK: - Helpers

    private var riskColor: Color {
        switch impact.riskLevel {
        case .none: .green
        case .low: .blue
        case .moderate: .orange
        case .high: .red
        }
    }

    private var riskLabel: String {
        switch impact.riskLevel {
        case .none: String(localized: "No Risk")
        case .low: String(localized: "Low Risk")
        case .moderate: String(localized: "Moderate Risk")
        case .high: String(localized: "High Risk")
        }
    }
}

#Preview {
    AlcoholImpactView()
        .modelContainer(for: [WaterLog.self, UserSettings.self], inMemory: true)
}
