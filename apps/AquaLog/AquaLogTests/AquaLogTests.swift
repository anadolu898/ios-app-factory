import Foundation
import Testing
@testable import AquaLog

// MARK: - Model Tests

@Test func waterLogCreation() {
    let log = WaterLog(amount: 250, beverageType: "water")
    #expect(log.amount == 250)
    #expect(log.beverageType == "water")
}

@Test func waterLogWithNote() {
    let log = WaterLog(amount: 500, beverageType: "coffee", note: "Morning espresso")
    #expect(log.amount == 500)
    #expect(log.beverageType == "coffee")
    #expect(log.note == "Morning espresso")
}

@Test func userSettingsDefaults() {
    let settings = UserSettings()
    #expect(settings.dailyGoalML == 2500)
    #expect(settings.unitSystem == "metric")
    #expect(settings.hasCompletedOnboarding == false)
    #expect(settings.currentStreak == 0)
    #expect(settings.longestStreak == 0)
    #expect(settings.reminderEnabled == true)
    #expect(settings.reminderIntervalMinutes == 60)
}

@Test func userSettingsStreakFields() {
    let settings = UserSettings()
    settings.currentStreak = 5
    settings.longestStreak = 12
    settings.lastGoalMetDate = .now
    #expect(settings.currentStreak == 5)
    #expect(settings.longestStreak == 12)
    #expect(settings.lastGoalMetDate != nil)
}

@Test func userSettingsGoalDisplay() {
    let settings = UserSettings(dailyGoalML: 2500, unitSystem: "metric")
    #expect(settings.dailyGoalDisplayString == "2.5 L")

    let settingsOz = UserSettings(dailyGoalML: 2500, unitSystem: "imperial")
    #expect(settingsOz.dailyGoalDisplayString.contains("oz"))

    let settingsSmall = UserSettings(dailyGoalML: 500, unitSystem: "metric")
    #expect(settingsSmall.dailyGoalDisplayString == "500 mL")
}

// MARK: - Volume Formatting Tests

@Test func volumeFormattingMetric() {
    #expect(250.volumeString() == "250 mL")
    #expect(1500.volumeString() == "1.5 L")
    #expect(1000.volumeString() == "1.0 L")
    #expect(999.volumeString() == "999 mL")
    #expect(0.volumeString() == "0 mL")
    #expect(3700.volumeString() == "3.7 L")
}

@Test func volumeFormattingImperial() {
    #expect(250.volumeString(unitSystem: "imperial") == "8.5 oz")
    #expect(1000.volumeString(unitSystem: "imperial") == "34 oz") // 33.81 rounds to 34 for >= 10
    // Large values should drop decimal
    #expect(500.volumeString(unitSystem: "imperial") == "17 oz") // 16.9 rounds to 17 for >= 10
}

// MARK: - HydrationCalculator Tests

@Suite("Hydration Calculator")
@MainActor
struct HydrationCalculatorTests {

    let calculator = HydrationCalculator.shared

    @Test func baseCalculationMale70kg() {
        let goal = calculator.calculateDailyGoal(
            weightKg: 70,
            gender: .male,
            age: 30,
            activityLevel: .sedentary
        )
        // 70 * 33 = 2310, but male floor is 2500, sedentary multiplier 1.0 → 2500
        #expect(goal == 2500)
    }

    @Test func baseCalculationFemale60kg() {
        let goal = calculator.calculateDailyGoal(
            weightKg: 60,
            gender: .female,
            age: 25,
            activityLevel: .sedentary
        )
        // 60 * 33 = 1980, female floor is 2000, sedentary 1.0 → 2000
        #expect(goal == 2000)
    }

    @Test func heavyMaleHighActivity() {
        let goal = calculator.calculateDailyGoal(
            weightKg: 100,
            gender: .male,
            age: 35,
            activityLevel: .veryActive,
            climate: .hot
        )
        // 100 * 33 = 3300 (> male floor), × 1.55 = 5115, + 600 hot = 5715 → round 5700, clamp 5700
        #expect(goal >= 5000)
        #expect(goal <= 6000)
    }

    @Test func activityMultiplierProgression() {
        var goals: [Int] = []
        for level in HydrationCalculator.ActivityLevel.allCases {
            let g = calculator.calculateDailyGoal(
                weightKg: 80,
                gender: .male,
                age: 30,
                activityLevel: level
            )
            goals.append(g)
        }
        // Each level should produce an equal or higher goal
        for i in 1..<goals.count {
            #expect(goals[i] >= goals[i - 1], "Activity level \(i) should >= level \(i-1)")
        }
    }

    @Test func climateAdjustment() {
        let temperate = calculator.calculateDailyGoal(
            weightKg: 70, gender: .male, age: 30, activityLevel: .moderate, climate: .temperate
        )
        let hot = calculator.calculateDailyGoal(
            weightKg: 70, gender: .male, age: 30, activityLevel: .moderate, climate: .hot
        )
        let humid = calculator.calculateDailyGoal(
            weightKg: 70, gender: .male, age: 30, activityLevel: .moderate, climate: .humid
        )
        #expect(hot > temperate)
        #expect(humid > hot)
    }

    @Test func ageAdjustmentElderly() {
        let adult = calculator.calculateDailyGoal(
            weightKg: 70, gender: .male, age: 40, activityLevel: .sedentary
        )
        let elderly = calculator.calculateDailyGoal(
            weightKg: 70, gender: .male, age: 70, activityLevel: .sedentary
        )
        #expect(elderly >= adult, "Elderly should get equal or higher recommendation")
    }

    @Test func ageAdjustmentYouth() {
        let adult = calculator.calculateDailyGoal(
            weightKg: 60, gender: .other, age: 25, activityLevel: .sedentary
        )
        let youth = calculator.calculateDailyGoal(
            weightKg: 60, gender: .other, age: 16, activityLevel: .sedentary
        )
        #expect(youth <= adult, "Youth should get equal or lower recommendation")
    }

    @Test func pregnancyAddsWater() {
        let normal = calculator.calculateDailyGoal(
            weightKg: 65, gender: .female, age: 30, activityLevel: .light
        )
        let pregnant = calculator.calculateDailyGoal(
            weightKg: 65, gender: .female, age: 30, activityLevel: .light, isPregnant: true
        )
        #expect(pregnant > normal)
    }

    @Test func breastfeedingAddsWater() {
        let normal = calculator.calculateDailyGoal(
            weightKg: 65, gender: .female, age: 30, activityLevel: .light
        )
        let breastfeeding = calculator.calculateDailyGoal(
            weightKg: 65, gender: .female, age: 30, activityLevel: .light, isBreastfeeding: true
        )
        #expect(breastfeeding > normal)
        #expect(breastfeeding - normal >= 650) // ~700mL added, rounded
    }

    @Test func clampedToSafeRange() {
        let tinyPerson = calculator.calculateDailyGoal(
            weightKg: 30, gender: .female, age: 16, activityLevel: .sedentary
        )
        #expect(tinyPerson >= 1500, "Should never go below 1500mL")

        let hugePerson = calculator.calculateDailyGoal(
            weightKg: 150, gender: .male, age: 35, activityLevel: .veryActive, climate: .humid
        )
        #expect(hugePerson <= 6000, "Should never exceed 6000mL")
    }

    @Test func climateFromWeather() {
        let calc = HydrationCalculator.shared
        #expect(calc.climateFromWeather(temperatureC: 10, humidity: 30) == .cool)
        #expect(calc.climateFromWeather(temperatureC: 20, humidity: 50) == .temperate)
        #expect(calc.climateFromWeather(temperatureC: 28, humidity: 40) == .warm)
        #expect(calc.climateFromWeather(temperatureC: 35, humidity: 30) == .hot)
        #expect(calc.climateFromWeather(temperatureC: 35, humidity: 70) == .humid)
    }

    @Test func explanationTextContainsWeight() {
        let text = calculator.explanationText(
            weightKg: 80, gender: .male, age: 30, activityLevel: .moderate,
            climate: .temperate, goalML: 3300
        )
        #expect(text.contains("80"))
        #expect(text.contains("3.3 L") || text.contains("3300"))
    }
}

// MARK: - Caffeine Tests

@Suite("Caffeine Tracking")
struct CaffeineTests {

    @Test func coffeeCaffeine() {
        let mg = CaffeineInfo.caffeinePerServing(beverage: "coffee", amountML: 250)
        #expect(mg == 95.0)
    }

    @Test func teaCaffeine() {
        let mg = CaffeineInfo.caffeinePerServing(beverage: "tea", amountML: 250)
        #expect(mg == 47.0)
    }

    @Test func sodaCaffeine() {
        let mg = CaffeineInfo.caffeinePerServing(beverage: "soda", amountML: 250)
        #expect(mg == 33.0)
    }

    @Test func waterHasNoCaffeine() {
        let mg = CaffeineInfo.caffeinePerServing(beverage: "water", amountML: 500)
        #expect(mg == 0.0)
    }

    @Test func juiceHasNoCaffeine() {
        let mg = CaffeineInfo.caffeinePerServing(beverage: "juice", amountML: 300)
        #expect(mg == 0.0)
    }

    @Test func caffeineScalesWithVolume() {
        let small = CaffeineInfo.caffeinePerServing(beverage: "coffee", amountML: 125)
        let large = CaffeineInfo.caffeinePerServing(beverage: "coffee", amountML: 500)
        #expect(large == small * 4, "Double the volume should double the caffeine")
    }

    @Test func noWarningBelowThreshold() {
        let status = CaffeineInfo.statusMessage(totalCaffeineMG: 200)
        #expect(status == nil)
    }

    @Test func warningAtThreshold() {
        let status = CaffeineInfo.statusMessage(totalCaffeineMG: 300)
        #expect(status != nil)
        #expect(status?.severity == .warning)
    }

    @Test func criticalAtLimit() {
        let status = CaffeineInfo.statusMessage(totalCaffeineMG: 400)
        #expect(status != nil)
        #expect(status?.severity == .critical)
    }

    @Test func criticalAboveLimit() {
        let status = CaffeineInfo.statusMessage(totalCaffeineMG: 500)
        #expect(status?.severity == .critical)
    }
}

// MARK: - Beverage Tests

@Suite("Beverage Type")
struct BeverageTests {

    @Test func allBeveragesHaveIcons() {
        for beverage in Beverage.allCases {
            #expect(!beverage.icon.isEmpty, "\(beverage.rawValue) should have an icon")
        }
    }

    @Test func allBeveragesHaveNames() {
        for beverage in Beverage.allCases {
            #expect(!beverage.displayName.isEmpty, "\(beverage.rawValue) should have a display name")
        }
    }

    @Test func hydrationFactorInRange() {
        for beverage in Beverage.allCases {
            #expect(beverage.hydrationFactor > 0 && beverage.hydrationFactor <= 1.0,
                    "\(beverage.rawValue) hydration factor should be 0-1")
        }
    }

    @Test func waterIsFullHydration() {
        #expect(Beverage.water.hydrationFactor == 1.0)
    }

    @Test func quickAmountsNotEmpty() {
        for beverage in Beverage.allCases {
            #expect(!beverage.quickAmounts.isEmpty, "\(beverage.rawValue) should have quick amounts")
        }
    }

    @Test func onlyWaterIsFree() {
        #expect(Beverage.water.isFree == true)
        #expect(Beverage.coffee.isFree == false)
        #expect(Beverage.tea.isFree == false)
    }
}

// MARK: - NutrientDatabase Tests

@Suite("Nutrient Database")
struct NutrientDatabaseTests {

    @Test func allBeveragesHaveValidData() {
        for bev in NutrientDatabase.beverages {
            #expect(!bev.id.isEmpty)
            #expect(!bev.displayName.isEmpty)
            #expect(!bev.icon.isEmpty)
            #expect(bev.hydrationFactor > 0 && bev.hydrationFactor <= 1.1,
                    "\(bev.id) hydration factor \(bev.hydrationFactor) out of range")
            #expect(bev.caffeineMgPer250mL >= 0)
            #expect(bev.sugarGramsPer250mL >= 0)
            #expect(bev.alcoholABV >= 0 && bev.alcoholABV < 1.0)
        }
    }

    @Test func lookupByIdWorks() {
        let water = NutrientDatabase.profile(for: "water")
        #expect(water != nil)
        #expect(water?.hydrationFactor == 1.0)
        #expect(water?.caffeineMgPer250mL == 0)

        let missing = NutrientDatabase.profile(for: "nonexistent")
        #expect(missing == nil)
    }

    @Test func alcoholBeveragesHaveABV() {
        let alcoholic = NutrientDatabase.beverages(in: .alcohol)
        #expect(!alcoholic.isEmpty)
        for bev in alcoholic {
            #expect(bev.alcoholABV > 0, "\(bev.id) should have ABV > 0")
        }
    }

    @Test func nonAlcoholBeveragesHaveZeroABV() {
        let nonAlcoholic = NutrientDatabase.beverages.filter { $0.category != .alcohol }
        for bev in nonAlcoholic {
            #expect(bev.alcoholABV == 0, "\(bev.id) should have ABV == 0")
        }
    }

    @Test func netHydrationWaterIs100Percent() {
        let result = NutrientDatabase.netHydration(beverageId: "water", volumeML: 250)
        #expect(result.grossML == 250)
        #expect(result.netML == 250)
        #expect(result.waterDebt == 0)
    }

    @Test func netHydrationAlcoholHasDebt() {
        let result = NutrientDatabase.netHydration(beverageId: "wine_red", volumeML: 150)
        #expect(result.netML < result.grossML, "Wine should have less net hydration than gross")
        #expect(result.waterDebt > 0, "Wine should create water debt")
        #expect(!result.factors.isEmpty, "Should explain the dehydration factors")
    }

    @Test func netHydrationSugaryCostsWater() {
        let cola = NutrientDatabase.netHydration(beverageId: "soda", volumeML: 330)
        #expect(cola.netML < cola.grossML, "Cola should have reduced net hydration")
    }

    @Test func freeBeveragesExist() {
        let free = NutrientDatabase.freeBeverages
        #expect(free.count >= 5, "Should have at least 5 free beverages")
        #expect(free.contains { $0.id == "water" })
    }

    @Test func milkHydratesBetterThanWater() {
        let milk = NutrientDatabase.profile(for: "milk")
        #expect(milk != nil)
        #expect(milk!.hydrationFactor > 1.0, "Milk hydrates better than water per research")
    }
}

// MARK: - AlcoholCalculator Tests

@Suite("Alcohol Calculator")
@MainActor
struct AlcoholCalculatorTests {

    let calc = AlcoholCalculator.shared

    @Test func nonAlcoholHasNoImpact() {
        let impact = calc.calculateImpact(
            beverageId: "water", volumeML: 250, weightKg: 70, gender: .male
        )
        #expect(impact.standardDrinks == 0)
        #expect(impact.dehydrationML == 0)
        #expect(impact.riskLevel == .none)
    }

    @Test func beerImpactIsLow() {
        let impact = calc.calculateImpact(
            beverageId: "beer", volumeML: 330, weightKg: 80, gender: .male
        )
        #expect(impact.standardDrinks > 0 && impact.standardDrinks < 2)
        #expect(impact.dehydrationML > 0)
        #expect(impact.riskLevel == .low)
        #expect(!impact.recommendations.isEmpty)
    }

    @Test func spiritsHaveHighDehydration() {
        let spirits = calc.calculateImpact(
            beverageId: "spirits", volumeML: 50, weightKg: 70, gender: .male
        )
        let beer = calc.calculateImpact(
            beverageId: "beer", volumeML: 330, weightKg: 70, gender: .male
        )
        // 50mL spirits (40% ABV) vs 330mL beer (5% ABV)
        // Both roughly 1 standard drink but spirits are more concentrated
        #expect(spirits.dehydrationML > 0)
        #expect(beer.dehydrationML > 0)
    }

    @Test func genderAffectsBAC() {
        let maleBAC = calc.estimateBAC(alcoholGrams: 14, weightKg: 70, gender: .male, hoursSinceDrink: 0)
        let femaleBAC = calc.estimateBAC(alcoholGrams: 14, weightKg: 70, gender: .female, hoursSinceDrink: 0)
        #expect(femaleBAC > maleBAC, "Same weight female should have higher BAC due to body water ratio")
    }

    @Test func bacDecaysOverTime() {
        let initial = calc.estimateBAC(alcoholGrams: 14, weightKg: 70, gender: .male, hoursSinceDrink: 0)
        let after2h = calc.estimateBAC(alcoholGrams: 14, weightKg: 70, gender: .male, hoursSinceDrink: 2)
        let after8h = calc.estimateBAC(alcoholGrams: 14, weightKg: 70, gender: .male, hoursSinceDrink: 8)
        #expect(after2h < initial)
        #expect(after8h <= after2h)
        #expect(after8h >= 0, "BAC should never go negative")
    }

    @Test func cumulativeAlcoholIncreasesRisk() {
        let oneGlass = calc.calculateImpact(
            beverageId: "wine_red", volumeML: 150, weightKg: 65, gender: .female
        )
        let afterThree = calc.calculateImpact(
            beverageId: "wine_red", volumeML: 150, weightKg: 65, gender: .female,
            existingAlcoholToday: 30 // ~2 glasses already
        )
        #expect(afterThree.riskLevel.rawValue >= oneGlass.riskLevel.rawValue)
    }
}

// MARK: - CaffeineTracker Tests

@Suite("Caffeine Tracker")
@MainActor
struct CaffeineTrackerTests {

    let tracker = CaffeineTracker.shared

    @Test func noDrinksReturnsZero() {
        let state = tracker.calculateState(drinks: [])
        #expect(state.currentMG == 0)
        #expect(state.totalConsumedMG == 0)
        #expect(state.sleepImpact == .none)
        #expect(state.clearByTime == nil)
    }

    @Test func recentCoffeeShowsHighLevel() {
        let drinks = [(caffeineeMG: 95.0, timestamp: Date.now.addingTimeInterval(-1800))] // 30 min ago
        let state = tracker.calculateState(drinks: drinks)
        #expect(state.currentMG > 80, "Should still have most of the caffeine after 30 min")
        #expect(state.totalConsumedMG == 95)
    }

    @Test func caffeineDecaysOverTime() {
        let fiveHoursAgo = Date.now.addingTimeInterval(-5 * 3600)
        let drinks = [(caffeineeMG: 100.0, timestamp: fiveHoursAgo)]
        let state = tracker.calculateState(drinks: drinks)
        // After one half-life (~5hrs), should be ~50mg
        #expect(state.currentMG > 40 && state.currentMG < 60,
                "After 5 hours (one half-life), should be ~50mg, got \(state.currentMG)")
    }

    @Test func multipleDrinksAccumulate() {
        let drinks = [
            (caffeineeMG: 95.0, timestamp: Date.now.addingTimeInterval(-3600)),  // 1hr ago
            (caffeineeMG: 95.0, timestamp: Date.now.addingTimeInterval(-1800)),  // 30min ago
        ]
        let state = tracker.calculateState(drinks: drinks)
        #expect(state.currentMG > 150, "Two recent coffees should show high caffeine")
        #expect(state.totalConsumedMG == 190)
    }

    @Test func lateCaffeineImpactsSleep() {
        // Coffee at 9 PM with bedtime at 11 PM
        let drinks = [(caffeineeMG: 200.0, timestamp: Date.now.addingTimeInterval(-1800))]
        let state = tracker.calculateState(drinks: drinks, bedtimeHour: Calendar.current.component(.hour, from: Date.now) + 2)
        #expect(state.sleepImpact != .none, "200mg caffeine 2 hours before bed should impact sleep")
    }

    @Test func decayCurveHas48Points() {
        let drinks = [(caffeineeMG: 95.0, timestamp: Date.now)]
        let curve = tracker.decayCurve(drinks: drinks)
        #expect(curve.count == 48, "Should have 48 half-hour points for 24 hours")
    }
}

// MARK: - HealthInsightsGenerator Tests

@Suite("Health Insights")
@MainActor
struct HealthInsightsTests {

    let generator = HealthInsightsGenerator.shared

    @Test func day0HasNoInsights() {
        let report = generator.generateReport(currentStreak: 0, longestStreak: 0, weekLogs: [])
        #expect(report.unlockedInsights.isEmpty)
        #expect(report.nextMilestone != nil)
    }

    @Test func day1UnlocksFirstInsight() {
        let report = generator.generateReport(currentStreak: 1, longestStreak: 1, weekLogs: [])
        #expect(!report.unlockedInsights.isEmpty)
        #expect(report.unlockedInsights.first?.milestone == .day1)
    }

    @Test func day7UnlocksMultipleInsights() {
        let report = generator.generateReport(currentStreak: 7, longestStreak: 7, weekLogs: [])
        let milestones = Set(report.unlockedInsights.map { $0.milestone })
        #expect(milestones.contains(.day1))
        #expect(milestones.contains(.day3))
        #expect(milestones.contains(.day7))
        #expect(!milestones.contains(.day14))
    }

    @Test func scoreIsBounded() {
        let report = generator.generateReport(currentStreak: 100, longestStreak: 100, weekLogs: [])
        #expect(report.overallScore >= 0 && report.overallScore <= 100)

        let badReport = generator.generateReport(
            currentStreak: 0, longestStreak: 0, weekLogs: [],
            weekCaffeineMG: 5000, weekAlcoholDrinks: 30
        )
        #expect(badReport.overallScore >= 0 && badReport.overallScore <= 100)
    }

    @Test func nextMilestoneCalculation() {
        let report = generator.generateReport(currentStreak: 5, longestStreak: 5, weekLogs: [])
        #expect(report.nextMilestone == .day7)
        #expect(report.daysToNextMilestone == 2)
    }

    @Test func allInsightsHaveCitations() {
        let report = generator.generateReport(currentStreak: 90, longestStreak: 90, weekLogs: [])
        for insight in report.unlockedInsights {
            #expect(!insight.citation.isEmpty, "\(insight.title) should have a citation")
        }
    }
}
