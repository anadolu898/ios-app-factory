import Foundation

/// Calculates alcohol's impact on hydration based on user profile
/// Sources: Hobson & Maughan 2010, Polhuis et al. 2017, NIAAA guidelines
@MainActor
final class AlcoholCalculator {
    static let shared = AlcoholCalculator()
    private init() {}

    // MARK: - BAC Estimation (Widmark Formula)

    /// Estimate Blood Alcohol Content
    /// Uses modified Widmark formula with body water distribution
    func estimateBAC(
        alcoholGrams: Double,
        weightKg: Double,
        gender: HydrationCalculator.Gender,
        hoursSinceDrink: Double
    ) -> Double {
        // Widmark factor: men ~0.68, women ~0.55 (body water ratio)
        let widmarkFactor: Double = switch gender {
        case .male: 0.68
        case .female: 0.55
        case .other: 0.615
        }

        let bac = (alcoholGrams / (weightKg * 1000.0 * widmarkFactor)) * 100.0
        // Metabolism rate: ~0.015% per hour
        let metabolized = hoursSinceDrink * 0.015
        return max(0, bac - metabolized)
    }

    // MARK: - Dehydration Impact

    struct AlcoholImpact {
        let standardDrinks: Double       // Number of standard drinks (14g pure alcohol each)
        let dehydrationML: Int           // Extra water needed to compensate
        let recoveryTimeHours: Double    // Time for body to fully process
        let bac: Double                  // Estimated BAC right now
        let riskLevel: RiskLevel
        let recommendations: [String]

        enum RiskLevel: String {
            case none
            case low        // 1-2 drinks
            case moderate   // 3-4 drinks
            case high       // 5+ drinks
        }
    }

    /// Calculate full alcohol impact on hydration
    func calculateImpact(
        beverageId: String,
        volumeML: Int,
        weightKg: Double,
        gender: HydrationCalculator.Gender,
        existingAlcoholToday: Double = 0 // grams already consumed today
    ) -> AlcoholImpact {
        guard let profile = NutrientDatabase.profile(for: beverageId),
              profile.alcoholABV > 0 else {
            return AlcoholImpact(
                standardDrinks: 0, dehydrationML: 0, recoveryTimeHours: 0,
                bac: 0, riskLevel: .none, recommendations: []
            )
        }

        // Calculate pure alcohol in grams
        // Volume (mL) × ABV × density of ethanol (0.789 g/mL)
        let alcoholGrams = Double(volumeML) * profile.alcoholABV * 0.789
        let totalAlcoholToday = existingAlcoholToday + alcoholGrams

        // Standard drinks (1 standard drink = 14g pure alcohol, NIAAA)
        let standardDrinks = totalAlcoholToday / 14.0

        // Dehydration: each gram of alcohol → ~10mL extra urine
        // Plus suppressed ADH hormone effect
        let dehydrationML = Int(alcoholGrams * 10.0)

        // Recovery time: liver processes ~7g alcohol/hour
        let recoveryHours = totalAlcoholToday / 7.0

        // BAC estimate (assumes drink consumed in last hour)
        let bac = estimateBAC(
            alcoholGrams: totalAlcoholToday,
            weightKg: weightKg,
            gender: gender,
            hoursSinceDrink: 0.5
        )

        // Risk level
        let riskLevel: AlcoholImpact.RiskLevel
        switch standardDrinks {
        case ..<0.1: riskLevel = .none
        case ..<2.5: riskLevel = .low
        case ..<4.5: riskLevel = .moderate
        default: riskLevel = .high
        }

        // Personalized recommendations
        var recommendations: [String] = []

        recommendations.append(
            String(localized: "Drink \(dehydrationML) mL extra water to compensate for this drink")
        )

        if standardDrinks >= 2 {
            recommendations.append(
                String(localized: "Alternate each alcoholic drink with a glass of water")
            )
        }

        if standardDrinks >= 3 {
            recommendations.append(
                String(localized: "Your body needs ~\(Int(recoveryHours)) hours to process today's alcohol")
            )
        }

        if riskLevel == .high {
            recommendations.append(
                String(localized: "Consider stopping — high alcohol intake severely dehydrates and strains your liver")
            )
        }

        // Gender-specific NIAAA guidelines
        let dailyLimit: Double = gender == .male ? 2.0 : 1.0
        if standardDrinks > dailyLimit {
            recommendations.append(
                String(localized: "You've exceeded the recommended daily limit of \(Int(dailyLimit)) drink\(dailyLimit > 1 ? "s" : "") for your profile")
            )
        }

        return AlcoholImpact(
            standardDrinks: standardDrinks,
            dehydrationML: dehydrationML,
            recoveryTimeHours: recoveryHours,
            bac: bac,
            riskLevel: riskLevel,
            recommendations: recommendations
        )
    }
}
