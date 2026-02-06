import StoreKit
import SwiftUI

@MainActor
final class SubscriptionManager: ObservableObject {
    
    static let shared = SubscriptionManager()
    
    @Published private(set) var subscriptionStatus: AppSubscriptionStatus = .unknown
    @Published private(set) var availableProducts: [Product] = []
    @Published private(set) var isLoading: Bool = false
    
    private let productIDs = [
        "com.bablabs.bringabrain.monthly",
        "com.bablabs.bringabrain.yearly"
    ]
    
    #if DEBUG
    var isMockedPremium: Bool = false {
        didSet {
            subscriptionStatus = isMockedPremium ? .subscribed : .notSubscribed
            notifyStatusChange()
        }
    }
    #endif
    
    private init() {
        Task {
            await loadProducts()
            await updateSubscriptionStatus()
            await listenForTransactions()
        }
    }
    
    func loadProducts() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            availableProducts = try await Product.products(for: productIDs)
                .sorted { $0.price < $1.price }
        } catch {
            print("Failed to load products: \(error)")
        }
    }
    
    func purchase(_ product: Product) async throws -> Bool {
        let result = try await product.purchase()
        
        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            await transaction.finish()
            await updateSubscriptionStatus()
            return true
            
        case .userCancelled:
            return false
            
        case .pending:
            return false
            
        @unknown default:
            return false
        }
    }
    
    func restorePurchases() async {
        do {
            try await AppStore.sync()
        } catch {
            print("Failed to sync AppStore: \(error)")
        }
        await updateSubscriptionStatus()
    }
    
    func updateSubscriptionStatus() async {
        #if DEBUG
        if isMockedPremium {
            subscriptionStatus = .subscribed
            notifyStatusChange()
            return
        }
        #endif
        
        var hasActiveSubscription = false
        
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result {
                if productIDs.contains(transaction.productID) {
                    hasActiveSubscription = true
                    break
                }
            }
        }
        
        subscriptionStatus = hasActiveSubscription ? .subscribed : .notSubscribed
        notifyStatusChange()
    }
    
    private func listenForTransactions() async {
        for await result in Transaction.updates {
            if case .verified(let transaction) = result {
                await transaction.finish()
                await updateSubscriptionStatus()
            }
        }
    }
    
    private func notifyStatusChange() {
        NotificationCenter.default.post(
            name: .subscriptionStatusChanged,
            object: subscriptionStatus
        )
    }
    
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw SubscriptionError.verificationFailed
        case .verified(let safe):
            return safe
        }
    }
}

extension Notification.Name {
    static let subscriptionStatusChanged = Notification.Name("SubscriptionStatusChanged")
}
