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
    
    @Test func migrationPlanIncludesAllSchemas() {
        let schemas = BabLanguageMigrationPlan.schemas
        
        #expect(schemas.count == 2)
        #expect(schemas.first == BabLanguageSchemaV1.self)
        #expect(schemas.last == BabLanguageSchemaV2.self)
    }
    
    @Test func migrationPlanHasV1toV2Stage() {
        let stages = BabLanguageMigrationPlan.stages
        
        #expect(stages.count == 1)
    }
    
    @Test func schemaV2IncludesConversationModels() {
        let models = BabLanguageSchemaV2.models
        
        #expect(models.count == 8)
        #expect(models.contains { $0 == SDConversationSession.self })
        #expect(models.contains { $0 == SDConversationMessage.self })
    }
    
    @Test func schemaV2HasCorrectVersion() {
        let version = BabLanguageSchemaV2.versionIdentifier
        
        #expect(version.major == 2)
        #expect(version.minor == 0)
        #expect(version.patch == 0)
    }
}
