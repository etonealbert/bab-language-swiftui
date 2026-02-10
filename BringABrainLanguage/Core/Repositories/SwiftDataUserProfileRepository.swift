import Foundation
import SwiftData
import BabLanguageSDK

@MainActor
class SwiftDataUserProfileRepository: UserProfileRepository {
    
    private let modelContainer: ModelContainer
    private let mainContext: ModelContext
    
    init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
        self.mainContext = modelContainer.mainContext
    }
    
    func __getProfile() async throws -> UserProfile? {
        let descriptor = FetchDescriptor<SDUserProfile>()
        
        return try await MainActor.run {
            let results = try? mainContext.fetch(descriptor)
            guard let sdProfile = results?.first else { return nil }
            return try mapToKMP(sdProfile)
        }
    }
    
    func __saveProfile(profile: UserProfile) async throws {
        await MainActor.run {
            let descriptor = FetchDescriptor<SDUserProfile>()
            
            if let existing = try? mainContext.fetch(descriptor).first {
                updateExisting(existing, with: profile)
            } else {
                let sdProfile = try! mapToSwiftData(profile)
                mainContext.insert(sdProfile)
            }
            
            try? mainContext.save()
        }
    }
    
    func __updateOnboardingComplete() async throws {
        await MainActor.run {
            let descriptor = FetchDescriptor<SDUserProfile>()
            if let existing = try? mainContext.fetch(descriptor).first {
                existing.onboardingCompleted = true
                existing.lastActiveAt = Date()
                try? mainContext.save()
            }
        }
    }
    
    func __updateLastActive() async throws {
        await MainActor.run {
            let descriptor = FetchDescriptor<SDUserProfile>()
            if let existing = try? mainContext.fetch(descriptor).first {
                existing.lastActiveAt = Date()
                try? mainContext.save()
            }
        }
    }
    
    func __clear() async throws {
        await MainActor.run {
            let descriptor = FetchDescriptor<SDUserProfile>()
            if let profiles = try? mainContext.fetch(descriptor) {
                profiles.forEach { mainContext.delete($0) }
                try? mainContext.save()
            }
        }
    }
    
    // MARK: - Mappers
    
    /// Convert SwiftData SDUserProfile to KMP UserProfile
    private func mapToKMP(_ sd: SDUserProfile) throws -> UserProfile {
        // Parse interests from JSON
        let interests = parseInterests(from: sd.interestsJSON)
        
        // Parse learning goals from JSON
        let learningGoals = parseLearningGoals(from: sd.learningGoalsJSON)
        
        // Map target languages
        let targetLanguages = sd.targetLanguages.map { sdLang in
            TargetLanguage(
                code: sdLang.code,
                proficiencyLevel: mapToCEFRLevel(sdLang.proficiencyLevel),
                startedAt: Int64(sdLang.startedAt.timeIntervalSince1970 * 1000)
            )
        }
        
        return UserProfile(
            id: sd.id,
            displayName: sd.displayName,
            nativeLanguage: sd.nativeLanguage,
            targetLanguages: targetLanguages,
            currentTargetLanguage: sd.currentTargetLanguage,
            interests: Set(interests),
            learningGoals: Set(learningGoals),
            dailyGoalMinutes: Int32(sd.dailyGoalMinutes),
            voiceSpeed: mapToVoiceSpeed(sd.voiceSpeed),
            showTranslations: mapToTranslationMode(sd.showTranslations),
            isPremium: sd.isPremium,
            onboardingCompleted: sd.onboardingCompleted,
            createdAt: Int64(sd.createdAt.timeIntervalSince1970 * 1000),
            lastActiveAt: Int64(sd.lastActiveAt.timeIntervalSince1970 * 1000)
        )
    }
    
    /// Convert KMP UserProfile to SwiftData SDUserProfile
    private func mapToSwiftData(_ kmp: UserProfile) throws -> SDUserProfile {
        let profile = SDUserProfile(id: kmp.id)
        profile.displayName = kmp.displayName
        profile.nativeLanguage = kmp.nativeLanguage
        profile.currentTargetLanguage = kmp.currentTargetLanguage
        profile.dailyGoalMinutes = Int(kmp.dailyGoalMinutes)
        profile.voiceSpeed = kmp.voiceSpeed.name
        profile.showTranslations = kmp.showTranslations.name
        profile.isPremium = kmp.isPremium
        profile.onboardingCompleted = kmp.onboardingCompleted
        profile.createdAt = Date(timeIntervalSince1970: Double(kmp.createdAt) / 1000.0)
        profile.lastActiveAt = Date(timeIntervalSince1970: Double(kmp.lastActiveAt) / 1000.0)
        
        // Serialize interests and learning goals to JSON
        profile.interestsJSON = serializeInterests(Array(kmp.interests))
        profile.learningGoalsJSON = serializeLearningGoals(Array(kmp.learningGoals))
        
        // Map target languages
        profile.targetLanguages = kmp.targetLanguages.map { kmpLang in
            SDTargetLanguage(
                code: kmpLang.code,
                proficiencyLevel: kmpLang.proficiencyLevel.name,
                startedAt: Date(timeIntervalSince1970: Double(kmpLang.startedAt) / 1000.0)
            )
        }
        
        // Set inverse relationship
        for targetLang in profile.targetLanguages {
            targetLang.profile = profile
        }
        
        return profile
    }
    
    /// Update existing SwiftData profile with KMP data
    private func updateExisting(_ existing: SDUserProfile, with kmp: UserProfile) {
        existing.displayName = kmp.displayName
        existing.nativeLanguage = kmp.nativeLanguage
        existing.currentTargetLanguage = kmp.currentTargetLanguage
        existing.dailyGoalMinutes = Int(kmp.dailyGoalMinutes)
        existing.voiceSpeed = kmp.voiceSpeed.name
        existing.showTranslations = kmp.showTranslations.name
        existing.isPremium = kmp.isPremium
        existing.onboardingCompleted = kmp.onboardingCompleted
        existing.lastActiveAt = Date(timeIntervalSince1970: Double(kmp.lastActiveAt) / 1000.0)
        
        // Update JSON fields
        existing.interestsJSON = serializeInterests(Array(kmp.interests))
        existing.learningGoalsJSON = serializeLearningGoals(Array(kmp.learningGoals))
        
        // Update target languages relationship
        // Remove old languages
        existing.targetLanguages.forEach { mainContext.delete($0) }
        
        // Add new languages
        existing.targetLanguages = kmp.targetLanguages.map { kmpLang in
            let sdLang = SDTargetLanguage(
                code: kmpLang.code,
                proficiencyLevel: kmpLang.proficiencyLevel.name,
                startedAt: Date(timeIntervalSince1970: Double(kmpLang.startedAt) / 1000.0)
            )
            sdLang.profile = existing
            return sdLang
        }
    }
    
    // MARK: - Enum Mappers
    
    private func mapToVoiceSpeed(_ string: String) -> VoiceSpeed {
        switch string.uppercased() {
        case "SLOW": return .slow
        case "NORMAL": return .normal
        case "FAST": return .fast
        default: return .normal
        }
    }
    
    private func mapToTranslationMode(_ string: String) -> TranslationMode {
        switch string.uppercased() {
        case "ALWAYS": return .always
        case "ON_TAP": return .onTap
        case "NEVER": return .never
        default: return .onTap
        }
    }
    
    private func mapToCEFRLevel(_ string: String) -> CEFRLevel {
        switch string.uppercased() {
        case "A1": return .a1
        case "A2": return .a2
        case "B1": return .b1
        case "B2": return .b2
        case "C1": return .c1
        case "C2": return .c2
        default: return .a1
        }
    }
    
    // MARK: - JSON Serialization Helpers
        
    private func parseInterests(from json: String) -> [Interest] {
        guard let data = json.data(using: .utf8),
              let strings = try? JSONDecoder().decode([String].self, from: data) else {
            return []
        }
        
        return strings.compactMap { string in
            switch string.uppercased() { // Use UPPERCASED to match KMP defaults
            case "TRAVEL": return .travel
            case "BUSINESS": return .business
            case "ROMANCE": return .romance
            case "SCI_FI": return .sciFi // Note: KMP enums usually map snake_case to camelCase in Swift
            case "EVERYDAY": return .everyday
            case "FOOD": return .food
            case "CULTURE": return .culture
            case "SPORTS": return .sports
            case "MUSIC": return .music
            case "MOVIES": return .movies
            // Removed: technology, art, science, history (Not in SDK)
            default: return nil
            }
        }
    }
    
    private func parseLearningGoals(from json: String) -> [LearningGoal] {
        guard let data = json.data(using: .utf8),
              let strings = try? JSONDecoder().decode([String].self, from: data) else {
            return []
        }
        
        return strings.compactMap { string in
            switch string.uppercased() {
            case "CONVERSATION": return .conversation
            case "READING": return .reading
            case "LISTENING": return .listening
            case "EXAM_PREP": return .examPrep // Maps to KMP's EXAM_PREP
            case "WORK": return .work
            case "TRAVEL": return .travel
            // Removed: school, exams (use examPrep), culture (Not in SDK LearningGoal)
            default: return nil
            }
        }
    }
    
    private func serializeInterests(_ interests: [Interest]) -> String {
        // We save as UPPERCASE to match the parsing logic above
        let strings = interests.map { $0.name }
        guard let data = try? JSONEncoder().encode(strings),
              let json = String(data: data, encoding: .utf8) else {
            return "[]"
        }
        return json
    }
    
    private func serializeLearningGoals(_ goals: [LearningGoal]) -> String {
        let strings = goals.map { $0.name }
        guard let data = try? JSONEncoder().encode(strings),
              let json = String(data: data, encoding: .utf8) else {
            return "[]"
        }
        return json
    }
}
