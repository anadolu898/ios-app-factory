import Foundation
import HealthKit

@MainActor
final class HealthKitManager {
    static let shared = HealthKitManager()

    private let healthStore = HKHealthStore()
    private let waterType = HKQuantityType(.dietaryWater)

    var isAvailable: Bool {
        HKHealthStore.isHealthDataAvailable()
    }

    private init() {}

    // MARK: - Authorization

    func requestAuthorization() async -> Bool {
        guard isAvailable else { return false }

        do {
            try await healthStore.requestAuthorization(
                toShare: [waterType],
                read: [waterType]
            )
            return true
        } catch {
            return false
        }
    }

    func authorizationStatus() -> HKAuthorizationStatus {
        healthStore.authorizationStatus(for: waterType)
    }

    // MARK: - Write

    func saveWaterIntake(milliliters: Int, date: Date = .now) async -> Bool {
        guard isAvailable else { return false }

        let quantity = HKQuantity(unit: .literUnit(with: .milli), doubleValue: Double(milliliters))
        let sample = HKQuantitySample(
            type: waterType,
            quantity: quantity,
            start: date,
            end: date
        )

        do {
            try await healthStore.save(sample)
            return true
        } catch {
            return false
        }
    }

    // MARK: - Read

    func todayWaterIntake() async -> Int {
        guard isAvailable else { return 0 }

        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: .now)
        let predicate = HKQuery.predicateForSamples(
            withStart: startOfDay,
            end: .now,
            options: .strictStartDate
        )

        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: waterType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, result, _ in
                let ml = result?.sumQuantity()?.doubleValue(for: .literUnit(with: .milli)) ?? 0
                continuation.resume(returning: Int(ml))
            }
            healthStore.execute(query)
        }
    }
}
