import Testing
@testable import BringABrainLanguage

@Suite("SubscriptionManager Tests")
struct SubscriptionManagerTests {
    
    @Test("Singleton instance exists")
    func testSingletonExists() async throws {
        let manager = await SubscriptionManager.shared
        #expect(manager != nil)
    }
    
    #if DEBUG
    @Test("Mock premium mode toggles subscription status")
    func testMockPremiumMode() async throws {
        let manager = await SubscriptionManager.shared
        
        await manager.setMockedPremium(false)
        let statusBefore = await manager.subscriptionStatus
        #expect(statusBefore == .notSubscribed)
        
        await manager.setMockedPremium(true)
        let statusAfter = await manager.subscriptionStatus
        #expect(statusAfter == .subscribed)
    }
    #endif
}

extension SubscriptionManager {
    #if DEBUG
    func setMockedPremium(_ value: Bool) {
        isMockedPremium = value
    }
    #endif
}
