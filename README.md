# Bring A Brain Language

A collaborative language learning iOS app where players practice conversations through AI-generated role-play dialogs. Features solo mode with on-device AI and local multiplayer via Bluetooth.

## Requirements

- iOS 18.0+
- Xcode 16+
- Swift 6
- For Foundation Models: iOS 26+ device (not simulator)
- For BLE multiplayer: Physical device (simulator doesn't support peripheral mode)

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        SwiftUI Views                             │
│  OnboardingFlow │ HomeView │ TheaterView │ VocabularyDashboard   │
├─────────────────────────────────────────────────────────────────┤
│                        SDKObserver                               │
│  @Published sessionState │ userProfile │ vocabularyStats │ ...   │
├─────────────────────────────────────────────────────────────────┤
│                        BrainSDK                                  │
│  StateFlow → Swift Concurrency (for await)                       │
├─────────────────────────────────────────────────────────────────┤
│    SwiftData Repositories          │    Native Providers         │
│  (UserProfile, Vocabulary, etc.)   │  (Foundation Models, BLE)   │
└─────────────────────────────────────────────────────────────────┘
```

### Key Principles

1. **Headless SDK Architecture** - Zero business logic in Swift; all game logic lives in `BabLanguageSDK` (Kotlin Multiplatform)
2. **SwiftUI-First** - Modern declarative UI with iOS 18+ animations
3. **Local-First** - Offline capable with optional cloud sync for premium
4. **Premium Animations** - Zoom transitions, SF Symbols 6, KeyframeAnimator

## Project Structure

```
BringABrainLanguage/
├── App/
│   ├── BringABrainLanguageApp.swift      # Entry point
│   └── ContentView.swift                  # Root view + MainTabView
│
├── Core/
│   ├── SDKObserver.swift                  # StateFlow → @Published bridge
│   ├── BLE/
│   │   ├── BLEConstants.swift             # Service/characteristic UUIDs
│   │   ├── BLEHostManager.swift           # CBPeripheralManager for hosting
│   │   └── BLEJoinManager.swift           # CBCentralManager for joining
│   ├── Speech/
│   │   └── SpeechManager.swift            # Word-by-word speech recognition
│   ├── Providers/
│   │   └── FoundationModelTranslationProvider.swift  # iOS 26 on-device AI
│   ├── Models/
│   │   ├── SDUserProfile.swift
│   │   ├── SDVocabularyEntry.swift
│   │   ├── SDTranslationCache.swift
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
│   │   └── ScenarioCard.swift
│   ├── Theater/
│   │   ├── TheaterView.swift              # Active role-play session
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
│   │   └── SettingsView.swift
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
                    │
            ┌───────┼───────┐
          Solo    Host    Join
            │       │       │
      Scenarios  Waiting  Scanning
            │       │       │
            └───────┴───────┘
                    ↓
              TheaterView (TabBar hidden)
                    ↓
            SessionSummaryView
```

### Voice Input (No Typing)

Users are learning the language, so they don't compose responses. Instead:
1. AI generates the user's line in target language
2. Line appears with translation visible
3. User speaks the line (word-by-word green highlighting)
4. Auto-advance when all words matched (80%+ similarity threshold)
5. Tap fallback if mic is disabled

### Word Translation

- Long-press any word in dialog bubbles
- Popover shows translation + part of speech
- "Add to Vocabulary" button saves for SRS review

### BLE Multiplayer

- **Host Mode**: `CBPeripheralManager` advertises game service
- **Join Mode**: `CBCentralManager` scans for hosts
- Up to 4 players per session
- Requires physical device (simulator doesn't support peripheral mode)

### Foundation Models (iOS 26+)

On-device translation using Apple's Foundation Models:
- `@Generable` structured output for translations
- Falls back to mock provider on older devices/simulator
- Translation cache in SwiftData

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

The app uses `BabLanguageSDK` (Kotlin Multiplatform) for all business logic:

```swift
// SDKObserver bridges StateFlow to SwiftUI
@MainActor
class SDKObserver: ObservableObject {
    let sdk: BrainSDK
    
    // Reactive observation with SKIE
    private func startObserving() {
        observationTasks.append(Task {
            for await state in sdk.state {
                self.sessionState = state
            }
        })
    }
}
```

## Design Documents

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
| Foundation Models | ❌ | ✅ (iOS 26+) |

## License

Proprietary - All rights reserved
