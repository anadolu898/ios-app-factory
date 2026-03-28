import Foundation

/// Comprehensive beverage nutrition data for smart hydration calculations
/// Sources: USDA FoodData Central, FDA caffeine guidelines, WHO alcohol guidelines
struct NutrientDatabase {

    // MARK: - Beverage Nutrition Profile

    struct BeverageProfile {
        let id: String
        let category: Category
        let displayName: String
        let icon: String
        let caffeineMgPer250mL: Double
        let sugarGramsPer250mL: Double
        let alcoholABV: Double           // 0.0 for non-alcoholic
        let hydrationFactor: Double       // 1.0 = pure water, <1.0 = net loss from processing
        let caloriesPer250mL: Double
        let isFree: Bool                  // Available in free tier

        enum Category: String, CaseIterable, Codable {
            case water
            case hotDrink
            case juice
            case soda
            case milk
            case alcohol
            case sports
        }
    }

    // MARK: - Full Beverage Database

    static let beverages: [BeverageProfile] = [
        // === Water ===
        BeverageProfile(id: "water", category: .water, displayName: String(localized: "Water"),
                        icon: "drop.fill", caffeineMgPer250mL: 0, sugarGramsPer250mL: 0,
                        alcoholABV: 0, hydrationFactor: 1.0, caloriesPer250mL: 0, isFree: true),
        BeverageProfile(id: "sparkling_water", category: .water, displayName: String(localized: "Sparkling Water"),
                        icon: "bubbles.and.sparkles", caffeineMgPer250mL: 0, sugarGramsPer250mL: 0,
                        alcoholABV: 0, hydrationFactor: 1.0, caloriesPer250mL: 0, isFree: true),
        BeverageProfile(id: "coconut_water", category: .water, displayName: String(localized: "Coconut Water"),
                        icon: "leaf.fill", caffeineMgPer250mL: 0, sugarGramsPer250mL: 11,
                        alcoholABV: 0, hydrationFactor: 1.0, caloriesPer250mL: 46, isFree: true),

        // === Hot Drinks ===
        BeverageProfile(id: "coffee", category: .hotDrink, displayName: String(localized: "Coffee"),
                        icon: "mug.fill", caffeineMgPer250mL: 95, sugarGramsPer250mL: 0,
                        alcoholABV: 0, hydrationFactor: 0.83, caloriesPer250mL: 2, isFree: true),
        BeverageProfile(id: "espresso", category: .hotDrink, displayName: String(localized: "Espresso"),
                        icon: "mug.fill", caffeineMgPer250mL: 212, sugarGramsPer250mL: 0,
                        alcoholABV: 0, hydrationFactor: 0.75, caloriesPer250mL: 5, isFree: false),
        BeverageProfile(id: "latte", category: .hotDrink, displayName: String(localized: "Latte"),
                        icon: "mug.fill", caffeineMgPer250mL: 63, sugarGramsPer250mL: 9,
                        alcoholABV: 0, hydrationFactor: 0.88, caloriesPer250mL: 103, isFree: false),
        BeverageProfile(id: "tea", category: .hotDrink, displayName: String(localized: "Tea"),
                        icon: "cup.and.saucer.fill", caffeineMgPer250mL: 47, sugarGramsPer250mL: 0,
                        alcoholABV: 0, hydrationFactor: 0.92, caloriesPer250mL: 2, isFree: true),
        BeverageProfile(id: "green_tea", category: .hotDrink, displayName: String(localized: "Green Tea"),
                        icon: "cup.and.saucer.fill", caffeineMgPer250mL: 28, sugarGramsPer250mL: 0,
                        alcoholABV: 0, hydrationFactor: 0.95, caloriesPer250mL: 2, isFree: false),
        BeverageProfile(id: "herbal_tea", category: .hotDrink, displayName: String(localized: "Herbal Tea"),
                        icon: "cup.and.saucer.fill", caffeineMgPer250mL: 0, sugarGramsPer250mL: 0,
                        alcoholABV: 0, hydrationFactor: 0.98, caloriesPer250mL: 2, isFree: false),

        // === Juice ===
        BeverageProfile(id: "juice", category: .juice, displayName: String(localized: "Orange Juice"),
                        icon: "carrot.fill", caffeineMgPer250mL: 0, sugarGramsPer250mL: 21,
                        alcoholABV: 0, hydrationFactor: 0.85, caloriesPer250mL: 112, isFree: true),
        BeverageProfile(id: "smoothie", category: .juice, displayName: String(localized: "Smoothie"),
                        icon: "blender.fill", caffeineMgPer250mL: 0, sugarGramsPer250mL: 25,
                        alcoholABV: 0, hydrationFactor: 0.82, caloriesPer250mL: 150, isFree: false),

        // === Soda ===
        BeverageProfile(id: "soda", category: .soda, displayName: String(localized: "Cola"),
                        icon: "bubbles.and.sparkles.fill", caffeineMgPer250mL: 33, sugarGramsPer250mL: 26,
                        alcoholABV: 0, hydrationFactor: 0.70, caloriesPer250mL: 105, isFree: true),
        BeverageProfile(id: "diet_soda", category: .soda, displayName: String(localized: "Diet Soda"),
                        icon: "bubbles.and.sparkles.fill", caffeineMgPer250mL: 38, sugarGramsPer250mL: 0,
                        alcoholABV: 0, hydrationFactor: 0.85, caloriesPer250mL: 1, isFree: false),
        BeverageProfile(id: "energy_drink", category: .soda, displayName: String(localized: "Energy Drink"),
                        icon: "bolt.fill", caffeineMgPer250mL: 80, sugarGramsPer250mL: 27,
                        alcoholABV: 0, hydrationFactor: 0.60, caloriesPer250mL: 110, isFree: false),

        // === Milk ===
        BeverageProfile(id: "milk", category: .milk, displayName: String(localized: "Milk"),
                        icon: "cup.and.saucer.fill", caffeineMgPer250mL: 0, sugarGramsPer250mL: 12,
                        alcoholABV: 0, hydrationFactor: 1.04, caloriesPer250mL: 149, isFree: true),
        // Note: milk has >1.0 hydration factor — studies show it hydrates better than water
        // due to sodium/potassium content slowing gastric emptying

        // === Alcohol ===
        BeverageProfile(id: "beer", category: .alcohol, displayName: String(localized: "Beer"),
                        icon: "wineglass.fill", caffeineMgPer250mL: 0, sugarGramsPer250mL: 3,
                        alcoholABV: 0.05, hydrationFactor: 0.62, caloriesPer250mL: 107, isFree: false),
        BeverageProfile(id: "light_beer", category: .alcohol, displayName: String(localized: "Light Beer"),
                        icon: "wineglass.fill", caffeineMgPer250mL: 0, sugarGramsPer250mL: 1,
                        alcoholABV: 0.04, hydrationFactor: 0.72, caloriesPer250mL: 76, isFree: false),
        BeverageProfile(id: "wine_red", category: .alcohol, displayName: String(localized: "Red Wine"),
                        icon: "wineglass.fill", caffeineMgPer250mL: 0, sugarGramsPer250mL: 1,
                        alcoholABV: 0.135, hydrationFactor: 0.40, caloriesPer250mL: 213, isFree: false),
        BeverageProfile(id: "wine_white", category: .alcohol, displayName: String(localized: "White Wine"),
                        icon: "wineglass.fill", caffeineMgPer250mL: 0, sugarGramsPer250mL: 2,
                        alcoholABV: 0.12, hydrationFactor: 0.45, caloriesPer250mL: 198, isFree: false),
        BeverageProfile(id: "spirits", category: .alcohol, displayName: String(localized: "Spirits (Vodka/Whiskey)"),
                        icon: "wineglass.fill", caffeineMgPer250mL: 0, sugarGramsPer250mL: 0,
                        alcoholABV: 0.40, hydrationFactor: 0.10, caloriesPer250mL: 560, isFree: false),
        BeverageProfile(id: "cocktail", category: .alcohol, displayName: String(localized: "Cocktail"),
                        icon: "wineglass.fill", caffeineMgPer250mL: 0, sugarGramsPer250mL: 22,
                        alcoholABV: 0.15, hydrationFactor: 0.35, caloriesPer250mL: 300, isFree: false),

        // === Sports ===
        BeverageProfile(id: "sports_drink", category: .sports, displayName: String(localized: "Sports Drink"),
                        icon: "figure.run", caffeineMgPer250mL: 0, sugarGramsPer250mL: 14,
                        alcoholABV: 0, hydrationFactor: 1.05, caloriesPer250mL: 63, isFree: false),
        // Sports drinks >1.0 due to electrolyte-enhanced absorption
    ]

    // MARK: - Lookup

    static func profile(for id: String) -> BeverageProfile? {
        beverages.first { $0.id == id }
    }

    static func beverages(in category: BeverageProfile.Category) -> [BeverageProfile] {
        beverages.filter { $0.category == category }
    }

    static var freeBeverages: [BeverageProfile] {
        beverages.filter { $0.isFree }
    }

    // MARK: - Calculations

    /// Calculate net effective hydration from a drink
    /// Accounts for: base volume × hydration factor, minus sugar processing water, minus alcohol dehydration
    static func netHydration(beverageId: String, volumeML: Int) -> NetHydrationResult {
        guard let profile = profile(for: beverageId) else {
            return NetHydrationResult(grossML: volumeML, netML: volumeML, waterDebt: 0, factors: [])
        }

        let volume = Double(volumeML)
        var factors: [String] = []

        // Base hydration
        let baseHydration = volume * profile.hydrationFactor

        // Sugar processing cost: ~1mL water per gram of sugar to metabolize
        let sugarGrams = profile.sugarGramsPer250mL * (volume / 250.0)
        let sugarCost = sugarGrams * 1.0
        if sugarCost > 2 {
            factors.append(String(localized: "\(Int(sugarGrams))g sugar uses \(Int(sugarCost)) mL to process"))
        }

        // Alcohol dehydration: alcohol inhibits ADH hormone
        // Each gram of alcohol causes ~10mL extra urine output
        let alcoholGrams = profile.alcoholABV * (volume / 1000.0) * 789 // density of ethanol
        let alcoholCost = alcoholGrams * 10.0
        if alcoholCost > 5 {
            factors.append(String(localized: "Alcohol causes \(Int(alcoholCost)) mL extra fluid loss"))
        }

        // Caffeine mild diuretic effect (only significant above ~300mg/day cumulative)
        let caffeineMG = profile.caffeineMgPer250mL * (volume / 250.0)
        if caffeineMG > 50 {
            factors.append(String(localized: "\(Int(caffeineMG)) mg caffeine (mild diuretic)"))
        }

        let netML = max(0, baseHydration - sugarCost - alcoholCost)
        let waterDebt = max(0, volume - netML)

        return NetHydrationResult(
            grossML: volumeML,
            netML: Int(netML),
            waterDebt: Int(waterDebt),
            factors: factors
        )
    }

    struct NetHydrationResult {
        let grossML: Int      // What you drank
        let netML: Int        // Effective hydration
        let waterDebt: Int    // Extra water needed to compensate
        let factors: [String] // Explanation strings
    }
}
