# BringABrainLanguage App Redesign - Design Document

**Version:** 2.0  
**Date:** 2026-02-06  
**Status:** Ready for Implementation  
**Supersedes:** 2026-02-06-ios-app-design.md (navigation flow, theater interaction)

---

## 1. Summary of Changes

| Area | Before | After |
|------|--------|-------|
| Navigation | MainTabView → LobbyView (nested TabView) → Scenarios → Theater | MainTabView → HomeView (mode selection) → Scenarios → Theater |
| User Input | TextField for responses | Voice input with tap fallback |
| Theater TabBar | Visible | Hidden during active session |
| Word Translation | Not implemented | Long-press word → popover |
| BLE Multiplayer | SDK-only abstraction | CoreBluetooth native implementation |
| SDK Observation | Manual refresh calls | SKIE `for await` reactive observation |

---

## 2. App Navigation Flow (Updated)

```
┌─────────────────────────────────────────────────────────────────────┐
│  App Launch → isOnboardingRequired?                                  │
│                    │         │                                       │
│                   YES        NO                                      │
│                    │         │                                       │
│                    ▼         │                                       │
│         OnboardingCoordinator                                        │
│         ┌─────────────────────┐                                      │
│         │ ProfileSetupView    │                                      │
│         │ LanguageSelectView  │                                      │
│         └──────────┬──────────┘                                      │
│                    │                                                 │
│                    ▼                                                 │
│              PaywallView (soft gate - can skip)                      │
│                    │                                                 │
│                    ▼                                                 │
│         ┌─────────────────────────────────────────┐                  │
│         │           MainTabView                   │                  │
│         ├─────────────────────────────────────────┤                  │
│         │ 🏠 Home       │ 📚 Vocabulary │ ⚙️ Settings │              │
│         └───────┬───────┴───────────────┴─────────┘                  │
│                 │                                                    │
│                 ▼                                                    │
│         ┌─────────────────────┐                                      │
│         │     HomeView        │ ◄── NEW: Mode Selection First        │
│         ├─────────────────────┤                                      │
│         │ ┌─────────────────┐ │                                      │
│         │ │   🎭 Solo Mode  │ │ ──→ SoloScenarioGridView             │
│         │ └─────────────────┘ │                                      │
│         │ ┌─────────────────┐ │                                      │
│         │ │ 📡 Host Party   │ │ ──→ HostLobbyView (BLE advertising)  │
│         │ └─────────────────┘ │                                      │
│         │ ┌─────────────────┐ │                                      │
│         │ │ 🔍 Join Party   │ │ ──→ JoinScanView (BLE scanning)      │
│         │ └─────────────────┘ │                                      │
│         └─────────────────────┘                                      │
│                    │                                                 │
│         Select Scenario (Zoom Transition)                            │
│                    │                                                 │
│                    ▼                                                 │
│         ┌─────────────────────┐                                      │
│         │    TheaterView      │ ◄── TabBar HIDDEN                    │
│         │  DialogBubbles      │ ◄── Voice input, no TextField        │
│         │  VoiceInputBar      │ ◄── NEW: Mic button + waveform       │
│         │  WordDetailPopover  │ ◄── NEW: Long-press translation      │
│         └──────────┬──────────┘                                      │
│                    │                                                 │
│               End Session                                            │
│                    │                                                 │
│                    ▼                                                 │
│         SessionSummaryView ──→ Back to Home (TabBar restored)        │
└─────────────────────────────────────────────────────────────────────┘
```

---

## 3. HomeView - Mode Selection

### Design Rationale

Users must choose their play mode **before** seeing scenarios. This allows:
- Solo mode: Immediate scenario access
- Host mode: Start BLE advertising, wait for players, then pick scenario
- Join mode: Scan for hosts, connect, wait for host to start

### UI Layout

```
┌────────────────────────────────────────┐
│            Choose Your Mode            │ ← Header
├────────────────────────────────────────┤
│ ┌────────────────────────────────────┐ │
│ │  🎭                                │ │
│ │  Solo Mode                         │ │
│ │  Practice on your own              │ │
│ │  AI plays all other roles          │ │
│ └────────────────────────────────────┘ │
│                                        │
│ ┌────────────────────────────────────┐ │
│ │  📡                                │ │
│ │  Host Party                        │ │
│ │  Start a local game                │ │
│ │  Friends join via Bluetooth        │ │
│ └────────────────────────────────────┘ │
│                                        │
│ ┌────────────────────────────────────┐ │
│ │  🔍                                │ │
│ │  Join Party                        │ │
│ │  Scan for nearby hosts             │ │
│ │  Connect and play together         │ │
│ └────────────────────────────────────┘ │
└────────────────────────────────────────┘
```

### Components

**HomeView.swift**
```swift
struct HomeView: View {
    @EnvironmentObject var sdkObserver: SDKObserver
    @State private var selectedMode: PlayMode?
    
    enum PlayMode: Identifiable {
        case solo, host, join
        var id: Self { self }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    ModeCard(
                        icon: "theatermasks.fill",
                        title: "Solo Mode",
                        subtitle: "Practice on your own",
                        description: "AI plays all other roles"
                    ) {
                        selectedMode = .solo
                    }
                    
                    ModeCard(
                        icon: "antenna.radiowaves.left.and.right",
                        title: "Host Party",
                        subtitle: "Start a local game",
                        description: "Friends join via Bluetooth"
                    ) {
                        selectedMode = .host
                    }
                    
                    ModeCard(
                        icon: "magnifyingglass",
                        title: "Join Party",
                        subtitle: "Scan for nearby hosts",
                        description: "Connect and play together"
                    ) {
                        selectedMode = .join
                    }
                }
                .padding()
            }
            .navigationTitle("Choose Your Mode")
            .navigationDestination(item: $selectedMode) { mode in
                switch mode {
                case .solo:
                    SoloScenarioGridView()
                case .host:
                    HostLobbyView()
                case .join:
                    JoinScanView()
                }
            }
        }
    }
}
```

**ModeCard.swift**
```swift
struct ModeCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let description: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 40))
                    .foregroundStyle(.accent)
                
                Text(title)
                    .font(.title2.bold())
                
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
    }
}
```

---

## 4. TheaterView - Voice Input Design

### Design Rationale

Users are **learning** the language, so they cannot compose responses. All responses are:
1. Generated by the SDK/LLM
2. Presented to user as "your line"
3. User speaks the line (or taps to confirm if mic is off)

### Voice Confirmation Flow

```
┌─────────────────────────────────────────────────────────────────┐
│  Dialog Bubbles                                                  │
│  ┌─────────────────────────────────────────────────────────────┐ │
│  │ NPC: "Hola, ¿cómo estás hoy?"                               │ │
│  │      Hello, how are you today?                               │ │
│  └─────────────────────────────────────────────────────────────┘ │
│                                                                  │
│  ┌─────────────────────────────────────────────────────────────┐ │
│  │ You: "Estoy bien, gracias. ¿Y tú?"                          │ │
│  │      I'm good, thanks. And you?                              │ │
│  │                                                              │ │
│  │      [Word-by-word highlighting as user speaks]              │ │
│  │      "Estoy" ← GREEN                                         │ │
│  │      "bien," ← waiting...                                    │ │
│  └─────────────────────────────────────────────────────────────┘ │
│                                                                  │
├─────────────────────────────────────────────────────────────────┤
│  Voice Input Bar                                                 │
│  ┌─────────────────────────────────────────────────────────────┐ │
│  │  🎤 Listening... ████████░░░░  │  [Skip] [Tap to Confirm]  │ │
│  └─────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
```

### Word-by-Word Highlighting

**Algorithm:**
1. Split user's expected line into words (normalized)
2. As user speaks, recognize words in sequence
3. When word matches (lenient: ignore accents, case, minor differences):
   - Turn word GREEN
   - Move to next word
4. When all words GREEN → auto-advance to next dialog turn

**Lenient Matching Rules:**
- Case insensitive: "Hola" = "hola"
- Accent insensitive: "cómo" = "como"
- Punctuation ignored: "gracias." = "gracias"
- Allow phonetic similarity: 80% match threshold

### Components

**VoiceInputBar.swift**
```swift
struct VoiceInputBar: View {
    @ObservedObject var speechManager: SpeechManager
    @AppStorage("micEnabled") private var micEnabled = true
    let onConfirmTap: () -> Void
    let onSkip: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            // Mic button with waveform
            Button {
                if micEnabled {
                    speechManager.toggleListening()
                } else {
                    onConfirmTap()
                }
            } label: {
                ZStack {
                    Circle()
                        .fill(speechManager.isListening ? .red : .accentColor)
                        .frame(width: 56, height: 56)
                    
                    Image(systemName: micEnabled ? "mic.fill" : "hand.tap.fill")
                        .font(.title2)
                        .foregroundStyle(.white)
                }
            }
            
            if micEnabled && speechManager.isListening {
                // Waveform visualization
                AudioWaveformView(level: speechManager.audioLevel)
                    .frame(height: 30)
            } else {
                Text(micEnabled ? "Tap to speak" : "Tap to confirm")
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Button("Skip", action: onSkip)
                .buttonStyle(.bordered)
        }
        .padding()
        .background(.ultraThinMaterial)
    }
}
```

**SpeechManager.swift**
```swift
@MainActor
class SpeechManager: ObservableObject {
    @Published var isListening = false
    @Published var audioLevel: Float = 0
    @Published var recognizedWords: [String] = []
    @Published var matchedWordCount: Int = 0
    
    private let speechRecognizer: SFSpeechRecognizer
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    
    var expectedWords: [String] = []
    var onAllWordsMatched: (() -> Void)?
    
    func startListening(expectedLine: String, language: String) {
        expectedWords = normalizeToWords(expectedLine)
        matchedWordCount = 0
        
        // Configure speech recognizer for target language
        guard let recognizer = SFSpeechRecognizer(locale: Locale(identifier: language)),
              recognizer.isAvailable else { return }
        
        // Start recognition...
        isListening = true
    }
    
    func checkWordMatch(_ spokenWord: String) {
        guard matchedWordCount < expectedWords.count else { return }
        
        let expectedWord = expectedWords[matchedWordCount]
        if lenientMatch(spoken: spokenWord, expected: expectedWord) {
            matchedWordCount += 1
            
            if matchedWordCount == expectedWords.count {
                onAllWordsMatched?()
            }
        }
    }
    
    private func lenientMatch(spoken: String, expected: String) -> Bool {
        let normalizedSpoken = spoken.lowercased()
            .folding(options: .diacriticInsensitive, locale: nil)
            .filter { $0.isLetter }
        
        let normalizedExpected = expected.lowercased()
            .folding(options: .diacriticInsensitive, locale: nil)
            .filter { $0.isLetter }
        
        // Exact match or 80%+ similarity
        return normalizedSpoken == normalizedExpected ||
               levenshteinSimilarity(normalizedSpoken, normalizedExpected) >= 0.8
    }
}
```

---

## 5. Dialog Bubble - Word Interaction

### Long-Press Word Translation

When user long-presses any word in a dialog bubble:
1. Popover appears with:
   - Word in target language (large)
   - Translation in native language
   - Part of speech (if available)
   - "Add to Vocabulary" button
2. SDK `translateWord()` called to get translation
3. If word already in vocabulary, show "Already saved" instead

### Components

**InteractiveTextView.swift**
```swift
struct InteractiveTextView: View {
    let text: String
    let translation: String
    let highlightedWordCount: Int  // For voice confirmation highlighting
    let language: String
    let onWordLongPress: (String, CGRect) -> Void
    
    var body: some View {
        // Custom text layout that:
        // 1. Renders each word as tappable element
        // 2. Applies green color to first N words (highlightedWordCount)
        // 3. Detects long-press and reports word + frame
        
        FlowLayout {
            ForEach(Array(words.enumerated()), id: \.offset) { index, word in
                WordView(
                    word: word,
                    isHighlighted: index < highlightedWordCount,
                    onLongPress: { frame in
                        onWordLongPress(word, frame)
                    }
                )
            }
        }
    }
}
```

**WordDetailPopover.swift**
```swift
struct WordDetailPopover: View {
    let word: String
    let translation: WordTranslation?
    let isLoading: Bool
    let isInVocabulary: Bool
    let onAddToVocabulary: () -> Void
    let onDismiss: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Word header
            Text(word)
                .font(.title2.bold())
            
            if isLoading {
                ProgressView()
            } else if let translation = translation {
                // Translation
                Text(translation.translatedWord)
                    .font(.headline)
                    .foregroundStyle(.secondary)
                
                // Part of speech
                if let pos = translation.partOfSpeech {
                    Text(pos)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .italic()
                }
                
                Divider()
                
                // Add to vocabulary button
                if isInVocabulary {
                    Label("Already in vocabulary", systemImage: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                } else {
                    Button {
                        onAddToVocabulary()
                    } label: {
                        Label("Add to Vocabulary", systemImage: "plus.circle.fill")
                    }
                    .buttonStyle(.borderedProminent)
                }
            } else {
                Text("Translation unavailable")
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .frame(minWidth: 200)
    }
}
```

### Updated DialogBubble.swift

```swift
struct DialogBubble: View {
    let line: DialogLine
    let isUserLine: Bool
    let highlightedWordCount: Int  // For voice confirmation
    let language: String
    
    @State private var selectedWord: String?
    @State private var wordFrame: CGRect = .zero
    @State private var translation: WordTranslation?
    @State private var isLoadingTranslation = false
    
    @EnvironmentObject var sdkObserver: SDKObserver
    
    var body: some View {
        VStack(alignment: isUserLine ? .trailing : .leading, spacing: 4) {
            // Speaker label
            Text(line.speaker)
                .font(.caption.bold())
                .foregroundStyle(.secondary)
            
            // Interactive text with word highlighting
            InteractiveTextView(
                text: line.text,
                translation: line.translation ?? "",
                highlightedWordCount: isUserLine ? highlightedWordCount : line.text.split(separator: " ").count,
                language: language,
                onWordLongPress: { word, frame in
                    selectedWord = word
                    wordFrame = frame
                    loadTranslation(for: word)
                }
            )
            .padding()
            .background(isUserLine ? Color.accentColor : Color(.systemGray5))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            
            // Translation subtitle (always visible)
            if let translation = line.translation {
                Text(translation)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .popover(isPresented: Binding(
            get: { selectedWord != nil },
            set: { if !$0 { selectedWord = nil } }
        )) {
            if let word = selectedWord {
                WordDetailPopover(
                    word: word,
                    translation: translation,
                    isLoading: isLoadingTranslation,
                    isInVocabulary: sdkObserver.sdk.isInVocabulary(word: word),
                    onAddToVocabulary: {
                        addWordToVocabulary(word)
                    },
                    onDismiss: {
                        selectedWord = nil
                    }
                )
            }
        }
    }
    
    private func loadTranslation(for word: String) {
        isLoadingTranslation = true
        Task {
            translation = try? await sdkObserver.sdk.translateWord(
                word: word,
                sentenceContext: line.text
            )
            isLoadingTranslation = false
        }
    }
    
    private func addWordToVocabulary(_ word: String) {
        guard let trans = translation else { return }
        Task {
            _ = try? await sdkObserver.sdk.addToVocabulary(
                word: word,
                translation: trans.translatedWord,
                partOfSpeech: trans.partOfSpeech,
                exampleSentence: line.text
            )
            selectedWord = nil
        }
    }
}
```

---

## 6. Hidden TabBar During Theater

### Implementation

When user enters TheaterView:
1. TabBar disappears (smooth transition)
2. Session plays fullscreen
3. On session end, TabBar reappears

**TheaterView.swift (updated)**
```swift
struct TheaterView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        // ... theater content
    }
    .toolbar(.hidden, for: .tabBar)  // Hide TabBar
    .navigationBarBackButtonHidden()
    .interactiveDismissDisabled()
}
```

**Navigation from ScenarioGrid:**
```swift
struct SoloScenarioGridView: View {
    @State private var selectedScenario: Scenario?
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 150))]) {
                ForEach(scenarios) { scenario in
                    ScenarioCard(scenario: scenario)
                        .onTapGesture {
                            selectedScenario = scenario
                        }
                }
            }
        }
        .navigationDestination(item: $selectedScenario) { scenario in
            TheaterView(scenario: scenario)
        }
        .navigationTransition(.zoom(sourceID: selectedScenario?.id, in: namespace))
    }
}
```

---

## 7. BLE Multiplayer - CoreBluetooth Implementation

### Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                         Swift Layer                              │
├─────────────────────────────────────────────────────────────────┤
│  BLEHostManager           │  BLEJoinManager                      │
│  - CBPeripheralManager    │  - CBCentralManager                  │
│  - Advertise service      │  - Scan for hosts                    │
│  - Accept connections     │  - Connect to peripheral             │
│  - Write characteristics  │  - Read characteristics              │
├─────────────────────────────────────────────────────────────────┤
│                      BabLanguageSDK                              │
│  - Game state management                                         │
│  - Turn coordination                                             │
│  - Message serialization                                         │
└─────────────────────────────────────────────────────────────────┘
```

### BLE Constants

```swift
enum BLEConstants {
    static let serviceUUID = CBUUID(string: "BAB-LANG-0001")
    static let gameStateCharacteristicUUID = CBUUID(string: "BAB-LANG-0002")
    static let playerActionCharacteristicUUID = CBUUID(string: "BAB-LANG-0003")
    static let chatMessageCharacteristicUUID = CBUUID(string: "BAB-LANG-0004")
}
```

### BLEHostManager.swift

```swift
@MainActor
class BLEHostManager: NSObject, ObservableObject {
    @Published var isAdvertising = false
    @Published var connectedPeers: [CBCentral] = []
    @Published var connectionError: Error?
    
    private var peripheralManager: CBPeripheralManager!
    private var gameStateCharacteristic: CBMutableCharacteristic!
    
    override init() {
        super.init()
        peripheralManager = CBPeripheralManager(delegate: self, queue: nil)
    }
    
    func startAdvertising(hostName: String) {
        guard peripheralManager.state == .poweredOn else { return }
        
        // Create service and characteristics
        let service = CBMutableService(type: BLEConstants.serviceUUID, primary: true)
        
        gameStateCharacteristic = CBMutableCharacteristic(
            type: BLEConstants.gameStateCharacteristicUUID,
            properties: [.read, .notify],
            value: nil,
            permissions: .readable
        )
        
        let playerActionCharacteristic = CBMutableCharacteristic(
            type: BLEConstants.playerActionCharacteristicUUID,
            properties: [.write],
            value: nil,
            permissions: .writeable
        )
        
        service.characteristics = [gameStateCharacteristic, playerActionCharacteristic]
        peripheralManager.add(service)
        
        // Start advertising
        peripheralManager.startAdvertising([
            CBAdvertisementDataServiceUUIDsKey: [BLEConstants.serviceUUID],
            CBAdvertisementDataLocalNameKey: hostName
        ])
        
        isAdvertising = true
    }
    
    func stopAdvertising() {
        peripheralManager.stopAdvertising()
        isAdvertising = false
    }
    
    func broadcastGameState(_ state: Data) {
        peripheralManager.updateValue(
            state,
            for: gameStateCharacteristic,
            onSubscribedCentrals: nil
        )
    }
}

extension BLEHostManager: CBPeripheralManagerDelegate {
    nonisolated func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        Task { @MainActor in
            if peripheral.state != .poweredOn {
                connectionError = BLEError.bluetoothNotAvailable
            }
        }
    }
    
    nonisolated func peripheralManager(
        _ peripheral: CBPeripheralManager,
        central: CBCentral,
        didSubscribeTo characteristic: CBCharacteristic
    ) {
        Task { @MainActor in
            connectedPeers.append(central)
        }
    }
    
    nonisolated func peripheralManager(
        _ peripheral: CBPeripheralManager,
        central: CBCentral,
        didUnsubscribeFrom characteristic: CBCharacteristic
    ) {
        Task { @MainActor in
            connectedPeers.removeAll { $0.identifier == central.identifier }
        }
    }
}
```

---

## 8. SDK Integration with SKIE

### Updated SDKObserver.swift

```swift
@MainActor
class SDKObserver: ObservableObject {
    let sdk: BrainSDK
    
    // Published state
    @Published var sessionState: SessionState?
    @Published var dialogHistory: [DialogLine] = []
    @Published var vocabularyEntries: [VocabularyEntry] = []
    @Published var translationCache: [String: WordTranslation] = [:]
    @Published var connectionStatus: ConnectionStatus = .disconnected
    
    private var observationTasks: [Task<Void, Never>] = []
    
    init(sdk: BrainSDK) {
        self.sdk = sdk
        startObserving()
    }
    
    private func startObserving() {
        // Observe session state
        observationTasks.append(Task {
            for await state in sdk.sessionState {
                self.sessionState = state
            }
        })
        
        // Observe dialog history
        observationTasks.append(Task {
            for await history in sdk.dialogHistory {
                self.dialogHistory = history
            }
        })
        
        // Observe vocabulary
        observationTasks.append(Task {
            for await entries in sdk.vocabularyEntries {
                self.vocabularyEntries = entries
            }
        })
        
        // Observe translation cache
        observationTasks.append(Task {
            for await cache in sdk.translationCache {
                self.translationCache = cache
            }
        })
        
        // Observe connection status
        observationTasks.append(Task {
            for await status in sdk.connectionStatus {
                self.connectionStatus = status
            }
        })
    }
    
    deinit {
        observationTasks.forEach { $0.cancel() }
    }
}
```

---

## 9. Translation Provider - Foundation Models

### FoundationModelTranslationProvider.swift

```swift
#if canImport(FoundationModels)
import FoundationModels

@available(iOS 26.0, *)
@Generable
struct TranslationResponse: Codable {
    let translatedWord: String
    let partOfSpeech: String?
    let definition: String?
    let exampleUsage: String?
}

@available(iOS 26.0, *)
class FoundationModelTranslationProvider {
    private let session: LanguageModelSession
    
    init() async throws {
        let model = SystemLanguageModel.default
        guard model.isAvailable else {
            throw TranslationError.modelNotAvailable
        }
        session = LanguageModelSession(model: model)
    }
    
    func translate(
        word: String,
        from sourceLanguage: String,
        to targetLanguage: String,
        context: String?
    ) async throws -> TranslationResponse {
        let prompt = """
        Translate the word "\(word)" from \(sourceLanguage) to \(targetLanguage).
        \(context.map { "Context: \($0)" } ?? "")
        
        Provide: translation, part of speech, brief definition, example usage.
        """
        
        return try await session.respond(to: prompt, generating: TranslationResponse.self)
    }
}
#endif
```

### TranslationCacheRepository.swift

```swift
import SwiftData

@Model
final class SDTranslationCache {
    @Attribute(.unique) var cacheKey: String  // "word:sourceLang:targetLang"
    var translatedWord: String
    var partOfSpeech: String?
    var definition: String?
    var cachedAt: Date
    
    init(cacheKey: String, translatedWord: String, partOfSpeech: String?, definition: String?) {
        self.cacheKey = cacheKey
        self.translatedWord = translatedWord
        self.partOfSpeech = partOfSpeech
        self.definition = definition
        self.cachedAt = Date()
    }
}

class SwiftDataTranslationCacheRepository {
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    func getCached(word: String, from: String, to: String) -> SDTranslationCache? {
        let key = "\(word):\(from):\(to)"
        let descriptor = FetchDescriptor<SDTranslationCache>(
            predicate: #Predicate { $0.cacheKey == key }
        )
        return try? modelContext.fetch(descriptor).first
    }
    
    func cache(word: String, from: String, to: String, translation: TranslationResponse) {
        let key = "\(word):\(from):\(to)"
        let entry = SDTranslationCache(
            cacheKey: key,
            translatedWord: translation.translatedWord,
            partOfSpeech: translation.partOfSpeech,
            definition: translation.definition
        )
        modelContext.insert(entry)
        try? modelContext.save()
    }
}
```

---

## 10. File Structure (Updated)

```
BringABrainLanguage/
├── App/
│   ├── BringABrainLanguageApp.swift
│   └── ContentView.swift
│
├── Core/
│   ├── SDKObserver.swift                  # UPDATE: SKIE for await
│   ├── BLE/
│   │   ├── BLEHostManager.swift           # NEW
│   │   ├── BLEJoinManager.swift           # NEW
│   │   └── BLEConstants.swift             # NEW
│   ├── Speech/
│   │   └── SpeechManager.swift            # NEW
│   ├── Providers/
│   │   └── FoundationModelTranslationProvider.swift  # NEW
│   └── Repositories/
│       └── SwiftDataTranslationCacheRepository.swift # NEW
│
├── Features/
│   ├── Home/
│   │   ├── HomeView.swift                 # NEW: Mode selection
│   │   └── ModeCard.swift                 # NEW
│   │
│   ├── Lobby/
│   │   ├── SoloScenarioGridView.swift     # RENAME from LobbyView
│   │   ├── HostLobbyView.swift            # NEW
│   │   ├── JoinScanView.swift             # NEW
│   │   ├── ScenarioCard.swift             # KEEP
│   │   └── ConnectionSheet.swift          # DELETE (replaced by Host/Join views)
│   │
│   ├── Theater/
│   │   ├── TheaterView.swift              # UPDATE: voice input, hidden TabBar
│   │   ├── DialogBubble.swift             # UPDATE: word interaction
│   │   ├── InteractiveTextView.swift      # NEW
│   │   ├── WordDetailPopover.swift        # NEW
│   │   ├── VoiceInputBar.swift            # NEW
│   │   └── AudioWaveformView.swift        # NEW
│   │
│   └── ... (rest unchanged)
│
└── Shared/
    └── ... (unchanged)
```

---

## 11. Implementation Order

### Phase 1: Core Infrastructure (Day 1)
1. `BLEConstants.swift`
2. `SpeechManager.swift`
3. `SDKObserver.swift` (SKIE update)

### Phase 2: Mode Selection (Day 1-2)
4. `HomeView.swift`
5. `ModeCard.swift`
6. `SoloScenarioGridView.swift` (refactor from LobbyView)
7. Update `MainTabView` to use HomeView

### Phase 3: BLE Multiplayer (Day 2)
8. `BLEHostManager.swift`
9. `BLEJoinManager.swift`
10. `HostLobbyView.swift`
11. `JoinScanView.swift`

### Phase 4: Theater Voice Input (Day 3)
12. `VoiceInputBar.swift`
13. `AudioWaveformView.swift`
14. `InteractiveTextView.swift`
15. `WordDetailPopover.swift`
16. Update `DialogBubble.swift`
17. Update `TheaterView.swift`

### Phase 5: Translation Provider (Day 4)
18. `FoundationModelTranslationProvider.swift`
19. `SwiftDataTranslationCacheRepository.swift`
20. `SDTranslationCache.swift` (SwiftData model)

### Phase 6: Testing & Polish (Day 5)
21. Unit tests for SpeechManager, BLE managers
22. UI tests for navigation flow
23. Integration testing on physical device (BLE + Foundation Models)

---

## 12. Testing Constraints

| Feature | Simulator | Physical Device |
|---------|-----------|-----------------|
| Mode Selection UI | ✅ | ✅ |
| Voice Input (mock) | ✅ | ✅ |
| Voice Input (real) | ❌ | ✅ |
| BLE Peripheral | ❌ | ✅ |
| BLE Central | ❌ | ✅ |
| Foundation Models | ❌ | ✅ (iOS 26+) |
| Word Translation | ✅ (SDK mock) | ✅ |
| TabBar hiding | ✅ | ✅ |

---

## 13. SDK API Summary (from vocabulary-and-translation-guide.md)

```swift
// Translation
sdk.translateWord(word: String, sentenceContext: String?) async throws -> WordTranslation

// Vocabulary
sdk.addToVocabulary(word: String, translation: String, partOfSpeech: String?, exampleSentence: String?) async throws -> VocabularyEntry
sdk.isInVocabulary(word: String, language: String?) -> Bool
sdk.getVocabularyEntry(word: String, language: String?) -> VocabularyEntry?
sdk.removeFromVocabulary(word: String, language: String?) async throws

// StateFlows (SKIE - use for await)
sdk.vocabularyEntries: StateFlow<[VocabularyEntry]>
sdk.translationCache: StateFlow<[String: WordTranslation]>
sdk.sessionState: StateFlow<SessionState?>
sdk.dialogHistory: StateFlow<[DialogLine]>
sdk.connectionStatus: StateFlow<ConnectionStatus>
```

---

*Document Version: 2.0 - February 2026*  
*Ready for Implementation*
