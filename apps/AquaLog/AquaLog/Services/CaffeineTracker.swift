import Foundation

/// Tracks caffeine metabolism using pharmacokinetic half-life model
/// Source: FDA, Fredholm et al. 1999, Institute for Scientific Information on Coffee
@MainActor
final class CaffeineTracker {
    static let shared = CaffeineTracker()
    private init() {}

    // MARK: - Constants

    /// Average caffeine half-life in hours (FDA: 4-6 hours, we use 5)
    static let halfLifeHours: Double = 5.0

    /// FDA daily limit in mg
    static let dailyLimitMG: Double = 400.0

    /// Threshold where caffeine impacts sleep quality (mg still in system at bedtime)
    static let sleepImpactThresholdMG: Double = 100.0

    /// Minimum mg to be considered "in your system"
    static let negligibleMG: Double = 5.0

    // MARK: - Current Caffeine Level

    struct CaffeineState {
        let currentMG: Double             // Right now
        let peakMG: Double                // Highest point today
        let totalConsumedMG: Double       // Total consumed today
        let clearByTime: Date?            // When it drops below negligible
        let atBedtimeMG: Double           // Estimated level at user's bedtime
        let sleepImpact: SleepImpact
        let cutoffRecommendation: String? // "Stop caffeine by 2 PM for good sleep"

        enum SleepImpact: String {
            case none       // <25mg at bedtime
            case mild       // 25-100mg at bedtime
            case moderate   // 100-200mg at bedtime
            case severe     // >200mg at bedtime

            var displayName: String {
                switch self {
                case .none: String(localized: "No impact")
                case .mild: String(localized: "Mild impact")
                case .moderate: String(localized: "May delay sleep")
                case .severe: String(localized: "Likely to disrupt sleep")
                }
            }
        }
    }

    /// Calculate current caffeine state from today's drink log
    func calculateState(
        drinks: [(caffeineeMG: Double, timestamp: Date)],
        bedtimeHour: Int = 23,
        bedtimeMinute: Int = 0
    ) -> CaffeineState {
        let now = Date.now

        // Calculate current caffeine level using exponential decay
        var currentMG: Double = 0
        var totalConsumed: Double = 0
        var peakMG: Double = 0

        for drink in drinks {
            let hoursSince = now.timeIntervalSince(drink.timestamp) / 3600.0
            guard hoursSince >= 0 else { continue }

            totalConsumed += drink.caffeineeMG

            // Exponential decay: C(t) = C₀ × (0.5)^(t/half-life)
            let remaining = drink.caffeineeMG * pow(0.5, hoursSince / Self.halfLifeHours)
            currentMG += remaining
        }

        // Calculate peak (simplified — assumes peak was at last caffeine intake)
        peakMG = max(currentMG, totalConsumed * 0.8)

        // Calculate when caffeine drops below negligible
        var clearByTime: Date?
        if currentMG > Self.negligibleMG {
            // Solve: negligible = currentMG × 0.5^(t/halflife)
            // t = halflife × log2(currentMG / negligible)
            let hoursToClean = Self.halfLifeHours * log2(currentMG / Self.negligibleMG)
            clearByTime = now.addingTimeInterval(hoursToClean * 3600)
        }

        // Calculate level at bedtime
        let calendar = Calendar.current
        var bedtimeComponents = calendar.dateComponents([.year, .month, .day], from: now)
        bedtimeComponents.hour = bedtimeHour
        bedtimeComponents.minute = bedtimeMinute
        var bedtime = calendar.date(from: bedtimeComponents) ?? now
        if bedtime < now {
            bedtime = calendar.date(byAdding: .day, value: 1, to: bedtime) ?? bedtime
        }

        let hoursToBedtime = bedtime.timeIntervalSince(now) / 3600.0
        let atBedtimeMG = currentMG * pow(0.5, hoursToBedtime / Self.halfLifeHours)

        // Sleep impact assessment
        let sleepImpact: CaffeineState.SleepImpact
        switch atBedtimeMG {
        case ..<25: sleepImpact = .none
        case ..<100: sleepImpact = .mild
        case ..<200: sleepImpact = .moderate
        default: sleepImpact = .severe
        }

        // Cutoff recommendation
        var cutoffRecommendation: String?
        if sleepImpact != .none && totalConsumed > 0 {
            // Calculate the latest time a 95mg coffee could be consumed
            // and still have <100mg at bedtime
            // 100 = 95 × 0.5^(t/5) → t = 5 × log2(95/100) ≈ -0.37 (already fine)
            // For 200mg caffeine: 100 = 200 × 0.5^(t/5) → t = 5 hours
            let safeHoursBeforeBed = Self.halfLifeHours * log2(200.0 / Self.sleepImpactThresholdMG)
            let cutoffTime = bedtime.addingTimeInterval(-safeHoursBeforeBed * 3600)
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            cutoffRecommendation = String(localized: "For better sleep, stop caffeine by \(formatter.string(from: cutoffTime))")
        }

        return CaffeineState(
            currentMG: currentMG,
            peakMG: peakMG,
            totalConsumedMG: totalConsumed,
            clearByTime: clearByTime,
            atBedtimeMG: atBedtimeMG,
            sleepImpact: sleepImpact,
            cutoffRecommendation: cutoffRecommendation
        )
    }

    /// Get caffeine decay data points for charting (one point per 30 min for 24 hours)
    func decayCurve(
        drinks: [(caffeineeMG: Double, timestamp: Date)]
    ) -> [(date: Date, mg: Double)] {
        let now = Date.now
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: now)

        var points: [(date: Date, mg: Double)] = []

        // Generate points every 30 minutes for 24 hours
        for halfHour in 0..<48 {
            let pointTime = startOfDay.addingTimeInterval(Double(halfHour) * 1800.0)
            var totalAtPoint: Double = 0

            for drink in drinks {
                let hoursSinceDrink = pointTime.timeIntervalSince(drink.timestamp) / 3600.0
                guard hoursSinceDrink >= 0 else { continue }
                totalAtPoint += drink.caffeineeMG * pow(0.5, hoursSinceDrink / Self.halfLifeHours)
            }

            points.append((date: pointTime, mg: totalAtPoint))
        }

        return points
    }
}
