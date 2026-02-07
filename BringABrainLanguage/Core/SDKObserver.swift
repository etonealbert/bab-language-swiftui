import SwiftUI
import BabLanguageSDK

@MainActor
final class SDKObserver: ObservableObject {
    
    let sdk: BrainSDK
    private let llmManager = LLMManager.shared
    private var observationTasks: [Task<Void, Never>] = []
    
    @Published var sessionState: SessionState?
    @Published var userProfile: UserProfile?
    @Published var vocabularyStats: VocabularyStats?
    @Published var progress: UserProgress?
    @Published var dueReviews: [VocabularyEntry] = []
    @Published var dialogHistory: [DialogLine] = []
    @Published var vocabularyEntries: [VocabularyEntry] = []
    
    @Published var isGenerating: Bool = false
    @Published var showMemoryWarningBanner: Bool = false
    
    @Published private(set) var isSoloMode: Bool = false
    @Published private(set) var currentAIResponse: String?
    @Published private(set) var isLLMInitialized: Bool = false
    
    var llmAvailability: LLMAvailability {
        LLMBridge().checkAvailability()
    }
    
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
        startObserving()
    }
    
    private func startObserving() {
        observationTasks.append(Task {
            for await state in sdk.state {
                self.sessionState = state
            }
        })
        
        observationTasks.append(Task {
            for await profile in sdk.userProfile {
                self.userProfile = profile
            }
        })
        
        observationTasks.append(Task {
            for await stats in sdk.vocabularyStats {
                self.vocabularyStats = stats
            }
        })
        
        observationTasks.append(Task {
            for await userProgress in sdk.progress {
                self.progress = userProgress
            }
        })
        
        // TODO: Enable when SDK exposes dialogHistory StateFlow
        // observationTasks.append(Task {
        //     for await history in sdk.dialogHistory {
        //         self.dialogHistory = history
        //     }
        // })
        
        // TODO: Enable when SDK exposes vocabularyEntries StateFlow
        // observationTasks.append(Task {
        //     for await entries in sdk.vocabularyEntries {
        //         self.vocabularyEntries = entries
        //     }
        // })
    }
    
    deinit {
        observationTasks.forEach { $0.cancel() }
    }
    
    private func refreshFromSDK() {
        self.sessionState = sdk.state.value as? SessionState
        self.userProfile = sdk.userProfile.value as? UserProfile
        self.vocabularyStats = sdk.vocabularyStats.value as? VocabularyStats
        self.progress = sdk.progress.value as? UserProgress
        objectWillChange.send()
    }
    
    func generate() {
        isGenerating = true
        if isSoloMode {
            Task {
                await generateWithLLM(userMessage: "")
            }
        } else {
            sdk.generate()
        }
    }
    
    func initializeLLMForSoloMode(
        targetLanguage: String,
        nativeLanguage: String,
        scenario: String,
        userRole: String,
        aiRole: String
    ) async {
        await llmManager.initialize(
            targetLanguage: targetLanguage,
            nativeLanguage: nativeLanguage,
            scenario: scenario,
            userRole: userRole,
            aiRole: aiRole
        )
        isLLMInitialized = llmManager.isInitialized
    }
    
    func generateWithLLM(userMessage: String) async {
        guard isLLMInitialized else { return }
        
        isGenerating = true
        currentAIResponse = nil
        
        do {
            let response = try await llmManager.generate(prompt: userMessage)
            currentAIResponse = response
        } catch {
            currentAIResponse = nil
        }
        
        isGenerating = false
    }
    
    func startSoloGameWithLLM(
        scenarioId: String,
        roleId: String,
        targetLanguage: String,
        nativeLanguage: String
    ) {
        isSoloMode = true
        sdk.startSoloGame(scenarioId: scenarioId, userRoleId: roleId)
        
        Task {
            await initializeLLMForSoloMode(
                targetLanguage: targetLanguage,
                nativeLanguage: nativeLanguage,
                scenario: scenarioId,
                userRole: roleId,
                aiRole: "AI Partner"
            )
        }
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
            isSoloMode = false
            llmManager.reset()
            isLLMInitialized = false
            currentAIResponse = nil
        } catch {}
    }
    
    func completeOnboarding(profile: UserProfile) async {
        do {
            try await sdk.completeOnboarding(profile: profile)
            refreshFromSDK()
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
