import SwiftUI

struct TheaterView: View {
    let scenarioId: String
    let namespace: Namespace.ID
    
    @EnvironmentObject var observer: SDKObserver
    @Environment(\.dismiss) var dismiss
    
    @StateObject private var speechManager = SpeechManager()
    @State private var dialogLines: [MockDialogLine] = []
    @State private var currentUserLineIndex: Int?
    @State private var selectedWord: String?
    @State private var selectedWordIndex: Int?
    
    @AppStorage("micEnabled") private var micEnabled = true
    
    struct MockDialogLine: Identifiable {
        let id = UUID()
        let text: String
        let translation: String?
        let role: String
        let isUser: Bool
    }
    
    var body: some View {
        VStack(spacing: 0) {
            headerBar
            
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 20) {
                        Color.clear.frame(height: 20)
                        
                        ForEach(Array(dialogLines.enumerated()), id: \.element.id) { index, line in
                            DialogBubble(
                                text: line.text,
                                translation: line.translation,
                                roleName: line.role,
                                isUser: line.isUser,
                                highlightedWordCount: currentUserLineIndex == index ? speechManager.matchedWordCount : (line.isUser ? line.text.split(separator: " ").count : 0),
                                onWordLongPress: { word, wordIndex in
                                    selectedWord = word
                                    selectedWordIndex = wordIndex
                                }
                            )
                            .id(line.id)
                        }
                    }
                    .padding()
                }
                .onChange(of: dialogLines.count) {
                    if let last = dialogLines.last {
                        withAnimation {
                            proxy.scrollTo(last.id, anchor: .bottom)
                        }
                    }
                }
            }
            
            VStack(spacing: 16) {
                DirectorToolbar(
                    onHint: {
                        addLine("Try asking about the dark roast.", translation: nil, role: "System", isUser: false)
                    },
                    onReplay: {},
                    onEnd: { dismiss() }
                )
                
                if let userLineIndex = currentUserLineIndex {
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
            if dialogLines.isEmpty {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                    addLine(
                        "Buenos días! ¿Qué le puedo servir?",
                        translation: "Good morning! What can I get for you?",
                        role: "Barista",
                        isUser: false
                    )
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        addUserLine(
                            "Me gustaría un café con leche, por favor.",
                            translation: "I would like a latte, please."
                        )
                    }
                }
            }
        }
    }
    
    private var headerBar: some View {
        HStack {
            Button {
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
            
            Text("Scenario Active")
                .font(.headline)
            
            Spacer()
            
            Color.clear.frame(width: 32, height: 32)
        }
        .padding()
        .background(.bar)
    }
    
    private func setupSpeechManager() {
        speechManager.onAllWordsMatched = {
            confirmCurrentLine()
        }
    }
    
    private func addLine(_ text: String, translation: String?, role: String, isUser: Bool) {
        let newLine = MockDialogLine(text: text, translation: translation, role: role, isUser: isUser)
        dialogLines.append(newLine)
    }
    
    private func addUserLine(_ text: String, translation: String?) {
        let newLine = MockDialogLine(text: text, translation: translation, role: "You", isUser: true)
        dialogLines.append(newLine)
        currentUserLineIndex = dialogLines.count - 1
        
        if micEnabled {
            speechManager.startListening(expectedLine: text, language: "es-ES")
        }
    }
    
    private func confirmCurrentLine() {
        speechManager.stopListening()
        currentUserLineIndex = nil
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            addLine(
                "¡Perfecto! Son cuatro con cincuenta.",
                translation: "Perfect! That'll be four fifty.",
                role: "Barista",
                isUser: false
            )
        }
    }
    
    private func skipCurrentLine() {
        speechManager.stopListening()
        currentUserLineIndex = nil
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            addLine(
                "¿Algo más?",
                translation: "Anything else?",
                role: "Barista",
                isUser: false
            )
        }
    }
}
