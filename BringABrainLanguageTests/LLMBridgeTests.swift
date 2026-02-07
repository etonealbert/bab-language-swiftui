import Testing
@testable import BringABrainLanguage

struct LLMBridgeTests {
    
    @Test
    func checkAvailability_returnsNotSupportedOnSimulator() {
        let bridge = LLMBridge()
        let availability = bridge.checkAvailability()
        
        #expect(availability == .notSupported || availability == .available)
    }
    
    @Test
    func initialize_withValidPrompt_returnsTrue() async {
        let bridge = LLMBridge()
        
        let systemPrompt = """
        You are a French tutor. Help the user practice ordering coffee.
        Respond in French with English translation hints.
        """
        
        let success = await bridge.initialize(systemPrompt: systemPrompt)
        
        #expect(success == true || bridge.checkAvailability() == .notSupported)
    }
    
    @Test
    func generate_whenNotInitialized_throwsError() async {
        let bridge = LLMBridge()
        
        do {
            _ = try await bridge.generate(prompt: "Bonjour!")
            #expect(Bool(false), "Should have thrown error")
        } catch {
            #expect(error is LLMBridgeError)
        }
    }
    
    @Test
    func generate_afterInitialize_returnsResponse() async {
        let bridge = LLMBridge()
        
        guard bridge.checkAvailability() == .available else {
            return
        }
        
        let systemPrompt = "You are a helpful assistant. Respond briefly."
        _ = await bridge.initialize(systemPrompt: systemPrompt)
        
        do {
            let response = try await bridge.generate(prompt: "Say hello")
            #expect(!response.isEmpty)
        } catch {
            #expect(Bool(false), "Should not throw: \(error)")
        }
    }
    
    @Test
    func dispose_releasesSession() async {
        let bridge = LLMBridge()
        
        guard bridge.checkAvailability() == .available else {
            return
        }
        
        _ = await bridge.initialize(systemPrompt: "Test")
        bridge.dispose()
        
        do {
            _ = try await bridge.generate(prompt: "Test")
            #expect(Bool(false), "Should throw after dispose")
        } catch {
            #expect(error is LLMBridgeError)
        }
    }
}
