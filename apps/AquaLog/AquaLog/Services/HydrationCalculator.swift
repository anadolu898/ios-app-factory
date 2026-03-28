import Foundation
import CoreLocation
import WeatherKit

/// Science-based hydration calculator
/// Sources: National Academies of Sciences, Mayo Clinic, WHO guidelines
@MainActor
final class HydrationCalculator {
    static let shared = HydrationCalculator()

    private init() {}

    // MARK: - User Profile

    enum Gender: String, CaseIterable, Codable {
        case male, female, other
        var displayName: String {
            switch self {
            case .male: String(localized: "Male")
            case .female: String(localized: "Female")
            case .other: String(localized: "Other")
            }
        }
    }

    enum ActivityLevel: String, CaseIterable, Codable {
        case sedentary      // Desk job, no exercise
        case light          // Light exercise 1-3 days/week
        case moderate       // Moderate exercise 3-5 days/week
        case active         // Hard exercise 6-7 days/week
        case veryActive     // Athlete or physical labor

        var displayName: String {
            switch self {
            case .sedentary: String(localized: "Sedentary")
            case .light: String(localized: "Lightly Active")
            case .moderate: String(localized: "Moderately Active")
            case .active: String(localized: "Very Active")
            case .veryActive: String(localized: "Athlete / Physical Labor")
            }
        }

        var description: String {
            switch self {
            case .sedentary: String(localized: "Desk job, little to no exercise")
            case .light: String(localized: "Light exercise 1-3 days/week")
            case .moderate: String(localized: "Moderate exercise 3-5 days/week")
            case .active: String(localized: "Hard exercise 6-7 days/week")
            case .veryActive: String(localized: "Athlete or physical labor job")
            }
        }

        var multiplier: Double {
            switch self {
            case .sedentary: 1.0
            case .light: 1.12
            case .moderate: 1.25
            case .active: 1.4
            case .veryActive: 1.55
            }
        }
    }

    enum Climate: String, CaseIterable, Codable {
        case cool       // < 15°C
        case temperate  // 15-25°C
        case warm       // 25-32°C
        case hot        // 32°C+
        case humid      // High humidity regardless of temp

        var displayName: String {
            switch self {
            case .cool: String(localized: "Cool / Indoor")
            case .temperate: String(localized: "Temperate")
            case .warm: String(localized: "Warm")
            case .hot: String(localized: "Hot")
            case .humid: String(localized: "Hot & Humid")
            }
        }

        var additionalML: Int {
            switch self {
            case .cool: 0
            case .temperate: 0
            case .warm: 300
            case .hot: 600
            case .humid: 900
            }
        }
    }

    // MARK: - Core Calculation

    /// Calculate personalized daily water intake in mL
    func calculateDailyGoal(
        weightKg: Double,
        gender: Gender,
        age: Int,
        activityLevel: ActivityLevel,
        climate: Climate = .temperate,
        isPregnant: Bool = false,
        isBreastfeeding: Bool = false
    ) -> Int {
        // Base calculation: weight × 33mL (established medical formula)
        var baseML = weightKg * 33.0

        // Gender adjustment (National Academies baseline)
        // Men: 3700mL, Women: 2700mL as anchors
        switch gender {
        case .male:
            baseML = max(baseML, 2500)
        case .female:
            baseML = max(baseML, 2000)
        case .other:
            baseML = max(baseML, 2200)
        }

        // Activity multiplier
        baseML *= activityLevel.multiplier

        // Climate adjustment
        baseML += Double(climate.additionalML)

        // Age adjustment
        if age > 65 {
            // Older adults often need more despite feeling less thirsty
            baseML *= 1.05
        } else if age < 18 {
            // Youth needs less absolute volume
            baseML *= 0.85
        }

        // Pregnancy/breastfeeding (WHO guidelines: +300-700mL)
        if isPregnant {
            baseML += 300
        }
        if isBreastfeeding {
            baseML += 700
        }

        // Round to nearest 50mL for clean display
        let rounded = Int((baseML / 50.0).rounded()) * 50
        return max(1500, min(rounded, 6000)) // Clamp to safe range
    }

    // MARK: - Weather-Based Adjustment

    /// Determine climate category from weather data
    func climateFromWeather(temperatureC: Double, humidity: Double) -> Climate {
        if temperatureC >= 32 && humidity >= 60 {
            return .humid
        } else if temperatureC >= 32 {
            return .hot
        } else if temperatureC >= 25 {
            return .warm
        } else if temperatureC >= 15 {
            return .temperate
        } else {
            return .cool
        }
    }

    /// Fetch current weather and calculate climate adjustment
    func fetchWeatherAdjustment(for location: CLLocation) async -> Climate {
        do {
            let weather = try await WeatherService.shared.weather(for: location)
            let temp = weather.currentWeather.temperature.converted(to: .celsius).value
            let humidity = weather.currentWeather.humidity * 100
            return climateFromWeather(temperatureC: temp, humidity: humidity)
        } catch {
            return .temperate // Default if weather unavailable
        }
    }

    // MARK: - Explanation Text

    /// Generate a human-readable explanation of the recommendation
    func explanationText(
        weightKg: Double,
        gender: Gender,
        age: Int,
        activityLevel: ActivityLevel,
        climate: Climate,
        goalML: Int
    ) -> String {
        var factors: [String] = []

        factors.append(String(localized: "Based on your weight of \(Int(weightKg)) kg"))

        if activityLevel != .sedentary {
            factors.append(String(localized: "adjusted for your \(activityLevel.displayName.lowercased()) lifestyle"))
        }

        if climate != .temperate {
            factors.append(String(localized: "with extra hydration for \(climate.displayName.lowercased()) conditions"))
        }

        if age > 65 {
            factors.append(String(localized: "with a slight increase for your age group"))
        }

        let base = factors.joined(separator: ", ")
        let goalDisplay = goalML >= 1000
            ? String(format: "%.1f L", Double(goalML) / 1000.0)
            : "\(goalML) mL"

        return String(localized: "\(base), we recommend \(goalDisplay) per day.")
    }
}

// MARK: - Caffeine Tracker

struct CaffeineInfo {
    /// Caffeine content in mg per serving for each beverage type
    static func caffeinePerServing(beverage: String, amountML: Int) -> Double {
        let servingRatio = Double(amountML) / 250.0 // Normalize to 250mL serving

        switch beverage.lowercased() {
        case "coffee":
            return 95.0 * servingRatio  // ~95mg per 250mL cup
        case "tea":
            return 47.0 * servingRatio  // ~47mg per 250mL cup
        case "soda":
            return 33.0 * servingRatio  // ~40mg per 330mL can, normalized
        default:
            return 0 // Water, juice, milk, smoothie = no caffeine
        }
    }

    /// FDA recommended daily limit
    static let dailyLimitMG: Double = 400.0

    /// Warning threshold (75% of limit)
    static let warningThresholdMG: Double = 300.0

    /// Get caffeine status message
    static func statusMessage(totalCaffeineMG: Double) -> (message: String, severity: CaffeineSeverity)? {
        if totalCaffeineMG >= dailyLimitMG {
            return (
                String(localized: "You've reached the recommended daily caffeine limit (\(Int(dailyLimitMG))mg). Consider switching to water or herbal tea."),
                .critical
            )
        } else if totalCaffeineMG >= warningThresholdMG {
            let remaining = Int(dailyLimitMG - totalCaffeineMG)
            return (
                String(localized: "You're approaching the daily caffeine limit. \(remaining)mg remaining."),
                .warning
            )
        }
        return nil
    }

    enum CaffeineSeverity {
        case warning, critical
    }
}
