import Foundation
import SwiftData

@Model
final class SDConversationSession {
    @Attribute(.unique) var id: String
    var scenarioTitle: String = ""
    var date: Date = Date()
    var targetLanguage: String = ""
    var nativeLanguage: String = ""
    var durationMinutes: Int = 0
    var isComplete: Bool = false
    
    @Relationship(deleteRule: .cascade, inverse: \SDConversationMessage.session)
    var messages: [SDConversationMessage] = []
    
    init(
        id: String = UUID().uuidString,
        scenarioTitle: String,
        targetLanguage: String,
        nativeLanguage: String
    ) {
        self.id = id
        self.scenarioTitle = scenarioTitle
        self.targetLanguage = targetLanguage
        self.nativeLanguage = nativeLanguage
    }
}

@Model
final class SDConversationMessage {
    @Attribute(.unique) var id: String
    var text: String = ""
    var translation: String?
    var role: String = ""
    var isUser: Bool = false
    var timestamp: Date = Date()
    /// Denormalized for @Query filtering in TheaterView inner-view pattern
    var sessionId: String = ""
    
    var session: SDConversationSession?
    
    init(
        id: String = UUID().uuidString,
        text: String,
        translation: String? = nil,
        role: String,
        isUser: Bool,
        sessionId: String
    ) {
        self.id = id
        self.text = text
        self.translation = translation
        self.role = role
        self.isUser = isUser
        self.sessionId = sessionId
    }
}
