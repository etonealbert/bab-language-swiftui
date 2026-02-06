import Foundation
import SwiftData

@Model
final class SDSavedSession {
    @Attribute(.unique) var id: String
    var scenarioId: String = ""
    var scenarioName: String = ""
    var playedAt: Date = Date()
    var durationMinutes: Int = 0
    var xpEarned: Int = 0
    
    @Relationship(deleteRule: .cascade, inverse: \SDDialogLine.session)
    var dialogLines: [SDDialogLine] = []
    
    init(id: String = UUID().uuidString, scenarioId: String, scenarioName: String) {
        self.id = id
        self.scenarioId = scenarioId
        self.scenarioName = scenarioName
    }
}
