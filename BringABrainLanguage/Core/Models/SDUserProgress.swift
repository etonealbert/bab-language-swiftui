import Foundation
import SwiftData

@Model
final class SDUserProgress {
    @Attribute(.unique) var id: String
    var language: String = ""
    var currentStreak: Int = 0
    var longestStreak: Int = 0
    var lastActivityDate: String = ""
    var todayMinutes: Int = 0
    var totalXP: Int = 0
    var weeklyXP: Int = 0
    var currentLevel: Int = 1
    var totalWordsLearned: Int = 0
    var wordsDueForReview: Int = 0
    var vocabularyMasteryPercent: Float = 0.0
    var totalSessions: Int = 0
    var totalMinutesPlayed: Int = 0
    var soloSessions: Int = 0
    var multiplayerSessions: Int = 0
    var estimatedCEFR: String = "A1"
    
    init(id: String = UUID().uuidString, language: String) {
        self.id = id
        self.language = language
    }
}
