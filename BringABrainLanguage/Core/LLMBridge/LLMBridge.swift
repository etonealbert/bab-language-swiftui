import Foundation

#if canImport(FoundationModels)
import FoundationModels
#endif

enum LLMAvailability: Equatable {
    case available
    case notSupported
    case modelNotReady
    case unknown
}

enum LLMBridgeError: Error, LocalizedError {
    case sessionNotInitialized
    case generationFailed(String)
    case notSupported
    
    var errorDescription: String? {
        switch self {
        case .sessionNotInitialized:
            return "LLM session not initialized"
        case .generationFailed(let message):
            return "Generation failed: \(message)"
        case .notSupported:
            return "On-device LLM not supported on this device"
        }
    }
}

final class LLMBridge {
    
    #if canImport(FoundationModels)
    @available(iOS 26.0, *)
    private var session: LanguageModelSession?
    #endif
    
    private var isInitialized = false
    private var currentSystemPrompt: String = ""
    
    func checkAvailability() -> LLMAvailability {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *) {
            let availability = SystemLanguageModel.default.availability
            switch availability {
            case .available:
                return .available
            case .unavailable(.deviceNotSupported):
                return .notSupported
            case .unavailable(.modelNotReady):
                return .modelNotReady
            default:
                return .unknown
            }
        }
        #endif
        return .notSupported
    }
    
    func initialize(systemPrompt: String) async -> Bool {
        let availability = checkAvailability()
        guard availability == .available else {
            return availability != .notSupported
        }
        
        currentSystemPrompt = systemPrompt
        
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *) {
            do {
                let instructions = Instructions {
                    systemPrompt
                }
                session = LanguageModelSession(
                    model: .default,
                    instructions: instructions
                )
                isInitialized = true
                return true
            } catch {
                return false
            }
        }
        #endif
        
        return false
    }
    
    func initializeForLanguageLearning(
        targetLanguage: String,
        nativeLanguage: String,
        scenario: String,
        userRole: String,
        aiRole: String
    ) async -> Bool {
        let systemPrompt = """
        You are a language learning assistant playing the role of \(aiRole) in a \(scenario) scenario.
        The user is playing \(userRole).
        
        RULES:
        1. Respond primarily in \(targetLanguage)
        2. Keep responses concise (1-3 sentences)
        3. Stay in character as \(aiRole)
        4. If the user makes a grammar mistake, gently correct it
        5. For difficult words, include a brief hint in \(nativeLanguage) in parentheses
        """
        return await initialize(systemPrompt: systemPrompt)
    }
    
    func generate(prompt: String) async throws -> String {
        guard isInitialized else {
            throw LLMBridgeError.sessionNotInitialized
        }
        
        guard checkAvailability() == .available else {
            throw LLMBridgeError.notSupported
        }
        
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *) {
            guard let session = session else {
                throw LLMBridgeError.sessionNotInitialized
            }
            
            do {
                let response = try await session.respond(to: prompt)
                return response.content
            } catch {
                throw LLMBridgeError.generationFailed(error.localizedDescription)
            }
        }
        #endif
        
        throw LLMBridgeError.notSupported
    }
    
    func generateStream(
        prompt: String,
        onToken: @escaping (String) -> Void
    ) async throws {
        guard isInitialized else {
            throw LLMBridgeError.sessionNotInitialized
        }
        
        guard checkAvailability() == .available else {
            throw LLMBridgeError.notSupported
        }
        
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *) {
            guard let session = session else {
                throw LLMBridgeError.sessionNotInitialized
            }
            
            do {
                let stream = session.streamResponse(to: prompt)
                for try await partial in stream {
                    await MainActor.run {
                        onToken(partial.content)
                    }
                }
            } catch {
                throw LLMBridgeError.generationFailed(error.localizedDescription)
            }
        }
        #endif
    }
    
    func dispose() {
        isInitialized = false
        currentSystemPrompt = ""
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *) {
            session = nil
        }
        #endif
    }
}
