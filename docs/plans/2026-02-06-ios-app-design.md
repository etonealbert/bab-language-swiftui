# Bring a Brain Language - iOS App Design Document

**Version:** 1.0  
**Date:** 2026-02-06  
**Platform:** iOS 18+ (Foundation Models: iOS 26+)  
**Framework:** SwiftUI + BabLanguageSDK (Kotlin Multiplatform)

---

## 1. Executive Summary

Bring a Brain Language is a collaborative language learning app where 1-4 players connect (offline via Bluetooth or online via WebSockets) to act out AI-generated role-play dialogs. The iOS app is a **pure UI layer** - all business logic (game states, SM-2 spaced repetition, BLE networking, AI prompts) lives in the `BabLanguageSDK` (Kotlin Multiplatform).

### Core Principles

1. **Headless SDK Architecture** - Zero business logic in Swift
2. **SwiftUI-First** - Modern declarative UI with iOS 18+ animations
3. **Local-First** - Offline capable with optional cloud sync for premium
4. **Premium Animations** - Zoom transitions, SF Symbols 6, KeyframeAnimator

---

## 2. Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                        SwiftUI Views                             │
│  OnboardingFlow │ LobbyView │ TheaterView │ VocabularyView       │
├─────────────────────────────────────────────────────────────────┤
│                        SDKObserver                               │
│  @Published sessionState │ userProfile │ vocabularyStats │ ...   │
├─────────────────────────────────────────────────────────────────┤
│                        BrainSDK                                  │
│  StateFlow → Swift Concurrency (for await)                       │
├─────────────────────────────────────────────────────────────────┤
│    SwiftData Repositories          │    IOSLLMBridge             │
│  (UserProfile, Vocabulary, etc.)   │  (Foundation Models iOS26)  │
└─────────────────────────────────────────────────────────────────┘
```

### Data Flow

1. **Views** observe `SDKObserver.@Published` properties
2. **Views** call `sdk.methodName()` for user actions
3. **SDK** updates `StateFlow` → triggers `SDKObserver` update
4. **SwiftUI** re-renders automatically

---

## 3. App Navigation Flow

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
│         ┌─────────────────────┐                                      │
│         │    MainTabView      │                                      │
│         ├─────────────────────┤                                      │
│         │ 🏠 Lobby            │──→ ScenarioGrid, DialogLibrary       │
│         │ 📚 Vocabulary       │──→ FlashcardReviewView               │
│         │ ⚙️ Settings         │──→ SettingsView                      │
│         └──────────┬──────────┘                                      │
│                    │                                                 │
│               Start Game (Zoom Transition)                           │
│                    │                                                 │
│                    ▼                                                 │
│         ┌─────────────────────┐                                      │
│         │    TheaterView      │ (fullScreenCover)                    │
│         │  DialogBubbles      │                                      │
│         │  DirectorToolbar    │                                      │
│         │  VotingOverlay      │                                      │
│         └──────────┬──────────┘                                      │
│                    │                                                 │
│               End Session                                            │
│                    │                                                 │
│                    ▼                                                 │
│         SessionSummaryView ──→ Back to Lobby                         │
└─────────────────────────────────────────────────────────────────────┘
```

---

## 4. File Structure

```
BringABrainLanguage/
├── App/
│   ├── BringABrainLanguageApp.swift      # Entry point, SDK + SwiftData setup
│   └── AppState.swift                     # App-wide navigation state
│
├── Core/
│   ├── SDKObserver.swift                  # StateFlow → @Published bridge
│   ├── Repositories/
│   │   ├── SwiftDataUserProfileRepository.swift
│   │   ├── SwiftDataVocabularyRepository.swift
│   │   ├── SwiftDataProgressRepository.swift
│   │   └── SwiftDataDialogHistoryRepository.swift
│   ├── Models/
│   │   ├── SDUserProfile.swift
│   │   ├── SDVocabularyEntry.swift
│   │   ├── SDUserProgress.swift
│   │   └── SDSavedSession.swift
│   ├── AI/
│   │   ├── IOSLLMBridge.swift             # iOS 26+ Foundation Models
│   │   └── PromptTranspiler.swift         # On-device vs cloud prompt format
│   └── Schema/
│       └── BabLanguageSchema.swift        # VersionedSchema for migrations
│
├── Features/
│   ├── Onboarding/
│   │   ├── OnboardingCoordinator.swift
│   │   ├── ProfileSetupView.swift
│   │   └── LanguageSelectionView.swift
│   │
│   ├── Paywall/
│   │   ├── PaywallView.swift
│   │   ├── SubscriptionManager.swift      # StoreKit 2
│   │   ├── PremiumGate.swift              # Inline feature gate
│   │   └── ProductButton.swift
│   │
│   ├── Lobby/
│   │   ├── LobbyView.swift
│   │   ├── ScenarioGrid.swift
│   │   ├── ScenarioCard.swift
│   │   ├── DialogLibraryView.swift
│   │   └── ConnectionSheet.swift          # Host/Join BLE modal
│   │
│   ├── Session/
│   │   ├── TheaterView.swift              # Active role-play
│   │   ├── DialogBubbleView.swift
│   │   ├── DirectorToolbar.swift          # Generate, Hint, Plot Twist
│   │   ├── VotingOverlay.swift
│   │   └── SessionSummaryView.swift
│   │
│   ├── Vocabulary/
│   │   ├── VocabularyDashboard.swift
│   │   ├── FlashcardReviewView.swift
│   │   └── WordDetailView.swift
│   │
│   └── Settings/
│       ├── SettingsView.swift
│       ├── LanguageSettingsView.swift
│       ├── LearningPreferencesView.swift
│       ├── ProfileEditView.swift
│       ├── NotificationsSettingsView.swift
│       ├── SocialLinksView.swift
│       └── AboutView.swift
│
├── Shared/
│   ├── Components/
│   │   ├── StatPill.swift
│   │   ├── ReviewBadge.swift
│   │   └── MemoryWarningBanner.swift
│   ├── Extensions/
│   │   └── Date+Extensions.swift
│   └── Theme/
│       ├── Colors.swift
│       └── Typography.swift
│
└── Resources/
    └── Assets.xcassets
```

---

## 5. SwiftData Models

### SDVocabularyEntry

```swift
@Model
final class SDVocabularyEntry {
    #Unique<SDVocabularyEntry>([\.language, \.word])
    #Index<SDVocabularyEntry>([\.language, \.nextReviewAt])
    
    @Attribute(.unique) var id: String
    var word: String
    var translation: String
    var language: String
    var partOfSpeech: String?
    var exampleSentence: String?
    
    // SM-2 SRS fields
    var masteryLevel: Int = 0           // 0-5
    var easeFactor: Float = 2.5
    var intervalDays: Int = 1
    var nextReviewAt: Date = Date()
    var totalReviews: Int = 0
    var correctReviews: Int = 0
    var firstSeenAt: Date = Date()
    var lastReviewedAt: Date?
}
```

### SDUserProfile

```swift
@Model
final class SDUserProfile {
    @Attribute(.unique) var id: String
    var displayName: String = ""
    var nativeLanguage: String = "en"
    var currentTargetLanguage: String = "es"
    var dailyGoalMinutes: Int = 15
    var voiceSpeed: String = "NORMAL"
    var showTranslations: String = "ON_TAP"
    var onboardingCompleted: Bool = false
    var createdAt: Date = Date()
    var lastActiveAt: Date = Date()
    var interestsJSON: String = "[]"
    var learningGoalsJSON: String = "[]"
    
    @Relationship(deleteRule: .cascade, inverse: \SDTargetLanguage.profile)
    var targetLanguages: [SDTargetLanguage] = []
}
```

---

## 6. SDK State → View Mapping

| SDK StateFlow | View Consumer | UI Update |
|---------------|---------------|-----------|
| `state.dialogHistory` | TheaterView | Append bubbles with KeyframeAnimator |
| `state.currentPhase` | RootView | Navigation (lobby/theater/summary) |
| `state.connectionStatus` | ConnectionSheet | Scanning/connecting states |
| `state.pendingVote` | VotingOverlay | Show/hide vote modal |
| `state.peers` | TheaterView header | Connected player avatars |
| `vocabularyStats` | LobbyView, VocabularyDashboard | Stats with numericText transition |
| `dueReviews` | VocabularyDashboard | Badge count |
| `progress` | LobbyView | XP bar, streak flame (.breathe) |

---

## 7. Animation Strategy (iOS 18+)

### Navigation Transitions

| Transition | Animation Type |
|------------|----------------|
| Lobby → Theater | `.navigationTransition(.zoom)` |
| Dialog Library → Session Detail | Zoom Transition |
| Tab switches | Morphing Tab Bar (iPad) |
| Modal sheets | Spring physics with detents |

### Micro-Animations (SF Symbols 6)

| UI Element | Symbol Effect | Trigger |
|------------|---------------|---------|
| Generate button | `.bounce` | On tap |
| Streak flame | `.breathe` | While active |
| XP counter | `.contentTransition(.numericText())` | Value change |
| Loading AI | `.rotate` (indefinite) | While generating |
| Error state | `.wiggle` | On validation failure |

### Dialog Bubble Entry (KeyframeAnimator)

```swift
KeyframeAnimator(initialValue: AnimationValues()) { values in
    DialogBubble(line: line)
        .offset(y: values.offsetY)
        .opacity(values.opacity)
        .scaleEffect(values.scale)
} keyframes: { _ in
    KeyframeTrack(\.offsetY) { SpringKeyframe(0, spring: .bouncy) }
    KeyframeTrack(\.opacity) { LinearKeyframe(1, duration: 0.2) }
    KeyframeTrack(\.scale) { SpringKeyframe(1.0, spring: .snappy) }
}
```

---

## 8. iOS 26 Foundation Model Integration

### Structured Output with @Generable

```swift
@available(iOS 26.0, *)
@Generable
struct DialogResponse: Codable {
    let textNative: String
    let textTranslated: String
    let sentiment: String?
    let corrections: [Correction]?
    let suggestedReplies: [String]?
}
```

### Memory Pressure Handling

- **WARNING**: Clear image/TTS caches
- **CRITICAL**: Release LLM session, notify SDK to throttle BLE

### Fallback Strategy

```swift
#if canImport(FoundationModels)
if #available(iOS 26.0, *) {
    // Use on-device Foundation Models
} else {
    // Fall back to MockAIProvider or Cloud
}
#endif
```

---

## 9. Paywall Architecture

### Free vs Premium Features

| Feature | Free | Premium |
|---------|------|---------|
| Solo mode (offline AI) | ✅ | ✅ |
| Local BLE multiplayer | ✅ | ✅ |
| Vocabulary flashcards | ✅ | ✅ |
| Basic scenarios (5) | ✅ | ✅ |
| All scenarios (20+) | ❌ | ✅ |
| Online multiplayer | ❌ | ✅ |
| Cloud history sync | ❌ | ✅ |

### Flow

1. **After Onboarding** → PaywallView (soft gate - can skip)
2. **Inline Gates** → PremiumGate wrapper for locked scenarios
3. **StoreKit 2** → Native subscription management
4. **Mocked Mode** → Debug toggle for development

---

## 10. Settings Structure

| Section | Items |
|---------|-------|
| **Profile** | Display name, Avatar picker |
| **Languages** | Native language, Target languages, Proficiency |
| **Learning** | Daily goal, Voice speed, Translation visibility, Interests |
| **Notifications** | Daily reminder, Reminder time, Streak reminder |
| **Share & Connect** | Referral link, Instagram, TikTok, Discord |
| **About** | Version, Rate, Privacy, Terms, Support |

---

## 11. Technology Stack Summary

| Layer | Technology |
|-------|------------|
| UI | SwiftUI (iOS 18+) |
| Animations | Zoom Transitions, KeyframeAnimator, SF Symbols 6 |
| State Bridge | SDKObserver (@Published ← StateFlow) |
| Business Logic | BabLanguageSDK (Kotlin Multiplatform) |
| Persistence | SwiftData with #Index, #Unique, VersionedSchema |
| AI (iOS 26) | Foundation Models + @Generable |
| AI (Fallback) | MockAIProvider / Cloud |
| Payments | StoreKit 2 |
| Networking | BLE via SDK, WebSocket for premium |

---

*Document Version: 1.0 - February 2026*
