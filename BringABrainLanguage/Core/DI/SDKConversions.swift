import Foundation
import BabLanguageSDK

extension SDUserProfile {
    func toSDKProfile() -> UserProfile {
        UserProfile(
            id: id,
            displayName: displayName,
            nativeLanguage: nativeLanguage,
            targetLanguages: targetLanguages.map { $0.toSDKTargetLanguage() },
            currentTargetLanguage: currentTargetLanguage,
            interests: [],
            learningGoals: [],
            dailyGoalMinutes: Int32(dailyGoalMinutes),
            voiceSpeed: .normal,
            showTranslations: .onTap,
            onboardingCompleted: onboardingCompleted,
            createdAt: Int64(createdAt.timeIntervalSince1970),
            lastActiveAt: Int64(lastActiveAt.timeIntervalSince1970)
        )
    }
}

extension SDTargetLanguage {
    func toSDKTargetLanguage() -> TargetLanguage {
        TargetLanguage(
            code: code,
            proficiencyLevel: .a1,
            startedAt: Int64(Date().timeIntervalSince1970)
        )
    }
}

extension SDVocabularyEntry {
    func toSDKEntry() -> VocabularyEntry {
        VocabularyEntry(
            id: id,
            word: word,
            translation: translation,
            language: languageCode,
            partOfSpeech: nil,
            exampleSentence: nil,
            audioUrl: nil,
            masteryLevel: Int32(masteryLevel),
            easeFactor: Float(easeFactor),
            intervalDays: 1,
            nextReviewAt: Int64(nextReviewDate.timeIntervalSince1970),
            totalReviews: Int32(reviewCount),
            correctReviews: Int32(reviewCount),
            firstSeenInDialogId: nil,
            firstSeenAt: Int64(createdAt.timeIntervalSince1970),
            lastReviewedAt: nil
        )
    }
}

extension SDUserProgress {
    func toSDKProgress() -> UserProgress {
        UserProgress(
            id: id,
            totalXP: Int32(totalXP),
            currentLevel: Int32(currentLevel),
            xpToNextLevel: 1000,
            currentStreak: Int32(currentStreak),
            longestStreak: Int32(longestStreak),
            sessionsCompleted: Int32(sessionsCompleted),
            totalPlayTimeMinutes: 0,
            lastSessionDate: Int64(lastSessionDate.timeIntervalSince1970),
            achievements: []
        )
    }
}

extension SDSavedSession {
    func toSDKSession() -> SavedSession {
        SavedSession(
            id: id,
            scenarioName: scenarioName,
            playedAt: Int64(playedAt.timeIntervalSince1970),
            durationMinutes: Int32(durationMinutes),
            dialogLines: dialogLines.map { $0.toSDKDialogLine() },
            stats: nil,
            report: nil
        )
    }
}

extension SDDialogLine {
    func toSDKDialogLine() -> DialogLine {
        DialogLine(
            id: id,
            roleId: speakerId,
            roleName: roleName,
            textNative: textNative,
            textTranslated: textTranslated,
            timestamp: Int64(timestamp.timeIntervalSince1970)
        )
    }
}
