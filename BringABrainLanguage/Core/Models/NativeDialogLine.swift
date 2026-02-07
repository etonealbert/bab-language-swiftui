import Foundation

struct NativeDialogLine: Identifiable, Equatable {
    let id: UUID
    let text: String
    let translation: String?
    let role: String
    let isUser: Bool
    let timestamp: Date
    
    init(
        id: UUID = UUID(),
        text: String,
        translation: String? = nil,
        role: String,
        isUser: Bool,
        timestamp: Date = Date()
    ) {
        self.id = id
        self.text = text
        self.translation = translation
        self.role = role
        self.isUser = isUser
        self.timestamp = timestamp
    }
}

enum SessionInitState: Equatable {
    case idle
    case initializing
    case ready
    case error(String)
    
    var isLoading: Bool {
        self == .initializing
    }
    
    var errorMessage: String? {
        if case .error(let message) = self {
            return message
        }
        return nil
    }
}

struct TheaterSessionConfig: Equatable {
    let scenarioId: String
    let scenarioTitle: String
    let targetLanguage: String
    let nativeLanguage: String
    let userRole: String
    let aiRole: String
}
