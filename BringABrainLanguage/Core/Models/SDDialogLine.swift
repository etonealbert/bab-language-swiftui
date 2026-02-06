import Foundation
import SwiftData

@Model
final class SDDialogLine {
    @Attribute(.unique) var id: String
    var speakerId: String = ""
    var roleName: String = ""
    var textNative: String = ""
    var textTranslated: String = ""
    var timestamp: Date = Date()
    
    var session: SDSavedSession?
    
    init(id: String = UUID().uuidString, speakerId: String, roleName: String, textNative: String, textTranslated: String) {
        self.id = id
        self.speakerId = speakerId
        self.roleName = roleName
        self.textNative = textNative
        self.textTranslated = textTranslated
    }
}
