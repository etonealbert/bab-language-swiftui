import SwiftData
import Foundation

@Model
final class SDTranslationCache {
    @Attribute(.unique) var cacheKey: String
    var sourceWord: String
    var sourceLanguage: String
    var targetLanguage: String
    var translatedWord: String
    var partOfSpeech: String?
    var definition: String?
    var cachedAt: Date
    var accessCount: Int
    var lastAccessedAt: Date
    
    init(
        sourceWord: String,
        sourceLanguage: String,
        targetLanguage: String,
        translatedWord: String,
        partOfSpeech: String? = nil,
        definition: String? = nil
    ) {
        self.cacheKey = "\(sourceWord.lowercased()):\(sourceLanguage):\(targetLanguage)"
        self.sourceWord = sourceWord
        self.sourceLanguage = sourceLanguage
        self.targetLanguage = targetLanguage
        self.translatedWord = translatedWord
        self.partOfSpeech = partOfSpeech
        self.definition = definition
        self.cachedAt = Date()
        self.accessCount = 0
        self.lastAccessedAt = Date()
    }
    
    func recordAccess() {
        accessCount += 1
        lastAccessedAt = Date()
    }
}
