import SwiftData
import Foundation

@MainActor
class SwiftDataTranslationCacheRepository {
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    func getCached(word: String, from sourceLanguage: String, to targetLanguage: String) -> SDTranslationCache? {
        let key = "\(word.lowercased()):\(sourceLanguage):\(targetLanguage)"
        let descriptor = FetchDescriptor<SDTranslationCache>(
            predicate: #Predicate { $0.cacheKey == key }
        )
        
        guard let entry = try? modelContext.fetch(descriptor).first else {
            return nil
        }
        
        entry.recordAccess()
        try? modelContext.save()
        
        return entry
    }
    
    func cache(
        word: String,
        from sourceLanguage: String,
        to targetLanguage: String,
        translatedWord: String,
        partOfSpeech: String?,
        definition: String?
    ) {
        let entry = SDTranslationCache(
            sourceWord: word,
            sourceLanguage: sourceLanguage,
            targetLanguage: targetLanguage,
            translatedWord: translatedWord,
            partOfSpeech: partOfSpeech,
            definition: definition
        )
        modelContext.insert(entry)
        try? modelContext.save()
    }
    
    func clearOldEntries(olderThan days: Int = 30) {
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        let descriptor = FetchDescriptor<SDTranslationCache>(
            predicate: #Predicate { $0.lastAccessedAt < cutoffDate }
        )
        
        guard let oldEntries = try? modelContext.fetch(descriptor) else { return }
        
        for entry in oldEntries {
            modelContext.delete(entry)
        }
        try? modelContext.save()
    }
    
    func getCacheStats() -> (totalEntries: Int, totalAccesses: Int) {
        let descriptor = FetchDescriptor<SDTranslationCache>()
        guard let entries = try? modelContext.fetch(descriptor) else {
            return (0, 0)
        }
        
        let totalAccesses = entries.reduce(0) { $0 + $1.accessCount }
        return (entries.count, totalAccesses)
    }
}
