import SwiftUI
import SwiftData

struct TheaterView: View {
    let scenarioId: String
    let scenarioTitle: String
    let namespace: Namespace.ID
    let config: TheaterSessionConfig
    
    @EnvironmentObject var observer: SDKObserver
    @Environment(\.dismiss) var dismiss
    @Query private var sessions: [SDConversationSession]
    
    @StateObject private var speechManager = SpeechManager()
    @State private var selectedWord: String?
    @State private var selectedWordIndex: Int?
    @State private var showEndSessionAlert = false
    
    @AppStorage("micEnabled") private var micEnabled = true
    
    private var activeSession: SDConversationSession? {
            sessions.first { $0.id == observer.currentSessionId }
        }
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                headerBar
                
                if let session = activeSession {
                    TheaterMessageList(
                        session: session,
                        isGenerating: observer.isGenerating,
                        currentUserLineId: observer.currentUserLineId,
                        speechMatchedWordCount: speechManager.matchedWordCount,
                        onWordLongPress: { word, index in
                            selectedWord = word
                            selectedWordIndex = index
                        }
                    )
                }
                
                bottomControls
            }
            
            if observer.sessionInitState.isLoading {
                loadingOverlay
            }
            
            if let errorMessage = observer.sessionInitState.errorMessage {
                errorOverlay(message: errorMessage)
            }
            
            if showEndSessionAlert {
                endSessionOverlay
            }
        }
        .navigationBarHidden(true)
        .navigationTransition(.zoom(sourceID: scenarioId, in: namespace))
        .toolbar(.hidden, for: .tabBar)
        .popover(isPresented: Binding(
            get: { selectedWord != nil },
            set: { if !$0 { selectedWord = nil } }
        )) {
            if let word = selectedWord {
                WordDetailPopover(
                    word: word,
                    translation: nil,
                    isLoading: false,
                    isInVocabulary: false,
                    onAddToVocabulary: {
                        selectedWord = nil
                    },
                    onDismiss: {
                        selectedWord = nil
                    }
                )
            }
        }
        .onAppear {
            setupSpeechManager()
            startSession()
        }
        .onDisappear {
            speechManager.stopListening()
        }
        .onChange(of: observer.currentUserLineId) { _, newId in
            guard let messageId = newId, micEnabled else { return }
            let descriptor = FetchDescriptor<SDConversationMessage>(
                predicate: #Predicate { $0.id == messageId }
            )
            if let message = try? observer.modelContext.fetch(descriptor).first {
                speechManager.startListening(
                    expectedLine: message.text,
                    language: languageCode(for: config.targetLanguage)
                )
            }
        }
    }
    
    private var bottomControls: some View {
        VStack(spacing: 16) {
            DirectorToolbar(
                onHint: {
                    observer.requestHint()
                },
                onReplay: {},
                onEnd: {
                    showEndSessionAlert = true
                }
            )
            
            if observer.currentUserLineId != nil {
                VoiceInputBar(
                    speechManager: speechManager,
                    onConfirmTap: {
                        confirmCurrentLine()
                    },
                    onSkip: {
                        skipCurrentLine()
                    }
                )
            }
        }
        .background(.bar)
    }
    
    private var headerBar: some View {
        HStack {
            Button {
                showEndSessionAlert = true
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.secondary)
                    .padding(8)
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())
            }
            
            Spacer()
            
            Text(scenarioTitle)
                .font(.headline)
                .lineLimit(1)
            
            Spacer()
            
            Color.clear.frame(width: 32, height: 32)
        }
        .padding()
        .background(.bar)
    }
    
    private var loadingOverlay: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                ProgressView()
                    .scaleEffect(1.5)
                    .tint(.white)
                
                Text("Preparing conversation...")
                    .font(.headline)
                    .foregroundColor(.white)
            }
            .padding(40)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 20))
        }
    }
    
    private func errorOverlay(message: String) -> some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.orange)
                
                Text("Something went wrong")
                    .font(.headline)
                
                Text(message)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                HStack(spacing: 16) {
                    Button("Dismiss") {
                        dismiss()
                    }
                    .buttonStyle(.bordered)
                    
                    Button("Retry") {
                        startSession()
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding(30)
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .padding(40)
        }
    }
    
    private func startSession() {
        Task {
            await observer.initializeTheaterSession(config: config)
        }
    }
    
    private func setupSpeechManager() {
        speechManager.onAllWordsMatched = {
            confirmCurrentLine()
        }
    }
    
    private func confirmCurrentLine() {
        speechManager.stopListening()
        Task {
            await observer.confirmUserLine()
        }
    }
    
    private func skipCurrentLine() {
        speechManager.stopListening()
        Task {
            await observer.skipUserLine()
        }
    }
    
    private var endSessionOverlay: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    showEndSessionAlert = false
                }
            
            VStack(spacing: 24) {
                VStack(spacing: 8) {
                    Image(systemName: "theatermask.and.paintbrush")
                        .font(.system(size: 36))
                        .foregroundStyle(.blue)
                    
                    Text("End Session?")
                        .font(.title2.bold())
                    
                    Text("Do you want to save this conversation to your history?")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                VStack(spacing: 12) {
                    Button {
                        Task {
                            await observer.endTheaterSession(save: true)
                        }
                        dismiss()
                    } label: {
                        Text("Save & Exit")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.blue)
                    
                    Button(role: .destructive) {
                        Task {
                            await observer.endTheaterSession(save: false)
                        }
                        dismiss()
                    } label: {
                        Text("Discard")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                    }
                    .buttonStyle(.bordered)
                    .tint(.red)
                    
                    Button {
                        showEndSessionAlert = false
                    } label: {
                        Text("Cancel")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 4)
                }
            }
            .padding(28)
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .shadow(color: .black.opacity(0.15), radius: 20, x: 0, y: 10)
            .padding(.horizontal, 40)
        }
        .transition(.opacity)
        .animation(.easeInOut(duration: 0.2), value: showEndSessionAlert)
    }

    private func languageCode(for language: String) -> String {
        switch language.lowercased() {
        case "spanish", "es": return "es-ES"
        case "french", "fr": return "fr-FR"
        case "german", "de": return "de-DE"
        case "italian", "it": return "it-IT"
        case "portuguese", "pt": return "pt-BR"
        case "japanese", "ja": return "ja-JP"
        case "korean", "ko": return "ko-KR"
        case "chinese", "zh": return "zh-CN"
        default: return "en-US"
        }
    }
}

// MARK: - Inner View (SwiftData @Query for messages)

private struct TheaterMessageList: View {
    let session: SDConversationSession
    
    let isGenerating: Bool
    let currentUserLineId: String?
    let speechMatchedWordCount: Int
    let onWordLongPress: (String, Int) -> Void
    
    var sortedMessages: [SDConversationMessage] {
            session.messages.sorted { $0.timestamp < $1.timestamp }
        }
    init(
            session: SDConversationSession,
            isGenerating: Bool,
            currentUserLineId: String?,
            speechMatchedWordCount: Int,
            onWordLongPress: @escaping (String, Int) -> Void
        ) {
            self.session = session
            self.isGenerating = isGenerating
            self.currentUserLineId = currentUserLineId
            self.speechMatchedWordCount = speechMatchedWordCount
            self.onWordLongPress = onWordLongPress
        }
    
    
    
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 20) {
                    Color.clear.frame(height: 20)
                    
                    ForEach(sortedMessages) { message in
                        DialogBubble(
                            text: message.text,
                            translation: message.translation,
                            roleName: message.role,
                            isUser: message.isUser,
                            highlightedWordCount: highlightedWordCount(for: message),
                            onWordLongPress: { word, wordIndex in
                                onWordLongPress(word, wordIndex)
                            }
                        )
                        .id(message.id)
                    }
                    
                    if isGenerating {
                        typingIndicator
                    }
                }
                .padding()
            }
            .onChange(of: sortedMessages.count) {
                if let last = sortedMessages.last {
                    withAnimation {
                        proxy.scrollTo(last.id, anchor: .bottom)
                    }
                }
            }
            .onChange(of: isGenerating) { _, generating in
                if generating {
                    withAnimation {
                        proxy.scrollTo("typingIndicator", anchor: .bottom)
                    }
                }
            }
        }
    }
    
    private var typingIndicator: some View {
        HStack {
            HStack(spacing: 4) {
                ForEach(0..<3) { index in
                    Circle()
                        .fill(Color.secondary)
                        .frame(width: 8, height: 8)
                        .scaleEffect(isGenerating ? 1.0 : 0.5)
                        .animation(
                            .easeInOut(duration: 0.6)
                            .repeatForever()
                            .delay(Double(index) * 0.2),
                            value: isGenerating
                        )
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(.systemGray5))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            
            Spacer()
        }
        .id("typingIndicator")
    }
    
    private func highlightedWordCount(for message: SDConversationMessage) -> Int {
        if message.id == currentUserLineId {
            return speechMatchedWordCount
        } else if message.isUser {
            return message.text.split(separator: " ").count
        }
        return 0
    }
}
