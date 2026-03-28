import SwiftUI
import StoreKit

/// Reusable paywall template following Apple HIG
/// Customize: features list, colors, pricing display
/// Integrates with StoreKit 2 + RevenueCat
struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss

    let appName: String
    let features: [PaywallFeature]
    let accentColor: Color
    let onRestore: () async -> Void
    let onPurchase: (Product) async -> Void

    @State private var products: [Product] = []
    @State private var selectedProduct: Product?
    @State private var isPurchasing = false
    @State private var showError = false
    @State private var errorMessage = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Text("Unlock \(appName) Pro")
                            .font(.largeTitle.bold())
                        Text("Start your free trial today")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 20)

                    // Features list
                    VStack(alignment: .leading, spacing: 16) {
                        ForEach(features) { feature in
                            HStack(spacing: 14) {
                                Image(systemName: feature.icon)
                                    .font(.title3)
                                    .foregroundStyle(accentColor)
                                    .frame(width: 32)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(feature.title)
                                        .font(.headline)
                                    Text(feature.subtitle)
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                    .padding(.horizontal)

                    // Product options
                    VStack(spacing: 12) {
                        ForEach(products, id: \.id) { product in
                            ProductOptionRow(
                                product: product,
                                isSelected: selectedProduct?.id == product.id,
                                accentColor: accentColor
                            )
                            .onTapGesture {
                                selectedProduct = product
                            }
                        }
                    }
                    .padding(.horizontal)

                    // Purchase button
                    Button {
                        Task { await purchase() }
                    } label: {
                        Group {
                            if isPurchasing {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Text("Start Free Trial")
                                    .font(.headline)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(accentColor)
                    .disabled(selectedProduct == nil || isPurchasing)
                    .padding(.horizontal)

                    // Legal text
                    VStack(spacing: 4) {
                        if let product = selectedProduct {
                            Text("7-day free trial, then \(product.displayPrice)/\(product.subscription?.subscriptionPeriod.unit == .month ? "month" : "year")")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Button("Restore Purchases") {
                            Task { await onRestore() }
                        }
                        .font(.caption)

                        HStack(spacing: 16) {
                            Link("Terms of Use", destination: URL(string: "https://example.com/terms")!)
                            Link("Privacy Policy", destination: URL(string: "https://example.com/privacy")!)
                        }
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    }
                    .padding(.bottom, 20)
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK") {}
            } message: {
                Text(errorMessage)
            }
            .task {
                await loadProducts()
            }
        }
    }

    private func loadProducts() async {
        // Replace with your product IDs
        do {
            products = try await Product.products(for: [
                "com.yourapp.monthly",
                "com.yourapp.yearly"
            ])
            selectedProduct = products.first { $0.subscription?.subscriptionPeriod.unit == .year }
                ?? products.first
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }

    private func purchase() async {
        guard let product = selectedProduct else { return }
        isPurchasing = true
        await onPurchase(product)
        isPurchasing = false
    }
}

struct PaywallFeature: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let subtitle: String
}

struct ProductOptionRow: View {
    let product: Product
    let isSelected: Bool
    let accentColor: Color

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(product.displayName)
                    .font(.headline)
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
                .stroke(isSelected ? accentColor : .secondary.opacity(0.3), lineWidth: isSelected ? 2 : 1)
                .fill(isSelected ? accentColor.opacity(0.05) : .clear)
        }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
