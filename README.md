# Bring A Brain Language

A collaborative language learning iOS app where players practice conversations through AI-generated role-play dialogs. Features solo mode with on-device AI (Foundation Models) and local multiplayer via Bluetooth.

## Requirements

- iOS 18.0+
- Xcode 16+
- Swift 6
- For Foundation Models: iOS 26+ device with Apple Intelligence enabled
- For BLE multiplayer: Physical device (simulator doesn't support peripheral mode)

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        SwiftUI Views                             │
│  OnboardingFlow │ HomeView │ TheaterView │ VocabularyDashboard   │
├─────────────────────────────────────────────────────────────────┤
│                        SDKObserver                               │
│  @Published sessionState │ nativeDialogLines │ isGenerating      │
├─────────────────────────────────────────────────────────────────┤
│         BrainSDK (KMP)           │      LLMBridge (Native)       │
│  Game logic, vocabulary, sync    │  Foundation Models wrapper    │
├─────────────────────────────────────────────────────────────────┤
│    SwiftData Repositories          │    LLMManager               │
│  (UserProfile, Vocabulary, etc.)   │  Session + memory handling  │
└─────────────────────────────────────────────────────────────────┘
```

### Key Principles

1. **Headless SDK Architecture** - Game logic lives in `BabLanguageSDK` (Kotlin Multiplatform)
2. **Native LLM Integration** - Foundation Models accessed directly via Swift for solo mode
3. **SwiftUI-First** - Modern declarative UI with iOS 18+ animations
4. **Local-First** - Offline capable with optional cloud sync for premium

## Project Structure

```
BringABrainLanguage/
├── App/
│   ├── BringABrainLanguageApp.swift      # Entry point
│   └── ContentView.swift                  # Root view + MainTabView
│
├── Core/
│   ├── SDKObserver.swift                  # StateFlow → @Published bridge + native LLM
│   ├── LLMBridge/
│   │   ├── LLMBridge.swift                # Foundation Models wrapper
│   │   └── LLMManager.swift               # Session lifecycle + memory handling
│   ├── BLE/
│   │   ├── BLEConstants.swift             # Service/characteristic UUIDs
│   │   ├── BLEHostManager.swift           # CBPeripheralManager for hosting
│   │   └── BLEJoinManager.swift           # CBCentralManager for joining
│   ├── Speech/
│   │   └── SpeechManager.swift            # Word-by-word speech recognition
│   ├── Providers/
│   │   └── FoundationModelTranslationProvider.swift  # iOS 26 translation
│   ├── Models/
│   │   ├── NativeDialogLine.swift         # Dialog models for native LLM
│   │   ├── SDUserProfile.swift
│   │   ├── SDVocabularyEntry.swift
│   │   └── ...
│   └── Repositories/
│       └── SwiftDataTranslationCacheRepository.swift
│
├── Features/
│   ├── Home/
│   │   ├── HomeView.swift                 # Mode selection (Solo/Host/Join)
│   │   └── ModeCard.swift
│   ├── Lobby/
│   │   ├── SoloScenarioGridView.swift
│   │   ├── HostLobbyView.swift            # BLE host waiting room
│   │   ├── JoinScanView.swift             # BLE scan for hosts
│   │   ├── ScenarioGrid.swift
│   │   ├── ScenarioCard.swift
│   │   └── ScenarioDisplayData.swift      # Scenario with roles
│   ├── Theater/
│   │   ├── TheaterView.swift              # Active role-play with LLM generation
│   │   ├── DialogBubble.swift             # Chat bubbles with word interaction
│   │   ├── VoiceInputBar.swift            # Mic button + waveform
│   │   ├── AudioWaveformView.swift        # Audio level visualization
│   │   ├── InteractiveTextView.swift      # Word-by-word highlighting
│   │   ├── WordDetailPopover.swift        # Long-press word translation
│   │   └── DirectorToolbar.swift          # Hint, Replay, End buttons
│   ├── Vocabulary/
│   │   ├── VocabularyDashboard.swift
│   │   └── ...
│   ├── Settings/
│   │   ├── SettingsView.swift             # App settings
│   │   └── LLMTestView.swift              # Developer LLM testing chat
│   ├── Onboarding/
│   │   └── OnboardingCoordinator.swift
│   └── Paywall/
│       └── PaywallView.swift
│
└── Shared/
    └── Components/
        └── StatPill.swift
```

## Features

### Navigation Flow

```
App Launch → Onboarding (if needed) → PaywallView (soft gate)
                                            ↓
                                      MainTabView
                    ┌───────────────────────┼───────────────────────┐
                  Home                  Vocabulary              Settings
                    │                                               │
            ┌───────┼───────┐                               LLM Test (Dev)
          Solo    Host    Join
            │       │       │
      Scenarios  Waiting  Scanning
            │       │       │
            └───────┴───────┘
                    ↓
              TheaterView (TabBar hidden)
              - Loading overlay during LLM init
              - Typing indicator during generation
                    ↓
            SessionSummaryView
```

### Theater Dialog Flow (Solo Mode)

1. User selects scenario → TheaterView opens with loading overlay
2. LLM session initializes with scenario context (roles, languages)
3. AI generates first exchange: AI line + suggested user line
4. User speaks the suggested line (word-by-word green highlighting)
5. Auto-advance when 80%+ words matched, or tap to confirm
6. LLM generates next exchange with typing indicator
7. Repeat until session ends

### Voice Input (No Typing)

Users practice speaking, not composing:
1. AI generates the user's line in target language
2. Line appears with translation visible
3. User speaks the line (real-time word matching)
4. Auto-advance when all words matched
5. Skip button as fallback

### Word Translation

- Long-press any word in dialog bubbles
- Popover shows translation + part of speech
- "Add to Vocabulary" button saves for SRS review

### BLE Multiplayer

- **Host Mode**: `CBPeripheralManager` advertises game service
- **Join Mode**: `CBCentralManager` scans for hosts
- Up to 4 players per session
- Requires physical device

### Foundation Models (iOS 26+)

On-device AI using Apple's Foundation Models framework:

**Dialog Generation:**
- `LLMBridge` wraps `LanguageModelSession` for text generation
- `LLMManager` handles session lifecycle and memory pressure
- Structured prompts generate AI line + suggested user line

**Translation:**
- `@Generable` structured output for word translations
- Falls back to mock provider on older devices/simulator
- Translation cache in SwiftData

**Developer Testing:**
- Settings → Developer → LLM Test
- Simple chat interface for testing Foundation Model availability
- Shows status: Ready / Downloading / Not Supported

## Build & Run

```bash
# Build
xcodebuild -scheme BringABrainLanguage \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
  build

# Run tests
xcodebuild test -scheme BringABrainLanguage \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro'
```

## SDK Integration

The app uses `BabLanguageSDK` (Kotlin Multiplatform) for game logic, with native Swift for LLM:

```swift
@MainActor
class SDKObserver: ObservableObject {
    let sdk: BrainSDK
    private let llmManager = LLMManager.shared
    
    @Published var nativeDialogLines: [NativeDialogLine] = []
    @Published var sessionInitState: SessionInitState = .idle
    @Published var isGenerating: Bool = false
    
    func initializeTheaterSession(config: TheaterSessionConfig) async {
        sessionInitState = .initializing
        await llmManager.initialize(...)
        sessionInitState = .ready
        await generateNextExchange()
    }
    
    func generateNextExchange() async {
        isGenerating = true
        let response = try await llmManager.generate(prompt: ...)
        // Parse AI line + user line from response
        nativeDialogLines.append(...)
        isGenerating = false
    }
}
```

## Design Documents

- [Foundation Model Integration](docs/plans/2026-02-07-foundation-model-integration-design.md) - LLM integration design
- [App Redesign Design](docs/plans/2026-02-06-app-redesign-design.md) - Full architecture and implementation plan
- [iOS App Design](docs/plans/2026-02-06-ios-app-design.md) - Original design document
- [Theater Animations Design](docs/plans/2026-02-06-theater-animations-design.md) - Animation specifications

## Testing Constraints

| Feature | Simulator | Physical Device |
|---------|-----------|-----------------|
| UI Navigation | ✅ | ✅ |
| Voice Input (mock) | ✅ | ✅ |
| Voice Input (real) | ❌ | ✅ |
| BLE Peripheral | ❌ | ✅ |
| BLE Central | ❌ | ✅ |
| Foundation Models | ⚠️ (requires macOS 26 host) | ✅ (iOS 26+) |
| LLM Test View | ⚠️ | ✅ |

## License

Proprietary - All rights reserved
