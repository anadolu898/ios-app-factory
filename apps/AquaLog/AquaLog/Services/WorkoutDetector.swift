import Foundation
import HealthKit

/// Detects recent HealthKit workouts and calculates extra hydration needed
/// Source: ACSM fluid replacement guidelines — 400-800mL/hour during exercise
@MainActor
final class WorkoutDetector {
    static let shared = WorkoutDetector()
    private let healthStore = HKHealthStore()
    private init() {}

    struct WorkoutHydrationAdvice {
        let workoutType: String
        let durationMinutes: Int
        let caloriesBurned: Int
        let extraWaterML: Int
        let message: String
    }

    /// Check for workouts completed today and return hydration advice
    func checkTodayWorkouts() async -> WorkoutHydrationAdvice? {
        guard HKHealthStore.isHealthDataAvailable() else { return nil }

        let workoutType = HKObjectType.workoutType()

        // Check authorization
        let status = healthStore.authorizationStatus(for: workoutType)
        guard status != .notDetermined else { return nil }

        // Request read access if needed
        do {
            try await healthStore.requestAuthorization(toShare: [], read: [workoutType])
        } catch {
            return nil
        }

        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: .now)

        let predicate = HKQuery.predicateForSamples(
            withStart: startOfDay,
            end: .now,
            options: .strictStartDate
        )

        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)

        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: workoutType,
                predicate: predicate,
                limit: 5,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, error in
                guard let workouts = samples as? [HKWorkout], let workout = workouts.first else {
                    continuation.resume(returning: nil)
                    return
                }

                let durationMin = Int(workout.duration / 60)
                let energyType = HKQuantityType(.activeEnergyBurned)
                let caloriesQuantity = workout.statistics(for: energyType)?.sumQuantity()
                let calories = Int(caloriesQuantity?.doubleValue(for: .kilocalorie()) ?? 0)
                let workoutName = Self.workoutName(for: workout.workoutActivityType)

                // ACSM guidelines: 400-800mL per hour of exercise
                // We use 500mL/hour as a conservative middle ground
                // Plus extra for high-calorie workouts
                let baseML = Int(Double(durationMin) / 60.0 * 500.0)
                let calorieBonus = calories > 300 ? 200 : 0
                let extraML = max(150, baseML + calorieBonus) // Minimum 150mL

                let message = String(localized: "You did \(durationMin) min of \(workoutName) — drink \(extraML) mL extra to replace sweat loss")

                let advice = WorkoutHydrationAdvice(
                    workoutType: workoutName,
                    durationMinutes: durationMin,
                    caloriesBurned: calories,
                    extraWaterML: extraML,
                    message: message
                )

                continuation.resume(returning: advice)
            }

            healthStore.execute(query)
        }
    }

    private nonisolated static func workoutName(for type: HKWorkoutActivityType) -> String {
        switch type {
        case .running: String(localized: "running")
        case .cycling: String(localized: "cycling")
        case .swimming: String(localized: "swimming")
        case .walking: String(localized: "walking")
        case .hiking: String(localized: "hiking")
        case .yoga: String(localized: "yoga")
        case .functionalStrengthTraining, .traditionalStrengthTraining: String(localized: "strength training")
        case .highIntensityIntervalTraining: String(localized: "HIIT")
        case .dance: String(localized: "dance")
        case .soccer: String(localized: "soccer")
        case .basketball: String(localized: "basketball")
        case .tennis: String(localized: "tennis")
        default: String(localized: "exercise")
        }
    }
}
