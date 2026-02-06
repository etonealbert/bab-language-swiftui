//
//  SwiftDataSchemaTests.swift
//  BringABrainLanguageTests
//
//  Created by Whatsername on 06/02/2026.
//

import Testing
import SwiftData
import Foundation
@testable import BringABrainLanguage

struct SwiftDataSchemaTests {
    
    @Test func schemaV1IncludesAllModels() {
        let models = BabLanguageSchemaV1.models
        
        #expect(models.count == 6)
        #expect(models.contains { $0 == SDUserProfile.self })
        #expect(models.contains { $0 == SDTargetLanguage.self })
        #expect(models.contains { $0 == SDVocabularyEntry.self })
        #expect(models.contains { $0 == SDUserProgress.self })
        #expect(models.contains { $0 == SDSavedSession.self })
        #expect(models.contains { $0 == SDDialogLine.self })
    }
    
    @Test func schemaV1HasCorrectVersion() {
        let version = BabLanguageSchemaV1.versionIdentifier
        
        #expect(version.major == 1)
        #expect(version.minor == 0)
        #expect(version.patch == 0)
    }
    
    @Test func migrationPlanIncludesSchemaV1() {
        let schemas = BabLanguageMigrationPlan.schemas
        
        #expect(schemas.count == 1)
        #expect(schemas.first == BabLanguageSchemaV1.self)
    }
    
    @Test func migrationPlanHasNoStagesInitially() {
        let stages = BabLanguageMigrationPlan.stages
        
        #expect(stages.isEmpty)
    }
}
