import Foundation
import SwiftData
import BabLanguageSDK

final class SwiftDataUserProfileRepository: UserProfileRepository {
    
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    func getProfile() async throws -> UserProfile? {
        let descriptor = FetchDescriptor<SDUserProfile>()
        let profiles = try modelContext.fetch(descriptor)
        return profiles.first?.toSDKProfile()
    }
    
    func saveProfile(_ profile: UserProfile) async throws {
        let descriptor = FetchDescriptor<SDUserProfile>()
        let existing = try modelContext.fetch(descriptor)
        
        if let sdProfile = existing.first {
            sdProfile.displayName = profile.displayName
            sdProfile.nativeLanguageCode = profile.nativeLanguage
            sdProfile.dailyGoalMinutes = Int(profile.dailyGoalMinutes)
            sdProfile.onboardingCompleted = profile.onboardingCompleted
        } else {
            let newProfile = SDUserProfile(
                id: profile.id,
                displayName: profile.displayName,
                nativeLanguageCode: profile.nativeLanguage,
                dailyGoalMinutes: Int(profile.dailyGoalMinutes),
                onboardingCompleted: profile.onboardingCompleted
            )
            modelContext.insert(newProfile)
        }
        try modelContext.save()
    }
    
    func isOnboardingRequired() -> Bool {
        let descriptor = FetchDescriptor<SDUserProfile>()
        guard let profiles = try? modelContext.fetch(descriptor),
              let profile = profiles.first else {
            return true
        }
        return !profile.onboardingCompleted
    }
}

final class SwiftDataVocabularyRepository: VocabularyRepository {
    
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    func getAllEntries() async throws -> [VocabularyEntry] {
        let descriptor = FetchDescriptor<SDVocabularyEntry>()
        let entries = try modelContext.fetch(descriptor)
        return entries.map { $0.toSDKEntry() }
    }
    
    func getDueReviews() async throws -> [VocabularyEntry] {
        let now = Date()
        let predicate = #Predicate<SDVocabularyEntry> { $0.nextReviewDate <= now }
        let descriptor = FetchDescriptor(predicate: predicate)
        let entries = try modelContext.fetch(descriptor)
        return entries.map { $0.toSDKEntry() }
    }
    
    func saveEntry(_ entry: VocabularyEntry) async throws {
        let predicate = #Predicate<SDVocabularyEntry> { $0.id == entry.id }
        let descriptor = FetchDescriptor(predicate: predicate)
        let existing = try modelContext.fetch(descriptor)
        
        if let sdEntry = existing.first {
            sdEntry.masteryLevel = Int(entry.masteryLevel)
            sdEntry.reviewCount = Int(entry.reviewCount)
            sdEntry.nextReviewDate = entry.nextReviewDate
            sdEntry.easeFactor = entry.easeFactor
        } else {
            let newEntry = SDVocabularyEntry(
                id: entry.id,
                word: entry.word,
                translation: entry.translation,
                languageCode: entry.languageCode,
                masteryLevel: Int(entry.masteryLevel),
                reviewCount: Int(entry.reviewCount),
                nextReviewDate: entry.nextReviewDate,
                easeFactor: entry.easeFactor
            )
            modelContext.insert(newEntry)
        }
        try modelContext.save()
    }
    
    func getStats() async throws -> VocabularyStats {
        let descriptor = FetchDescriptor<SDVocabularyEntry>()
        let entries = try modelContext.fetch(descriptor)
        
        let total = entries.count
        let mastered = entries.filter { $0.masteryLevel >= 4 }.count
        let learning = entries.filter { $0.masteryLevel > 0 && $0.masteryLevel < 4 }.count
        let newCount = entries.filter { $0.masteryLevel == 0 }.count
        
        let now = Date()
        let dueCount = entries.filter { $0.nextReviewDate <= now }.count
        
        return VocabularyStats(
            totalWords: Int32(total),
            masteredWords: Int32(mastered),
            learningWords: Int32(learning),
            newWords: Int32(newCount),
            dueForReview: Int32(dueCount),
            averageRetention: 0.8
        )
    }
}

final class SwiftDataProgressRepository: ProgressRepository {
    
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    func getProgress() async throws -> UserProgress? {
        let descriptor = FetchDescriptor<SDUserProgress>()
        let progress = try modelContext.fetch(descriptor)
        return progress.first?.toSDKProgress()
    }
    
    func saveProgress(_ progress: UserProgress) async throws {
        let descriptor = FetchDescriptor<SDUserProgress>()
        let existing = try modelContext.fetch(descriptor)
        
        if let sdProgress = existing.first {
            sdProgress.totalXP = Int(progress.totalXP)
            sdProgress.currentLevel = Int(progress.currentLevel)
            sdProgress.currentStreak = Int(progress.currentStreak)
            sdProgress.sessionsCompleted = Int(progress.sessionsCompleted)
        } else {
            let newProgress = SDUserProgress(
                id: progress.id,
                totalXP: Int(progress.totalXP),
                currentLevel: Int(progress.currentLevel),
                currentStreak: Int(progress.currentStreak),
                longestStreak: Int(progress.longestStreak),
                sessionsCompleted: Int(progress.sessionsCompleted),
                lastSessionDate: progress.lastSessionDate
            )
            modelContext.insert(newProgress)
        }
        try modelContext.save()
    }
}

final class SwiftDataDialogHistoryRepository: DialogHistoryRepository {
    
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    func getSavedSessions() async throws -> [SavedSession] {
        let descriptor = FetchDescriptor<SDSavedSession>(sortBy: [SortDescriptor(\.playedAt, order: .reverse)])
        let sessions = try modelContext.fetch(descriptor)
        return sessions.map { $0.toSDKSession() }
    }
    
    func saveSession(_ session: SavedSession) async throws {
        let newSession = SDSavedSession(
            id: session.id,
            scenarioId: session.scenarioId,
            scenarioName: session.scenarioName,
            playedAt: session.playedAt,
            durationMinutes: Int(session.durationMinutes),
            dialogLines: session.dialogHistory.map { line in
                SDDialogLine(
                    id: line.id,
                    roleId: line.roleId,
                    roleName: line.roleName,
                    textNative: line.textNative,
                    textTranslated: line.textTranslated,
                    timestamp: line.timestamp
                )
            }
        )
        modelContext.insert(newSession)
        try modelContext.save()
    }
    
    func deleteSession(_ sessionId: String) async throws {
        let predicate = #Predicate<SDSavedSession> { $0.id == sessionId }
        let descriptor = FetchDescriptor(predicate: predicate)
        let sessions = try modelContext.fetch(descriptor)
        
        for session in sessions {
            modelContext.delete(session)
        }
        try modelContext.save()
    }
}
