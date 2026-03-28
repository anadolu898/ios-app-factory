import Foundation
import SwiftData

@Model
final class WaterLog {
    var id: UUID
    var amount: Int // milliliters
    var beverageType: String // "water", "tea", "coffee", etc.
    var timestamp: Date
    var note: String?

    init(
        amount: Int,
        beverageType: String = "water",
        timestamp: Date = .now,
        note: String? = nil
    ) {
        self.id = UUID()
        self.amount = amount
        self.beverageType = beverageType
        self.timestamp = timestamp
        self.note = note
    }
}
