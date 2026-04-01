import Foundation
import RevenueCat

@Observable @MainActor
final class StoreManager {
    static let shared = StoreManager()

    private(set) var offerings: Offerings?
    var customerInfo: CustomerInfo?
    private(set) var isLoading = false

    var isPremium: Bool {
        customerInfo?.entitlements["premium"]?.isActive ?? false
    }

    static let monthlyID = "com.rightbehind.aqualog.premium.monthly"
    static let yearlyID = "com.rightbehind.aqualog.premium.yearly"
    static let lifetimeID = "com.rightbehind.aqualog.premium.lifetime"

    // MARK: - RevenueCat API Key (set from App Store Connect)
    // Note: This is the test store key. Replace with production key before App Store submission.
    static let revenueCatAPIKey = "test_POltyIflbVGdOekYPBLJpizrfni"

    private init() {}

    // MARK: - Configuration (call from App init)

    func configure() {
        Purchases.logLevel = .error
        Purchases.configure(withAPIKey: Self.revenueCatAPIKey)
        Purchases.shared.delegate = RevenueCatDelegate.shared
        Task { await loadOfferings() }
        Task { await refreshCustomerInfo() }
    }

    // MARK: - Load Offerings

    func loadOfferings() async {
        isLoading = true
        do {
            offerings = try await Purchases.shared.offerings()
        } catch {
            offerings = nil
        }
        isLoading = false
    }

    // MARK: - Products from Offerings

    var products: [Package] {
        offerings?.current?.availablePackages ?? []
    }

    var monthlyPackage: Package? {
        offerings?.current?.monthly
    }

    var yearlyPackage: Package? {
        offerings?.current?.annual
    }

    var lifetimePackage: Package? {
        offerings?.current?.lifetime
    }

    // MARK: - Purchase

    func purchase(_ package: Package) async throws -> Bool {
        do {
            let result = try await Purchases.shared.purchase(package: package)
            customerInfo = result.customerInfo
            return !result.userCancelled
        } catch {
            throw error
        }
    }

    // MARK: - Restore

    func restorePurchases() async {
        do {
            customerInfo = try await Purchases.shared.restorePurchases()
        } catch {
            // Restore failed
        }
    }

    // MARK: - Refresh

    func refreshCustomerInfo() async {
        do {
            customerInfo = try await Purchases.shared.customerInfo()
        } catch {
            customerInfo = nil
        }
    }
}

// MARK: - RevenueCat Delegate

final class RevenueCatDelegate: NSObject, PurchasesDelegate, @unchecked Sendable {
    static let shared = RevenueCatDelegate()

    nonisolated func purchases(_ purchases: Purchases, receivedUpdated customerInfo: CustomerInfo) {
        Task { @MainActor in
            StoreManager.shared.customerInfo = customerInfo
        }
    }
}
