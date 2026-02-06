import Foundation

struct ScenarioDisplayData: Identifiable, Hashable {
    let id: String
    let name: String
    let description: String
    let difficulty: String
    let isPremium: Bool
    let imageName: String
}
