import Foundation
import SwiftData

enum BabLanguageSchemaV1: VersionedSchema {
    static var versionIdentifier = Schema.Version(1, 0, 0)
    
    static var models: [any PersistentModel.Type] {
        [
            SDUserProfile.self,
            SDTargetLanguage.self,
            SDVocabularyEntry.self,
            SDUserProgress.self,
            SDSavedSession.self,
            SDDialogLine.self
        ]
    }
}

enum BabLanguageSchemaV2: VersionedSchema {
    static var versionIdentifier = Schema.Version(2, 0, 0)
    
    static var models: [any PersistentModel.Type] {
        [
            SDUserProfile.self,
            SDTargetLanguage.self,
            SDVocabularyEntry.self,
            SDUserProgress.self,
            SDSavedSession.self,
            SDDialogLine.self,
            SDConversationSession.self,
            SDConversationMessage.self
        ]
    }
}

enum BabLanguageMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [BabLanguageSchemaV1.self, BabLanguageSchemaV2.self]
    }
    
    static var stages: [MigrationStage] {
        [migrateV1toV2]
    }
    
    static let migrateV1toV2 = MigrationStage.lightweight(
        fromVersion: BabLanguageSchemaV1.self,
        toVersion: BabLanguageSchemaV2.self
    )
}
