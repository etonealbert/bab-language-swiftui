import SwiftUI

#if canImport(FoundationModels)
import FoundationModels

@available(iOS 26.0, *)
@Generable
struct TranslationResponse: Codable {
    let translatedWord: String
    let partOfSpeech: String?
    let definition: String?
    let exampleUsage: String?
}

@available(iOS 26.0, *)
@MainActor
class FoundationModelTranslationProvider: ObservableObject {
    @Published var isAvailable = false
    @Published var isLoading = false
    
    private var session: LanguageModelSession?
    
    init() {
        Task {
            await checkAvailability()
        }
    }
    
    func checkAvailability() async {
        let model = SystemLanguageModel.default
        isAvailable = model.isAvailable
    }
    
    func initialize() async throws {
        let model = SystemLanguageModel.default
        guard model.isAvailable else {
            throw TranslationProviderError.modelNotAvailable
        }
        session = LanguageModelSession(model: model)
    }
    
    func translate(
        word: String,
        from sourceLanguage: String,
        to targetLanguage: String,
        context: String?
    ) async throws -> TranslationResponse {
        guard let session = session else {
            throw TranslationProviderError.sessionNotInitialized
        }
        
        isLoading = true
        defer { isLoading = false }
        
        let prompt = buildTranslationPrompt(
            word: word,
            from: sourceLanguage,
            to: targetLanguage,
            context: context
        )
        
        return try await session.respond(to: prompt, generating: TranslationResponse.self)
    }
    
    private func buildTranslationPrompt(
        word: String,
        from sourceLanguage: String,
        to targetLanguage: String,
        context: String?
    ) -> String {
        var prompt = """
        Translate the word "\(word)" from \(sourceLanguage) to \(targetLanguage).
        """
        
        if let context = context {
            prompt += "\nContext: \(context)"
        }
        
        prompt += """
        
        Provide:
        - translatedWord: the translation
        - partOfSpeech: noun, verb, adjective, etc.
        - definition: brief definition in \(targetLanguage)
        - exampleUsage: example sentence using the word
        """
        
        return prompt
    }
    
    func dispose() {
        session = nil
    }
}
#endif

enum TranslationProviderError: LocalizedError {
    case modelNotAvailable
    case sessionNotInitialized
    case translationFailed
    
    var errorDescription: String? {
        switch self {
        case .modelNotAvailable:
            return "Foundation Models not available on this device"
        case .sessionNotInitialized:
            return "Translation session not initialized"
        case .translationFailed:
            return "Translation failed"
        }
    }
}

struct MockWordTranslation {
    let translatedWord: String
    let partOfSpeech: String?
}

@MainActor
class MockTranslationProvider: ObservableObject {
    @Published var isAvailable = true
    @Published var isLoading = false
    
    private let mockTranslations: [String: (translation: String, pos: String)] = [
        "hola": ("hello", "interjection"),
        "buenos": ("good", "adjective"),
        "días": ("days/morning", "noun"),
        "café": ("coffee", "noun"),
        "leche": ("milk", "noun"),
        "por favor": ("please", "phrase"),
        "gracias": ("thank you", "interjection"),
        "qué": ("what", "pronoun"),
        "cómo": ("how", "adverb"),
        "cuánto": ("how much", "adverb")
    ]
    
    func translate(
        word: String,
        from sourceLanguage: String,
        to targetLanguage: String,
        context: String?
    ) async -> MockWordTranslation? {
        isLoading = true
        defer { isLoading = false }
        
        try? await Task.sleep(for: .milliseconds(300))
        
        let normalizedWord = word.lowercased()
            .trimmingCharacters(in: .punctuationCharacters)
        
        if let mock = mockTranslations[normalizedWord] {
            return MockWordTranslation(
                translatedWord: mock.translation,
                partOfSpeech: mock.pos
            )
        }
        
        return MockWordTranslation(
            translatedWord: "[\(word)]",
            partOfSpeech: nil
        )
    }
}
