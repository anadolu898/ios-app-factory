import SwiftUI
import RevenueCat

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedPackage: Package?
    @State private var isPurchasing = false
    @State private var showError = false
    @State private var errorMessage = ""

    private var storeManager: StoreManager { .shared }

    private let features: [(icon: String, title: String, subtitle: String)] = [
        ("brain.head.profile.fill", String(localized: "Health Timeline"), String(localized: "Research-cited milestones tracking your body's improvement")),
        ("wineglass.fill", String(localized: "Alcohol Calculator"), String(localized: "See dehydration impact, BAC, and recovery time")),
        ("mug.fill", String(localized: "Caffeine Tracker"), String(localized: "Half-life decay curve and sleep impact analysis")),
        ("chart.bar.doc.horizontal", String(localized: "Weekly Body Report"), String(localized: "Net hydration score, trends, and personalized insights")),
        ("square.and.arrow.up.fill", String(localized: "Export Data"), String(localized: "Export your full hydration history as CSV")),
        ("cup.and.saucer.fill", String(localized: "23 Beverages"), String(localized: "Track every drink type with full nutrition data"))
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
                await storeManager.loadOfferings()
                selectedPackage = storeManager.yearlyPackage ?? storeManager.monthlyPackage
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
            ForEach(storeManager.products, id: \.identifier) { package in
                packageRow(package)
            }
        }
    }

    private func packageRow(_ package: Package) -> some View {
        let productID = package.storeProduct.productIdentifier

        return Button {
            selectedPackage = package
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text(package.storeProduct.localizedTitle)
                            .font(.headline)
                        if productID == StoreManager.lifetimeID {
                            Text(String(localized: "Best Deal"))
                                .font(.caption2.weight(.bold))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Color.green)
                                .foregroundStyle(.white)
                                .clipShape(Capsule())
                        } else if productID == StoreManager.yearlyID {
                            Text(String(localized: "Save 58%"))
                                .font(.caption2.weight(.bold))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Color.accentColor)
                                .foregroundStyle(.white)
                                .clipShape(Capsule())
                        }
                    }
                    Text(package.storeProduct.localizedDescription)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Text(package.localizedPriceString)
                    .font(.headline)
            }
            .padding()
            .background {
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        selectedPackage?.identifier == package.identifier ? Color.accentColor : .secondary.opacity(0.3),
                        lineWidth: selectedPackage?.identifier == package.identifier ? 2 : 1
                    )
                    .fill(selectedPackage?.identifier == package.identifier ? Color.accentColor.opacity(0.05) : .clear)
            }
            .foregroundStyle(.primary)
        }
        .accessibilityAddTraits(selectedPackage?.identifier == package.identifier ? .isSelected : [])
    }

    // MARK: - Purchase Button

    private var purchaseButton: some View {
        let isLifetime = selectedPackage?.storeProduct.productIdentifier == StoreManager.lifetimeID

        return Button {
            Task { await purchase() }
        } label: {
            Group {
                if isPurchasing {
                    ProgressView()
                        .tint(.white)
                } else {
                    Text(isLifetime
                         ? String(localized: "Buy Lifetime Access")
                         : String(localized: "Start Free Trial"))
                        .font(.headline)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
        }
        .buttonStyle(.borderedProminent)
        .tint(Color.accentColor)
        .disabled(selectedPackage == nil || isPurchasing)
    }

    // MARK: - Legal

    private var legalSection: some View {
        VStack(spacing: 8) {
            if let package = selectedPackage {
                let isLifetime = package.storeProduct.productIdentifier == StoreManager.lifetimeID
                if isLifetime {
                    Text(String(localized: "One-time payment of \(package.localizedPriceString) — yours forever"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    let isYearly = package.storeProduct.productIdentifier.contains("yearly")
                    Text(String(localized: "7-day free trial, then \(package.localizedPriceString)/\(isYearly ? String(localized: "year") : String(localized: "month"))"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
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
        guard let package = selectedPackage else { return }
        isPurchasing = true
        do {
            let success = try await storeManager.purchase(package)
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
