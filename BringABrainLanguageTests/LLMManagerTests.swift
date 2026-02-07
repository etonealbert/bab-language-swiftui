import XCTest
@testable import BringABrainLanguage

final class LLMManagerTests: XCTestCase {
    
    var manager: LLMManager!
    
    override func setUp() {
        super.setUp()
        manager = LLMManager.shared
        manager.reset()
    }
    
    override func tearDown() {
        manager.reset()
        super.tearDown()
    }
    
    // MARK: - Singleton Tests
    
    func test_shared_returnsSameInstance() {
        let instance1 = LLMManager.shared
        let instance2 = LLMManager.shared
        XCTAssertTrue(instance1 === instance2, "Shared should return same instance")
    }
    
    // MARK: - Initialization Tests
    
    func test_isReady_beforeInitialize_returnsFalse() {
        XCTAssertFalse(manager.isReady, "Should not be ready before initialization")
    }
    
    func test_initialize_setsIsInitializedTrue() async {
        await manager.initialize(
            targetLanguage: "Spanish",
            nativeLanguage: "English",
            scenario: "Cafe",
            userRole: "Customer",
            aiRole: "Barista"
        )
        
        XCTAssertTrue(manager.isInitialized, "Should be initialized after calling initialize")
    }
    
    // MARK: - Memory Pressure Tests
    
    func test_handleMemoryWarning_disposesSession() async {
        await manager.initialize(
            targetLanguage: "French",
            nativeLanguage: "English",
            scenario: "Restaurant",
            userRole: "Guest",
            aiRole: "Waiter"
        )
        XCTAssertTrue(manager.isInitialized)
        
        manager.handleMemoryWarning()
        
        XCTAssertFalse(manager.isReady, "Session should be disposed after memory warning")
        XCTAssertTrue(manager.needsReinitialize, "Should need reinitialization after memory warning")
    }
    
    func test_reinitialize_afterMemoryWarning_restoresSession() async {
        await manager.initialize(
            targetLanguage: "German",
            nativeLanguage: "English",
            scenario: "Airport",
            userRole: "Traveler",
            aiRole: "Agent"
        )
        manager.handleMemoryWarning()
        XCTAssertTrue(manager.needsReinitialize)
        
        await manager.reinitializeIfNeeded()
        
        XCTAssertFalse(manager.needsReinitialize, "Should not need reinit after reinitializing")
        XCTAssertTrue(manager.isInitialized)
    }
    
    // MARK: - Generate Tests
    
    func test_generate_whenNotInitialized_throwsError() async {
        do {
            _ = try await manager.generate(prompt: "Hello")
            XCTFail("Should throw when not initialized")
        } catch let error as LLMManagerError {
            XCTAssertEqual(error, .notInitialized)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    func test_generate_afterMemoryWarning_automaticallyReinitializes() async {
        await manager.initialize(
            targetLanguage: "Italian",
            nativeLanguage: "English",
            scenario: "Market",
            userRole: "Shopper",
            aiRole: "Vendor"
        )
        manager.handleMemoryWarning()
        
        do {
            _ = try await manager.generate(prompt: "Buongiorno")
        } catch {
        }
        
        XCTAssertFalse(manager.needsReinitialize, "Should have attempted reinit during generate")
    }
    
    // MARK: - Configuration Tests
    
    func test_currentConfiguration_returnsLastUsedConfig() async {
        await manager.initialize(
            targetLanguage: "Japanese",
            nativeLanguage: "English",
            scenario: "Train Station",
            userRole: "Tourist",
            aiRole: "Station Staff"
        )
        
        let config = manager.currentConfiguration
        XCTAssertEqual(config?.targetLanguage, "Japanese")
        XCTAssertEqual(config?.nativeLanguage, "English")
        XCTAssertEqual(config?.scenario, "Train Station")
    }
    
    func test_reset_clearsEverything() async {
        await manager.initialize(
            targetLanguage: "Korean",
            nativeLanguage: "English",
            scenario: "Coffee Shop",
            userRole: "Customer",
            aiRole: "Barista"
        )
        
        manager.reset()
        
        XCTAssertFalse(manager.isInitialized)
        XCTAssertFalse(manager.isReady)
        XCTAssertNil(manager.currentConfiguration)
    }
}
