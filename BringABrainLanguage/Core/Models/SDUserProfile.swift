import Foundation
import SwiftData

@Model
final class SDUserProfile {
    @Attribute(.unique) var id: String
    var displayName: String = ""
    var nativeLanguage: String = "en"
    var currentTargetLanguage: String = "es"
    var dailyGoalMinutes: Int = 15
    var voiceSpeed: String = "NORMAL"
    var showTranslations: String = "ON_TAP"
    var onboardingCompleted: Bool = false
    var createdAt: Date = Date()
    var lastActiveAt: Date = Date()
    var isPremium: Bool = false
    var interestsJSON: String = "[]"
    var learningGoalsJSON: String = "[]"
    
    @Relationship(deleteRule: .cascade, inverse: \SDTargetLanguage.profile)
    var targetLanguages: [SDTargetLanguage] = []
    
    init(id: String = UUID().uuidString) {
        self.id = id
    }
}
