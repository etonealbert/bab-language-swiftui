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
    
    @Published var nativeDialogLines: [NativeDialogLine] = []
    @Published var sessionInitState: SessionInitState = .idle
    @Published private(set) var currentTheaterConfig: TheaterSessionConfig?
    @Published private(set) var currentUserLineIndex: Int?
    
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
    
    // MARK: - Native Theater Session (Foundation Models)
    
    func initializeTheaterSession(config: TheaterSessionConfig) async {
        sessionInitState = .initializing
        currentTheaterConfig = config
        nativeDialogLines = []
        currentUserLineIndex = nil
        isSoloMode = true
        
        await llmManager.initialize(
            targetLanguage: config.targetLanguage,
            nativeLanguage: config.nativeLanguage,
            scenario: config.scenarioTitle,
            userRole: config.userRole,
            aiRole: config.aiRole
        )
        
        guard llmManager.isInitialized else {
            sessionInitState = .error("Failed to initialize language model")
            return
        }
        
        isLLMInitialized = true
        sessionInitState = .ready
        
        await generateNextExchange()
    }
    
    func generateNextExchange() async {
        guard isLLMInitialized, let config = currentTheaterConfig else { return }
        
        isGenerating = true
        defer { isGenerating = false }
        
        let prompt = buildExchangePrompt(config: config)
        
        do {
            let response = try await llmManager.generate(prompt: prompt)
            let parsed = parseExchangeResponse(response, config: config)
            
            nativeDialogLines.append(parsed.aiLine)
            nativeDialogLines.append(parsed.userLine)
            currentUserLineIndex = nativeDialogLines.count - 1
        } catch {
            if nativeDialogLines.isEmpty {
                sessionInitState = .error("Failed to generate dialog: \(error.localizedDescription)")
            }
        }
    }
    
    func confirmUserLine() async {
        currentUserLineIndex = nil
        await generateNextExchange()
    }
    
    func skipUserLine() {
        currentUserLineIndex = nil
    }
    
    func endTheaterSession() async {
        await endSession()
        nativeDialogLines = []
        sessionInitState = .idle
        currentTheaterConfig = nil
        currentUserLineIndex = nil
    }
    
    private func buildExchangePrompt(config: TheaterSessionConfig) -> String {
        let previousContext: String
        if nativeDialogLines.isEmpty {
            previousContext = "This is the start of the conversation."
        } else {
            let recentLines = nativeDialogLines.suffix(6).map { line in
                "\(line.role): \(line.text)"
            }.joined(separator: "\n")
            previousContext = "Previous conversation:\n\(recentLines)"
        }
        
        return """
        \(previousContext)
        
        Generate the next exchange. First provide your line as \(config.aiRole), then suggest what the user (\(config.userRole)) should say.
        
        Format your response exactly like this:
        AI_LINE: [Your dialog in \(config.targetLanguage)]
        AI_TRANSLATION: [Translation in \(config.nativeLanguage)]
        USER_LINE: [Suggested user response in \(config.targetLanguage)]
        USER_TRANSLATION: [Translation in \(config.nativeLanguage)]
        """
    }
    
    private func parseExchangeResponse(_ response: String, config: TheaterSessionConfig) -> (aiLine: NativeDialogLine, userLine: NativeDialogLine) {
        var aiText = ""
        var aiTranslation: String?
        var userText = ""
        var userTranslation: String?
        
        let lines = response.components(separatedBy: .newlines)
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("AI_LINE:") {
                aiText = String(trimmed.dropFirst("AI_LINE:".count)).trimmingCharacters(in: .whitespaces)
            } else if trimmed.hasPrefix("AI_TRANSLATION:") {
                aiTranslation = String(trimmed.dropFirst("AI_TRANSLATION:".count)).trimmingCharacters(in: .whitespaces)
            } else if trimmed.hasPrefix("USER_LINE:") {
                userText = String(trimmed.dropFirst("USER_LINE:".count)).trimmingCharacters(in: .whitespaces)
            } else if trimmed.hasPrefix("USER_TRANSLATION:") {
                userTranslation = String(trimmed.dropFirst("USER_TRANSLATION:".count)).trimmingCharacters(in: .whitespaces)
            }
        }
        
        if aiText.isEmpty {
            aiText = response.components(separatedBy: "USER_LINE:").first?.trimmingCharacters(in: .whitespacesAndNewlines) ?? response
        }
        if userText.isEmpty {
            userText = "..."
        }
        
        let aiLine = NativeDialogLine(
            text: aiText,
            translation: aiTranslation,
            role: config.aiRole,
            isUser: false
        )
        
        let userLine = NativeDialogLine(
            text: userText,
            translation: userTranslation,
            role: config.userRole,
            isUser: true
        )
        
        return (aiLine, userLine)
    }
}
