import SwiftUI
import BabLanguageSDK

@MainActor
final class SDKObserver: ObservableObject {
    
    let sdk: BrainSDK
    
    @Published var sessionState: SessionState?
    @Published var userProfile: UserProfile?
    @Published var vocabularyStats: VocabularyStats?
    @Published var progress: UserProgress?
    @Published var dueReviews: [VocabularyEntry] = []
    
    @Published var isGenerating: Bool = false
    @Published var showMemoryWarningBanner: Bool = false
    
    var isOnboardingRequired: Bool {
        sdk.isOnboardingRequired()
    }
    
    var isInActiveSession: Bool {
        guard let state = sessionState else { return false }
        return state.currentPhase == .active
    }
    
    var hasPendingVote: Bool {
        guard let state = sessionState else { return false }
        return state.pendingVote != nil
    }
    
    init(sdk: BrainSDK) {
        self.sdk = sdk
        self.sessionState = sdk.state.value as? SessionState
        self.userProfile = sdk.userProfile.value as? UserProfile
        self.vocabularyStats = sdk.vocabularyStats.value as? VocabularyStats
        self.progress = sdk.progress.value as? UserProgress
    }
    
    func generate() {
        isGenerating = true
        sdk.generate()
    }
    
    func startSoloGame(scenarioId: String, roleId: String) {
        sdk.startSoloGame(scenarioId: scenarioId, userRoleId: roleId)
    }
    
    func hostGame(scenarioId: String, roleId: String) {
        sdk.hostGame(scenarioId: scenarioId, userRoleId: roleId)
    }
    
    func joinGame(hostId: String, roleId: String) {
        sdk.joinGame(hostDeviceId: hostId, userRoleId: roleId)
    }
    
    func endSession() async {
        do {
            try await sdk.endSession()
        } catch {}
    }
    
    func completeOnboarding(profile: UserProfile) async {
        do {
            try await sdk.completeOnboarding(profile: profile)
        } catch {}
    }
    
    func recordReview(entryId: String, quality: ReviewQuality) async {
        do {
            try await sdk.recordVocabularyReview(entryId: entryId, quality: quality)
        } catch {}
    }
    
    func requestHint(level: HintLevel = .starterWords) {
        sdk.requestHint(level: level)
    }
}
