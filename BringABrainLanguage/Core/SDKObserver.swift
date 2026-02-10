import SwiftUI
import SwiftData
import BabLanguageSDK

@MainActor
final class SDKObserver: ObservableObject {
    
    let sdk: BrainSDK
    private let llmManager = LLMManager.shared
    let modelContext: ModelContext
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
    
    @Published var sessionInitState: SessionInitState = .idle
    @Published private(set) var currentTheaterConfig: TheaterSessionConfig?
    @Published private(set) var currentUserLineId: String?
    @Published private(set) var currentSessionId: String?
    
    private var sessionStartDate: Date?
    
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
    
    init(sdk: BrainSDK, modelContext: ModelContext) {
        self.sdk = sdk
        self.modelContext = modelContext
        self.sessionState = sdk.state.value as? SessionState
        self.userProfile = sdk.userProfile.value as? UserProfile
        self.vocabularyStats = sdk.vocabularyStats.value as? VocabularyStats
        self.progress = sdk.progress.value as? UserProgress
        startObserving()
    }
    
    private func startObserving() {
        observationTasks.append(Task {
            for await state in sdk.state {
                await MainActor.run { self.sessionState = state }
            }
        })
        
        observationTasks.append(Task {
            for await profile in sdk.userProfile {
                await MainActor.run { self.userProfile = profile }
            }
        })
        
        observationTasks.append(Task {
            for await stats in sdk.vocabularyStats {
                await MainActor.run { self.vocabularyStats = stats }
            }
        })
        
        observationTasks.append(Task {
            for await userProgress in sdk.progress {
                await MainActor.run { self.progress = userProgress }
            }
        })
        
        NotificationCenter.default.addObserver(
            forName: .subscriptionStatusChanged,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let self,
                  let status = notification.object as? AppSubscriptionStatus else { return }
            Task { @MainActor in
                await self.syncPremiumStatus(isSubscribed: status == .subscribed)
            }
        }
    }
    
    deinit {
        observationTasks.forEach { $0.cancel() }
    }
    
    // MARK: - Premium Sync
    
    private func syncPremiumStatus(isSubscribed: Bool) async {
        let descriptor = FetchDescriptor<SDUserProfile>()
        if let sdProfile = try? modelContext.fetch(descriptor).first {
            sdProfile.isPremium = isSubscribed
            try? modelContext.save()
        }
        
        if let currentProfile = userProfile {
            let updatedProfile = UserProfile(
                id: currentProfile.id,
                displayName: currentProfile.displayName,
                nativeLanguage: currentProfile.nativeLanguage,
                targetLanguages: currentProfile.targetLanguages,
                currentTargetLanguage: currentProfile.currentTargetLanguage,
                interests: currentProfile.interests,
                learningGoals: currentProfile.learningGoals,
                dailyGoalMinutes: currentProfile.dailyGoalMinutes,
                voiceSpeed: currentProfile.voiceSpeed,
                showTranslations: currentProfile.showTranslations,
                isPremium: isSubscribed,
                onboardingCompleted: currentProfile.onboardingCompleted,
                createdAt: currentProfile.createdAt,
                lastActiveAt: currentProfile.lastActiveAt
            )
            try? await sdk.completeOnboarding(profile: updatedProfile)
        }
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
    
    // MARK: - Native Theater Session
    
    func initializeTheaterSession(config: TheaterSessionConfig) async {
        sessionInitState = .initializing
        currentTheaterConfig = config
        currentUserLineId = nil
        isSoloMode = true
        sessionStartDate = Date()
        
        let session = SDConversationSession(
            scenarioTitle: config.scenarioTitle,
            targetLanguage: config.targetLanguage,
            nativeLanguage: config.nativeLanguage
        )
        modelContext.insert(session)
        try? modelContext.save()
        currentSessionId = session.id
        
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
        guard isLLMInitialized, let config = currentTheaterConfig,
              let sessionId = currentSessionId else { return }
        
        await MainActor.run { isGenerating = true }
        
        defer {
            Task { @MainActor in isGenerating = false }
        }
        
        let prompt = buildExchangePrompt(config: config, sessionId: sessionId)
        
        do {
            let response = try await llmManager.generate(prompt: prompt)
            let parsed = parseExchangeResponse(response, config: config)
            
            print("🔎 [LLM DEBUG] Raw Response:\n\(response)")
            print("🔎 [LLM DEBUG] Parsed AI: \(parsed.aiLine.text)")
            
            await MainActor.run {
                let aiMessage = SDConversationMessage(
                    text: parsed.aiLine.text,
                    translation: parsed.aiLine.translation,
                    role: parsed.aiLine.role,
                    isUser: false,
                    sessionId: sessionId
                )
                let userMessage = SDConversationMessage(
                    text: parsed.userLine.text,
                    translation: parsed.userLine.translation,
                    role: parsed.userLine.role,
                    isUser: true,
                    sessionId: sessionId
                )
                
                let descriptor = FetchDescriptor<SDConversationSession>(
                    predicate: #Predicate { $0.id == sessionId }
                )
                if let session = try? self.modelContext.fetch(descriptor).first {
                    session.messages.append(aiMessage)
                    session.messages.append(userMessage)
                    
                    try? self.modelContext.save()
                    
                    self.currentUserLineId = userMessage.id
                }
            }
            
        } catch {
            print("❌ [LLM ERROR] \(error.localizedDescription)")
            await MainActor.run {
                self.sessionInitState = .error(error.localizedDescription)
            }
        }
    }
    
    func confirmUserLine() async {
        currentUserLineId = nil
        await generateNextExchange()
    }
    
    func skipUserLine() async {
        currentUserLineId = nil
        await generateNextExchange()
    }
    
    func endTheaterSession(save: Bool) async {
        if let sessionId = currentSessionId {
            let descriptor = FetchDescriptor<SDConversationSession>(
                predicate: #Predicate { $0.id == sessionId }
            )
            if let session = try? modelContext.fetch(descriptor).first {
                if save {
                    let duration = Int(Date().timeIntervalSince(sessionStartDate ?? Date()) / 60)
                    session.durationMinutes = max(duration, 1)
                    session.isComplete = true
                    try? modelContext.save()
                } else {
                    modelContext.delete(session)
                    try? modelContext.save()
                }
            }
        }
        
        await endSession()
        sessionInitState = .idle
        currentTheaterConfig = nil
        currentUserLineId = nil
        currentSessionId = nil
        sessionStartDate = nil
    }
    
    func deleteConversationSession(id: String) {
        let descriptor = FetchDescriptor<SDConversationSession>(
            predicate: #Predicate { $0.id == id }
        )
        if let session = try? modelContext.fetch(descriptor).first {
            modelContext.delete(session)
            try? modelContext.save()
        }
    }
    
    private func buildExchangePrompt(config: TheaterSessionConfig, sessionId: String) -> String {
        var descriptor = FetchDescriptor<SDConversationMessage>(
            predicate: #Predicate { $0.sessionId == sessionId },
            sortBy: [SortDescriptor(\.timestamp)]
        )
        descriptor.fetchLimit = 6
        
        let recentMessages = (try? modelContext.fetch(descriptor)) ?? []
        
        let previousContext: String
        if recentMessages.isEmpty {
            previousContext = "This is the start of the conversation."
        } else {
            let recentLines = recentMessages.map { msg in
                "\(msg.role): \(msg.text)"
            }.joined(separator: "\n")
            previousContext = "Previous conversation:\n\(recentLines)"
        }
        
        return """
        \(previousContext)
        
        Generate the next exchange. First provide your line as \(config.aiRole), then suggest what the user (\(config.userRole)) should say.
        
        IMPORTANT RULES:
        - Generate ONLY the immediate next exchange. Do NOT generate a conversation history.
        - Output exactly ONE AI_LINE and ONE USER_LINE pair.
        - Do NOT add numbering, extra turns, or continue the conversation beyond one exchange.
        
        Format your response exactly like this:
        AI_LINE: [Your dialog in \(config.targetLanguage)]
        AI_TRANSLATION: [Translation in \(config.nativeLanguage)]
        USER_LINE: [Suggested user response in \(config.targetLanguage)]
        USER_TRANSLATION: [Translation in \(config.nativeLanguage)]
        """
    }
    
    private func parseExchangeResponse(_ response: String, config: TheaterSessionConfig) -> (aiLine: NativeDialogLine, userLine: NativeDialogLine) {
            
            func findText(pattern: String) -> String? {
                let regexPattern = "\(pattern)\\**\\s*:?\\s*\"?(.*?)\"?\\s*$"
                
                guard let regex = try? NSRegularExpression(pattern: regexPattern, options: [.caseInsensitive, .anchorsMatchLines]) else { return nil }
                let nsString = response as NSString
                let results = regex.matches(in: response, options: [], range: NSRange(location: 0, length: nsString.length))
                
                if let match = results.first {
                    return nsString.substring(with: match.range(at: 1)).trimmingCharacters(in: .whitespacesAndNewlines)
                }
                return nil
            }

            let aiText = findText(pattern: "AI_LINE") ?? "..."
            let aiTranslation = findText(pattern: "AI_TRANSLATION")
            let userText = findText(pattern: "USER_LINE") ?? "..."
            let userTranslation = findText(pattern: "USER_TRANSLATION")

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
