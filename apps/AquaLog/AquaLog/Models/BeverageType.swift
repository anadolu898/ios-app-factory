import SwiftUI

enum Beverage: String, CaseIterable, Identifiable {
    case water
    case tea
    case coffee
    case juice
    case milk
    case soda
    case smoothie
    case custom

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .water: String(localized: "Water")
        case .tea: String(localized: "Tea")
        case .coffee: String(localized: "Coffee")
        case .juice: String(localized: "Juice")
        case .milk: String(localized: "Milk")
        case .soda: String(localized: "Soda")
        case .smoothie: String(localized: "Smoothie")
        case .custom: String(localized: "Custom")
        }
    }

    var icon: String {
        switch self {
        case .water: "drop.fill"
        case .tea: "cup.and.saucer.fill"
        case .coffee: "mug.fill"
        case .juice: "carrot.fill"
        case .milk: "cup.and.saucer.fill"
        case .soda: "bubbles.and.sparkles.fill"
        case .smoothie: "blender.fill"
        case .custom: "plus.circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .water: .blue
        case .tea: .green
        case .coffee: .brown
        case .juice: .orange
        case .milk: .white
        case .soda: .red
        case .smoothie: .purple
        case .custom: .gray
        }
    }

    /// Hydration factor — how much of this beverage counts toward hydration
    var hydrationFactor: Double {
        switch self {
        case .water: 1.0
        case .tea: 0.9
        case .coffee: 0.8
        case .juice: 0.85
        case .milk: 0.9
        case .soda: 0.7
        case .smoothie: 0.85
        case .custom: 1.0
        }
    }

    /// Whether this beverage is available in free tier
    var isFree: Bool {
        self == .water
    }

    /// Quick-add amounts in mL
    var quickAmounts: [Int] {
        switch self {
        case .water: [150, 250, 350, 500]
        case .coffee: [100, 150, 250, 350]
        case .tea: [150, 200, 250, 350]
        default: [150, 250, 350, 500]
        }
    }
}
