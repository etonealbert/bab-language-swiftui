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

enum BabLanguageMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [BabLanguageSchemaV1.self]
    }
    
    static var stages: [MigrationStage] {
        []
    }
}
