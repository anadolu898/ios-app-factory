import SwiftUI

struct AddDrinkSheet: View {
    @Environment(\.dismiss) private var dismiss

    let onAdd: (Int, String, String?) -> Void

    @State private var amountText: String = "250"
    @State private var selectedProfile: NutrientDatabase.BeverageProfile = NutrientDatabase.beverages[0]
    @State private var selectedCategory: NutrientDatabase.BeverageProfile.Category = .water
    @State private var note: String = ""

    private var amountValue: Int {
        Int(amountText) ?? 0
    }

    private var isValid: Bool {
        amountValue > 0 && amountValue <= 5000
    }

    private var netHydration: NutrientDatabase.NetHydrationResult {
        NutrientDatabase.netHydration(beverageId: selectedProfile.id, volumeML: amountValue)
    }

    private var quickAmounts: [Int] {
        let bev = Beverage(rawValue: selectedProfile.id)
        return bev?.quickAmounts ?? [150, 250, 350, 500]
    }

    var body: some View {
        NavigationStack {
            Form {
                amountSection
                categorySection
                beverageSection
                hydrationInsightSection
                noteSection
            }
            .navigationTitle(String(localized: "Add Drink"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "Cancel")) {
                        dismiss()
                    }
                    .accessibilityLabel(String(localized: "Cancel adding drink"))
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(String(localized: "Add")) {
                        let trimmedNote = note.trimmingCharacters(in: .whitespacesAndNewlines)
                        onAdd(amountValue, selectedProfile.id, trimmedNote.isEmpty ? nil : trimmedNote)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .disabled(!isValid)
                    .accessibilityLabel(String(localized: "Add drink"))
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    // MARK: - Amount Section

    private var amountSection: some View {
        Section {
            HStack {
                TextField(String(localized: "Amount"), text: $amountText)
                    .keyboardType(.numberPad)
                    .font(.title2.weight(.semibold))
                    .accessibilityLabel(String(localized: "Drink amount in milliliters"))

                Text(String(localized: "mL"))
                    .foregroundStyle(.secondary)
                    .font(.title3)
            }

            HStack(spacing: 10) {
                ForEach(quickAmounts, id: \.self) { amount in
                    Button {
                        amountText = "\(amount)"
                    } label: {
                        Text("\(amount)")
                            .font(.caption.weight(.medium))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                Capsule()
                                    .fill(
                                        amountValue == amount
                                            ? Color.accentColor
                                            : Color.accentColor.opacity(0.12)
                                    )
                            )
                            .foregroundStyle(
                                amountValue == amount ? .white : Color.accentColor
                            )
                    }
                    .accessibilityLabel(String(localized: "\(amount) milliliters"))
                }
            }
        } header: {
            Text(String(localized: "Amount"))
        }
    }

    // MARK: - Category Filter

    private var categorySection: some View {
        Section {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(NutrientDatabase.BeverageProfile.Category.allCases, id: \.rawValue) { cat in
                        Button {
                            selectedCategory = cat
                            // Auto-select first in category
                            if let first = NutrientDatabase.beverages(in: cat).first {
                                selectedProfile = first
                            }
                        } label: {
                            Text(categoryName(cat))
                                .font(.caption.weight(.medium))
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(
                                    Capsule()
                                        .fill(selectedCategory == cat ? Color.accentColor : Color(.systemGray6))
                                )
                                .foregroundStyle(selectedCategory == cat ? .white : .primary)
                        }
                        .accessibilityAddTraits(selectedCategory == cat ? .isSelected : [])
                    }
                }
            }
        } header: {
            Text(String(localized: "Category"))
        }
    }

    // MARK: - Beverage Grid

    private var beverageSection: some View {
        Section {
            let filtered = NutrientDatabase.beverages(in: selectedCategory)
            LazyVGrid(columns: [
                GridItem(.adaptive(minimum: 80), spacing: 10)
            ], spacing: 10) {
                ForEach(filtered, id: \.id) { profile in
                    Button {
                        selectedProfile = profile
                    } label: {
                        VStack(spacing: 4) {
                            Image(systemName: profile.icon)
                                .font(.title3)
                            Text(profile.displayName)
                                .font(.caption2)
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)

                            if !profile.isFree && !StoreManager.shared.isPremium {
                                Image(systemName: "lock.fill")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(
                                    selectedProfile.id == profile.id
                                        ? Color.accentColor
                                        : Color(.systemGray6)
                                )
                        )
                        .foregroundStyle(
                            selectedProfile.id == profile.id ? .white : .primary
                        )
                    }
                    .accessibilityLabel(String(localized: "\(profile.displayName)"))
                    .accessibilityAddTraits(selectedProfile.id == profile.id ? .isSelected : [])
                }
            }
        } header: {
            Text(String(localized: "Beverage"))
        }
    }

    // MARK: - Hydration Insight (the smart part)

    private var hydrationInsightSection: some View {
        Section {
            if amountValue > 0 {
                // Net hydration
                HStack {
                    Image(systemName: "drop.fill")
                        .foregroundStyle(.blue)
                    Text(String(localized: "Net Hydration"))
                        .font(.subheadline)
                    Spacer()
                    Text("\(netHydration.netML) mL")
                        .font(.subheadline.weight(.semibold).monospacedDigit())
                        .foregroundStyle(netHydration.netML < amountValue ? .orange : .green)
                }
                .accessibilityElement(children: .combine)

                if netHydration.waterDebt > 0 {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                        Text(String(localized: "Drink \(netHydration.waterDebt) mL extra water to compensate"))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                // Factor breakdown
                ForEach(netHydration.factors, id: \.self) { factor in
                    HStack {
                        Image(systemName: "info.circle")
                            .foregroundStyle(.secondary)
                            .font(.caption)
                        Text(factor)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                // Caffeine info
                if selectedProfile.caffeineMgPer250mL > 0 {
                    let caffeine = selectedProfile.caffeineMgPer250mL * (Double(amountValue) / 250.0)
                    HStack {
                        Image(systemName: "mug.fill")
                            .foregroundStyle(.brown)
                        Text(String(localized: "Caffeine"))
                            .font(.subheadline)
                        Spacer()
                        Text("\(Int(caffeine)) mg")
                            .font(.subheadline.weight(.semibold).monospacedDigit())
                    }
                }

                // Calories
                if selectedProfile.caloriesPer250mL > 0 {
                    let calories = selectedProfile.caloriesPer250mL * (Double(amountValue) / 250.0)
                    HStack {
                        Image(systemName: "flame")
                            .foregroundStyle(.red)
                        Text(String(localized: "Calories"))
                            .font(.subheadline)
                        Spacer()
                        Text("\(Int(calories)) kcal")
                            .font(.subheadline.weight(.semibold).monospacedDigit())
                    }
                }

                // Sugar info
                if selectedProfile.sugarGramsPer250mL > 0 {
                    let sugar = selectedProfile.sugarGramsPer250mL * (Double(amountValue) / 250.0)
                    HStack {
                        Image(systemName: "cube.fill")
                            .foregroundStyle(.pink)
                        Text(String(localized: "Sugar"))
                            .font(.subheadline)
                        Spacer()
                        Text(String(format: "%.0fg", sugar))
                            .font(.subheadline.weight(.semibold).monospacedDigit())
                    }
                }

                // Alcohol impact
                if selectedProfile.alcoholABV > 0 {
                    let alcoholImpact = AlcoholCalculator.shared.calculateImpact(
                        beverageId: selectedProfile.id,
                        volumeML: amountValue,
                        weightKg: 70, // Default — real value from settings in production
                        gender: .other
                    )

                    Divider()

                    HStack {
                        Image(systemName: "wineglass.fill")
                            .foregroundStyle(.purple)
                        Text(String(localized: "Alcohol"))
                            .font(.subheadline.weight(.semibold))
                        Spacer()
                        Text(String(format: "%.1f drinks", alcoholImpact.standardDrinks))
                            .font(.subheadline.weight(.semibold).monospacedDigit())
                            .foregroundStyle(.purple)
                    }

                    HStack {
                        Image(systemName: "drop.triangle.fill")
                            .foregroundStyle(.red)
                        Text(String(localized: "Extra water needed"))
                            .font(.caption)
                        Spacer()
                        Text("\(alcoholImpact.dehydrationML) mL")
                            .font(.caption.weight(.semibold).monospacedDigit())
                            .foregroundStyle(.red)
                    }

                    if alcoholImpact.recoveryTimeHours > 0 {
                        HStack {
                            Image(systemName: "clock.fill")
                                .foregroundStyle(.orange)
                            Text(String(localized: "Recovery time"))
                                .font(.caption)
                            Spacer()
                            Text(String(format: "%.1f hrs", alcoholImpact.recoveryTimeHours))
                                .font(.caption.weight(.semibold).monospacedDigit())
                        }
                    }
                }
            }
        } header: {
            Text(String(localized: "Hydration Intelligence"))
        }
    }

    // MARK: - Note Section

    private var noteSection: some View {
        Section {
            TextField(String(localized: "Optional note..."), text: $note, axis: .vertical)
                .lineLimit(2...4)
                .accessibilityLabel(String(localized: "Add an optional note"))
        } header: {
            Text(String(localized: "Note"))
        }
    }

    // MARK: - Helpers

    private func categoryName(_ cat: NutrientDatabase.BeverageProfile.Category) -> String {
        switch cat {
        case .water: String(localized: "Water")
        case .hotDrink: String(localized: "Hot Drinks")
        case .juice: String(localized: "Juice")
        case .soda: String(localized: "Soda")
        case .milk: String(localized: "Milk")
        case .alcohol: String(localized: "Alcohol")
        case .sports: String(localized: "Sports")
        }
    }
}

#Preview {
    AddDrinkSheet { amount, type, note in
        print("Added \(amount) ml of \(type), note: \(note ?? "none")")
    }
}
