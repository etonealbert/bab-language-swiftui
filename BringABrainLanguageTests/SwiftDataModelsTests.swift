//
//  SwiftDataModelsTests.swift
//  BringABrainLanguageTests
//
//  Created by Whatsername on 06/02/2026.
//

import Testing
import SwiftData
import Foundation
@testable import BringABrainLanguage

struct SwiftDataModelsTests {
    
    // MARK: - SDTargetLanguage Tests
    
    @Test func targetLanguageCanBeInstantiated() {
        let targetLanguage = SDTargetLanguage(code: "es", proficiencyLevel: "A1")
        
        #expect(targetLanguage.code == "es")
        #expect(targetLanguage.proficiencyLevel == "A1")
        #expect(targetLanguage.startedAt != nil)
    }
    
    @Test func targetLanguageHasDefaultValues() {
        let targetLanguage = SDTargetLanguage(code: "es")
        
        #expect(targetLanguage.proficiencyLevel == "A1")
    }
    
    // MARK: - SDUserProfile Tests
    
    @Test func userProfileCanBeInstantiated() {
        let profile = SDUserProfile()
        
        #expect(profile.id != "")
        #expect(profile.displayName == "")
        #expect(profile.nativeLanguage == "en")
        #expect(profile.currentTargetLanguage == "es")
        #expect(profile.dailyGoalMinutes == 15)
        #expect(profile.voiceSpeed == "NORMAL")
        #expect(profile.showTranslations == "ON_TAP")
        #expect(profile.onboardingCompleted == false)
        #expect(profile.targetLanguages.isEmpty)
    }
    
    @Test func userProfileCanHaveTargetLanguages() {
        let profile = SDUserProfile()
        let targetLanguage = SDTargetLanguage(code: "es")
        
        profile.targetLanguages.append(targetLanguage)
        
        #expect(profile.targetLanguages.count == 1)
        #expect(profile.targetLanguages.first?.code == "es")
    }
    
    // MARK: - SDVocabularyEntry Tests
    
    @Test func vocabularyEntryCanBeInstantiated() {
        let entry = SDVocabularyEntry(
            word: "hola",
            translation: "hello",
            language: "es"
        )
        
        #expect(entry.id != "")
        #expect(entry.word == "hola")
        #expect(entry.translation == "hello")
        #expect(entry.language == "es")
    }
    
    @Test func vocabularyEntryHasSM2SRSDefaults() {
        let entry = SDVocabularyEntry(
            word: "hola",
            translation: "hello",
            language: "es"
        )
        
        #expect(entry.masteryLevel == 0)
        #expect(entry.easeFactor == 2.5)
        #expect(entry.intervalDays == 1)
        #expect(entry.totalReviews == 0)
        #expect(entry.correctReviews == 0)
        #expect(entry.nextReviewAt != nil)
        #expect(entry.firstSeenAt != nil)
    }
    
    // MARK: - SDUserProgress Tests
    
    @Test func userProgressCanBeInstantiated() {
        let progress = SDUserProgress(language: "es")
        
        #expect(progress.id != "")
        #expect(progress.language == "es")
        #expect(progress.currentStreak == 0)
        #expect(progress.longestStreak == 0)
        #expect(progress.totalXP == 0)
        #expect(progress.currentLevel == 1)
        #expect(progress.estimatedCEFR == "A1")
    }
    
    // MARK: - SDDialogLine Tests
    
    @Test func dialogLineCanBeInstantiated() {
        let dialogLine = SDDialogLine(
            speakerId: "user1",
            roleName: "Tourist",
            textNative: "¿Dónde está el baño?",
            textTranslated: "Where is the bathroom?"
        )
        
        #expect(dialogLine.id != "")
        #expect(dialogLine.speakerId == "user1")
        #expect(dialogLine.roleName == "Tourist")
        #expect(dialogLine.textNative == "¿Dónde está el baño?")
        #expect(dialogLine.textTranslated == "Where is the bathroom?")
        #expect(dialogLine.timestamp != nil)
    }
    
    // MARK: - SDSavedSession Tests
    
    @Test func savedSessionCanBeInstantiated() {
        let session = SDSavedSession(
            scenarioId: "cafe_order",
            scenarioName: "Ordering at a Café"
        )
        
        #expect(session.id != "")
        #expect(session.scenarioId == "cafe_order")
        #expect(session.scenarioName == "Ordering at a Café")
        #expect(session.playedAt != nil)
        #expect(session.durationMinutes == 0)
        #expect(session.xpEarned == 0)
        #expect(session.dialogLines.isEmpty)
    }
    
    @Test func savedSessionCanHaveDialogLines() {
        let session = SDSavedSession(
            scenarioId: "cafe_order",
            scenarioName: "Ordering at a Café"
        )
        let dialogLine = SDDialogLine(
            speakerId: "user1",
            roleName: "Customer",
            textNative: "Un café, por favor",
            textTranslated: "A coffee, please"
        )
        
        session.dialogLines.append(dialogLine)
        
        #expect(session.dialogLines.count == 1)
        #expect(session.dialogLines.first?.textNative == "Un café, por favor")
    }
}
