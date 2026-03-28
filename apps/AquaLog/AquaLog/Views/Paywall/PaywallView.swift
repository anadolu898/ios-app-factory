import SwiftUI
import StoreKit

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedProduct: Product?
    @State private var isPurchasing = false
    @State private var showError = false
    @State private var errorMessage = ""

    private var storeManager: StoreManager { .shared }

    private let features: [(icon: String, title: String, subtitle: String)] = [
        ("chart.bar.fill", String(localized: "Detailed Analytics"), String(localized: "Weekly and monthly charts to track your habits")),
        ("drop.degreesign.fill", String(localized: "Custom Beverages"), String(localized: "Track tea, coffee, juice and more")),
        ("square.and.arrow.up.fill", String(localized: "Export Data"), String(localized: "Export your hydration history as CSV")),
        ("widget.small.badge.plus", String(localized: "All Widgets"), String(localized: "Multiple widget sizes for your Home Screen")),
        ("bell.badge.fill", String(localized: "Smart Reminders"), String(localized: "Customizable reminder schedule"))
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    headerSection
                    featuresSection
                    productsSection
                    purchaseButton
                    legalSection
                }
                .padding()
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                            .font(.title3)
                    }
                    .accessibilityLabel(String(localized: "Close"))
                }
            }
            .alert(String(localized: "Error"), isPresented: $showError) {
                Button(String(localized: "OK")) {}
            } message: {
                Text(errorMessage)
            }
            .task {
                await storeManager.loadProducts()
                selectedProduct = storeManager.yearlyProduct ?? storeManager.monthlyProduct
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 8) {
            Image(systemName: "drop.fill")
                .font(.system(size: 50))
                .foregroundStyle(Color.accentColor)
                .symbolEffect(.bounce, value: true)

            Text(String(localized: "AquaLog Pro"))
                .font(.largeTitle.bold())

            Text(String(localized: "Unlock the full hydration experience"))
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.top, 20)
    }

    // MARK: - Features

    private var featuresSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            ForEach(features, id: \.title) { feature in
                HStack(spacing: 14) {
                    Image(systemName: feature.icon)
                        .font(.title3)
                        .foregroundStyle(Color.accentColor)
                        .frame(width: 32)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(feature.title)
                            .font(.subheadline.weight(.semibold))
                        Text(feature.subtitle)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.regularMaterial)
        )
    }

    // MARK: - Products

    private var productsSection: some View {
        VStack(spacing: 12) {
            ForEach(storeManager.products, id: \.id) { product in
                productRow(product)
            }
        }
    }

    private func productRow(_ product: Product) -> some View {
        Button {
            selectedProduct = product
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text(product.displayName)
                            .font(.headline)
                        if product.id == StoreManager.yearlyID {
                            Text(String(localized: "Best Value"))
                                .font(.caption2.weight(.bold))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Color.accentColor)
                                .foregroundStyle(.white)
                                .clipShape(Capsule())
                        }
                    }
                    Text(product.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Text(product.displayPrice)
                    .font(.headline)
            }
            .padding()
            .background {
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        selectedProduct?.id == product.id ? Color.accentColor : .secondary.opacity(0.3),
                        lineWidth: selectedProduct?.id == product.id ? 2 : 1
                    )
                    .fill(selectedProduct?.id == product.id ? Color.accentColor.opacity(0.05) : .clear)
            }
            .foregroundStyle(.primary)
        }
        .accessibilityAddTraits(selectedProduct?.id == product.id ? .isSelected : [])
    }

    // MARK: - Purchase Button

    private var purchaseButton: some View {
        Button {
            Task { await purchase() }
        } label: {
            Group {
                if isPurchasing {
                    ProgressView()
                        .tint(.white)
                } else {
                    Text(String(localized: "Start Free Trial"))
                        .font(.headline)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
        }
        .buttonStyle(.borderedProminent)
        .tint(Color.accentColor)
        .disabled(selectedProduct == nil || isPurchasing)
    }

    // MARK: - Legal

    private var legalSection: some View {
        VStack(spacing: 8) {
            if let product = selectedProduct {
                Text(String(localized: "7-day free trial, then \(product.displayPrice)/\(product.id.contains("yearly") ? String(localized: "year") : String(localized: "month"))"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Button(String(localized: "Restore Purchases")) {
                Task { await storeManager.restorePurchases() }
            }
            .font(.caption)

            Text(String(localized: "Payment will be charged to your Apple ID account. Subscription automatically renews unless cancelled at least 24 hours before the end of the current period."))
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
        }
        .padding(.bottom, 20)
    }

    // MARK: - Actions

    private func purchase() async {
        guard let product = selectedProduct else { return }
        isPurchasing = true
        do {
            let success = try await storeManager.purchase(product)
            if success {
                dismiss()
            }
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
        isPurchasing = false
    }
}

#Preview {
    PaywallView()
}
