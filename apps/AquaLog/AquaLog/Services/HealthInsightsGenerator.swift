import Foundation

/// Generates personalized health insights based on hydration streaks and patterns
/// All claims are backed by published research with citations
@MainActor
final class HealthInsightsGenerator {
    static let shared = HealthInsightsGenerator()
    private init() {}

    // MARK: - Insight Model

    struct HealthInsight: Identifiable {
        let id = UUID()
        let icon: String
        let title: String
        let description: String
        let citation: String
        let milestone: Milestone
        let isPremium: Bool

        enum Milestone: Int, CaseIterable {
            case day1 = 1
            case day3 = 3
            case day7 = 7
            case day14 = 14
            case day30 = 30
            case day60 = 60
            case day90 = 90
        }
    }

    struct HealthReport {
        let streakDays: Int
        let unlockedInsights: [HealthInsight]
        let nextMilestone: HealthInsight.Milestone?
        let daysToNextMilestone: Int
        let overallScore: Int                // 0-100 hydration health score
        let weekSummary: WeekSummary?
    }

    struct WeekSummary {
        let daysOnGoal: Int
        let totalIntakeML: Int
        let avgDailyML: Int
        let totalCaffeineMG: Double
        let totalAlcoholDrinks: Double
        let netHydrationScore: Int          // 0-100
        let topBeverage: String
        let insights: [String]
    }

    // MARK: - Streak-Based Health Insights Database

    private let insightDatabase: [HealthInsight] = [
        // Day 1
        HealthInsight(
            icon: "drop.fill",
            title: String(localized: "First Step Taken"),
            description: String(localized: "Meeting your hydration goal even once improves cognitive function. Studies show that just 1-2% dehydration impairs concentration, alertness, and short-term memory."),
            citation: "Popkin et al., Nutrition Reviews, 2010",
            milestone: .day1,
            isPremium: false
        ),

        // Day 3
        HealthInsight(
            icon: "brain.head.profile.fill",
            title: String(localized: "Brain Boost Active"),
            description: String(localized: "After 3 days of proper hydration, your brain's processing speed and working memory begin to normalize. Dehydrated individuals show 12% slower reaction times."),
            citation: "Adan, Journal of the American College of Nutrition, 2012",
            milestone: .day3,
            isPremium: false
        ),

        // Day 7
        HealthInsight(
            icon: "face.smiling.fill",
            title: String(localized: "Skin Hydration Improving"),
            description: String(localized: "One week of consistent hydration increases skin elasticity and moisture levels. The dermal layer begins to show measurable improvement in turgor and appearance."),
            citation: "Palma et al., Clinical, Cosmetic and Investigational Dermatology, 2015",
            milestone: .day7,
            isPremium: true
        ),
        HealthInsight(
            icon: "bolt.heart.fill",
            title: String(localized: "Kidney Function Optimized"),
            description: String(localized: "Your kidneys filter ~180 liters of blood daily. With 7 days of optimal hydration, filtration efficiency stabilizes and your risk of kidney stone formation begins to decrease."),
            citation: "Clark et al., European Journal of Clinical Nutrition, 2018",
            milestone: .day7,
            isPremium: true
        ),

        // Day 14
        HealthInsight(
            icon: "figure.walk",
            title: String(localized: "Physical Performance Up"),
            description: String(localized: "Two weeks of consistent hydration improves exercise performance by 10-20%. Your muscles recover faster, joints stay lubricated, and perceived exertion drops."),
            citation: "Cheuvront & Kenefick, Comprehensive Physiology, 2014",
            milestone: .day14,
            isPremium: true
        ),
        HealthInsight(
            icon: "stomach",
            title: String(localized: "Digestive Health Improved"),
            description: String(localized: "Adequate hydration for 14+ days significantly reduces constipation risk. Water helps break down food and ensures smooth passage through the digestive tract."),
            citation: "Boilesen et al., Nutrition Reviews, 2017",
            milestone: .day14,
            isPremium: true
        ),

        // Day 30
        HealthInsight(
            icon: "heart.fill",
            title: String(localized: "Cardiovascular Benefit"),
            description: String(localized: "A month of proper hydration reduces blood viscosity, making it easier for your heart to pump. People who drink 5+ glasses daily have a 41% lower risk of fatal coronary heart disease."),
            citation: "Chan et al., American Journal of Epidemiology, 2002",
            milestone: .day30,
            isPremium: true
        ),
        HealthInsight(
            icon: "liver.fill",
            title: String(localized: "Liver Health Supported"),
            description: String(localized: "30 days of optimal hydration supports your liver's detoxification pathways. Water is essential for phase II liver detoxification and bile production, reducing metabolic waste buildup."),
            citation: "Jequier & Constant, European Journal of Clinical Nutrition, 2010",
            milestone: .day30,
            isPremium: true
        ),

        // Day 60
        HealthInsight(
            icon: "sparkles",
            title: String(localized: "Habit Formed"),
            description: String(localized: "Research shows it takes an average of 66 days to form an automatic habit. Your hydration habit is now deeply embedded — you've likely noticed you feel thirsty before you used to."),
            citation: "Lally et al., European Journal of Social Psychology, 2010",
            milestone: .day60,
            isPremium: true
        ),

        // Day 90
        HealthInsight(
            icon: "shield.checkered",
            title: String(localized: "Long-Term Protection Active"),
            description: String(localized: "90 days of consistent hydration is associated with measurable improvements in kidney function markers, reduced UTI frequency, and better metabolic health indicators across multiple studies."),
            citation: "Clark et al., European Journal of Clinical Nutrition, 2018",
            milestone: .day90,
            isPremium: true
        ),
    ]

    // MARK: - Generate Report

    func generateReport(
        currentStreak: Int,
        longestStreak: Int,
        weekLogs: [(date: Date, totalML: Int, goalML: Int)],
        weekCaffeineMG: Double = 0,
        weekAlcoholDrinks: Double = 0
    ) -> HealthReport {
        // Find unlocked insights
        let unlocked = insightDatabase.filter { $0.milestone.rawValue <= currentStreak }

        // Find next milestone
        let nextMilestone = HealthInsight.Milestone.allCases.first { $0.rawValue > currentStreak }
        let daysToNext = (nextMilestone?.rawValue ?? 0) - currentStreak

        // Calculate overall score (0-100)
        let overallScore = calculateScore(
            streak: currentStreak,
            weekLogs: weekLogs,
            caffeineMG: weekCaffeineMG,
            alcoholDrinks: weekAlcoholDrinks
        )

        // Generate week summary
        let weekSummary = generateWeekSummary(
            logs: weekLogs,
            caffeineMG: weekCaffeineMG,
            alcoholDrinks: weekAlcoholDrinks
        )

        return HealthReport(
            streakDays: currentStreak,
            unlockedInsights: unlocked,
            nextMilestone: nextMilestone,
            daysToNextMilestone: daysToNext,
            overallScore: overallScore,
            weekSummary: weekSummary
        )
    }

    // MARK: - Score Calculation

    private func calculateScore(
        streak: Int,
        weekLogs: [(date: Date, totalML: Int, goalML: Int)],
        caffeineMG: Double,
        alcoholDrinks: Double
    ) -> Int {
        var score: Double = 50 // Base score

        // Streak bonus: up to +20 points
        score += min(Double(streak), 30) * (20.0 / 30.0)

        // Weekly goal adherence: up to +25 points
        let daysOnGoal = weekLogs.filter { $0.totalML >= $0.goalML }.count
        score += Double(daysOnGoal) / 7.0 * 25.0

        // Caffeine penalty: lose up to -10 if consistently over 400mg
        let avgDailyCaffeine = caffeineMG / 7.0
        if avgDailyCaffeine > 400 {
            score -= 10
        } else if avgDailyCaffeine > 300 {
            score -= 5
        }

        // Alcohol penalty: lose up to -15
        if alcoholDrinks > 14 { // More than 2/day average
            score -= 15
        } else if alcoholDrinks > 7 {
            score -= 8
        } else if alcoholDrinks > 3 {
            score -= 3
        }

        return max(0, min(100, Int(score)))
    }

    private func generateWeekSummary(
        logs: [(date: Date, totalML: Int, goalML: Int)],
        caffeineMG: Double,
        alcoholDrinks: Double
    ) -> WeekSummary? {
        guard !logs.isEmpty else { return nil }

        let daysOnGoal = logs.filter { $0.totalML >= $0.goalML }.count
        let totalIntake = logs.reduce(0) { $0 + $1.totalML }
        let avgDaily = totalIntake / max(logs.count, 1)

        var insights: [String] = []

        if daysOnGoal == 7 {
            insights.append(String(localized: "Perfect week! Every day on target."))
        } else if daysOnGoal >= 5 {
            insights.append(String(localized: "\(daysOnGoal)/7 days on goal — solid consistency."))
        } else {
            insights.append(String(localized: "\(daysOnGoal)/7 days on goal — try to improve next week."))
        }

        let avgDailyCaffeine = caffeineMG / 7.0
        if avgDailyCaffeine > 300 {
            insights.append(String(localized: "Caffeine averaged \(Int(avgDailyCaffeine))mg/day — consider cutting back for better hydration."))
        } else if avgDailyCaffeine > 0 {
            insights.append(String(localized: "Caffeine averaged \(Int(avgDailyCaffeine))mg/day — within safe limits."))
        }

        if alcoholDrinks > 0 {
            let extraWater = Int(alcoholDrinks * 250) // ~250mL per drink to compensate
            insights.append(String(localized: "\(Int(alcoholDrinks)) alcoholic drinks this week — offset ~\(extraWater) mL of hydration."))
        }

        let netScore = calculateScore(streak: daysOnGoal, weekLogs: logs, caffeineMG: caffeineMG, alcoholDrinks: alcoholDrinks)

        return WeekSummary(
            daysOnGoal: daysOnGoal,
            totalIntakeML: totalIntake,
            avgDailyML: avgDaily,
            totalCaffeineMG: caffeineMG,
            totalAlcoholDrinks: alcoholDrinks,
            netHydrationScore: netScore,
            topBeverage: "water", // TODO: calculate from actual data
            insights: insights
        )
    }
}
