import Foundation

#if canImport(FoundationModels)
import FoundationModels
#endif

@available(iOS 26.0, *)
actor IOSLLMBridge {
    private var session: LanguageModelSession?
    
    func generateHint(forContext context: String) async throws -> String {
        #if canImport(FoundationModels)
        let model = SystemLanguageModel.default
        guard model.isAvailable else {
            throw LLMError.modelUnavailable
        }
        
        if session == nil {
            session = LanguageModelSession()
        }
        
        let prompt = "You are a language learning assistant. Given this conversation context, provide a brief hint: \(context)"
        let response = try await session?.respond(to: prompt)
        return response?.content ?? ""
        #else
        throw LLMError.notSupported
        #endif
    }
    
    func clearSession() {
        session = nil
    }
}

enum LLMError: Error {
    case modelUnavailable
    case notSupported
}
