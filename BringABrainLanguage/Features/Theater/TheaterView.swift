import SwiftUI

struct TheaterView: View {
    let scenarioId: String
    let scenarioTitle: String
    let namespace: Namespace.ID
    let config: TheaterSessionConfig
    
    @EnvironmentObject var observer: SDKObserver
    @Environment(\.dismiss) var dismiss
    
    @StateObject private var speechManager = SpeechManager()
    @State private var selectedWord: String?
    @State private var selectedWordIndex: Int?
    
    @AppStorage("micEnabled") private var micEnabled = true
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                headerBar
                
                dialogContent
                
                bottomControls
            }
            
            if observer.sessionInitState.isLoading {
                loadingOverlay
            }
            
            if let errorMessage = observer.sessionInitState.errorMessage {
                errorOverlay(message: errorMessage)
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
        .onChange(of: observer.currentUserLineIndex) { _, newIndex in
            if let index = newIndex, micEnabled {
                let line = observer.nativeDialogLines[index]
                speechManager.startListening(expectedLine: line.text, language: languageCode(for: config.targetLanguage))
            }
        }
    }
    
    private var dialogContent: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 20) {
                    Color.clear.frame(height: 20)
                    
                    ForEach(Array(observer.nativeDialogLines.enumerated()), id: \.element.id) { index, line in
                        DialogBubble(
                            text: line.text,
                            translation: line.translation,
                            roleName: line.role,
                            isUser: line.isUser,
                            highlightedWordCount: highlightedWordCount(for: index, line: line),
                            onWordLongPress: { word, wordIndex in
                                selectedWord = word
                                selectedWordIndex = wordIndex
                            }
                        )
                        .id(line.id)
                    }
                    
                    if observer.isGenerating {
                        typingIndicator
                    }
                }
                .padding()
            }
            .onChange(of: observer.nativeDialogLines.count) {
                if let last = observer.nativeDialogLines.last {
                    withAnimation {
                        proxy.scrollTo(last.id, anchor: .bottom)
                    }
                }
            }
            .onChange(of: observer.isGenerating) { _, isGenerating in
                if isGenerating {
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
                        .scaleEffect(typingDotScale(index: index))
                        .animation(
                            .easeInOut(duration: 0.6)
                            .repeatForever()
                            .delay(Double(index) * 0.2),
                            value: observer.isGenerating
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
    
    private func typingDotScale(index: Int) -> CGFloat {
        observer.isGenerating ? 1.0 : 0.5
    }
    
    private func highlightedWordCount(for index: Int, line: NativeDialogLine) -> Int {
        if observer.currentUserLineIndex == index {
            return speechManager.matchedWordCount
        } else if line.isUser {
            return line.text.split(separator: " ").count
        }
        return 0
    }
    
    private var bottomControls: some View {
        VStack(spacing: 16) {
            DirectorToolbar(
                onHint: {
                    observer.requestHint()
                },
                onReplay: {},
                onEnd: {
                    Task {
                        await observer.endTheaterSession()
                    }
                    dismiss()
                }
            )
            
            if observer.currentUserLineIndex != nil {
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
                Task {
                    await observer.endTheaterSession()
                }
                dismiss()
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
        observer.skipUserLine()
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
