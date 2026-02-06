import Foundation
import SwiftData

@Model
final class SDTargetLanguage {
    var code: String = ""
    var proficiencyLevel: String = "A1"
    var startedAt: Date = Date()
    
    var profile: SDUserProfile?
    
    init(code: String, proficiencyLevel: String = "A1", startedAt: Date = Date()) {
        self.code = code
        self.proficiencyLevel = proficiencyLevel
        self.startedAt = startedAt
    }
}
