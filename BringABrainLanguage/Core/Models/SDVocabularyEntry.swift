import Foundation
import SwiftData

@Model
final class SDVocabularyEntry {
    @Attribute(.unique) var id: String
    var word: String = ""
    var translation: String = ""
    var language: String = ""
    var partOfSpeech: String?
    var exampleSentence: String?
    var audioUrl: String?
    
    var masteryLevel: Int = 0
    var easeFactor: Float = 2.5
    var intervalDays: Int = 1
    var nextReviewAt: Date = Date()
    var totalReviews: Int = 0
    var correctReviews: Int = 0
    var firstSeenInDialogId: String?
    var firstSeenAt: Date = Date()
    var lastReviewedAt: Date?
    
    init(id: String = UUID().uuidString, word: String, translation: String, language: String) {
        self.id = id
        self.word = word
        self.translation = translation
        self.language = language
    }
}
