import Foundation

struct ScenarioDisplayData: Identifiable, Hashable {
    let id: String
    let name: String
    let description: String
    let difficulty: String
    let isPremium: Bool
    let imageName: String
    let userRole: String
    let aiRole: String
    
    init(
        id: String,
        name: String,
        description: String,
        difficulty: String,
        isPremium: Bool,
        imageName: String,
        userRole: String = "Customer",
        aiRole: String = "Assistant"
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.difficulty = difficulty
        self.isPremium = isPremium
        self.imageName = imageName
        self.userRole = userRole
        self.aiRole = aiRole
    }
}
