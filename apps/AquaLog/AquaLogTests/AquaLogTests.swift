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
