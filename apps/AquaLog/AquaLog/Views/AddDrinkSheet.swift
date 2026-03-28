import SwiftUI

struct AddDrinkSheet: View {
    @Environment(\.dismiss) private var dismiss

    let onAdd: (Int, String, String?) -> Void

    @State private var amountText: String = "250"
    @State private var selectedBeverage: Beverage = .water
    @State private var note: String = ""

    private var amountValue: Int {
        Int(amountText) ?? 0
    }

    private var isValid: Bool {
        amountValue > 0 && amountValue <= 5000
    }

    var body: some View {
        NavigationStack {
            Form {
                amountSection
                beverageSection
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
                        onAdd(amountValue, selectedBeverage.rawValue, trimmedNote.isEmpty ? nil : trimmedNote)
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

                Text(String(localized: "ml"))
                    .foregroundStyle(.secondary)
                    .font(.title3)
            }

            // Preset row
            HStack(spacing: 10) {
                ForEach(selectedBeverage.quickAmounts, id: \.self) { amount in
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

    // MARK: - Beverage Section

    private var beverageSection: some View {
        Section {
            LazyVGrid(columns: [
                GridItem(.adaptive(minimum: 70), spacing: 10)
            ], spacing: 10) {
                ForEach(Beverage.allCases) { beverage in
                    Button {
                        selectedBeverage = beverage
                    } label: {
                        VStack(spacing: 4) {
                            Image(systemName: beverage.icon)
                                .font(.title3)
                            Text(beverage.displayName)
                                .font(.caption2)
                                .lineLimit(1)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(
                                    selectedBeverage == beverage
                                        ? Color.accentColor
                                        : Color(.systemGray6)
                                )
                        )
                        .foregroundStyle(
                            selectedBeverage == beverage ? .white : .primary
                        )
                    }
                    .accessibilityLabel(String(localized: "Beverage type: \(beverage.displayName)"))
                    .accessibilityAddTraits(selectedBeverage == beverage ? .isSelected : [])
                }
            }
        } header: {
            Text(String(localized: "Beverage"))
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
}

#Preview {
    AddDrinkSheet { amount, type, note in
        print("Added \(amount) ml of \(type), note: \(note ?? "none")")
    }
}
