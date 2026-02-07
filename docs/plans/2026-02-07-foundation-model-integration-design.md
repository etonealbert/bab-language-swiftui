# Foundation Model Integration Design

**Date:** 2026-02-07
**Status:** Ready for Implementation

## Problem Statement

TheaterView currently uses hardcoded mock dialog data instead of the existing LLMBridge/LLMManager infrastructure. The Foundation Model integration exists in code but is never called when the theater opens.

## Goals

1. Wire Foundation Models to TheaterView so dialog is actually generated
2. Add loading/progress indicators for LLM operations
3. Add LLM testing menu in Settings for developers to test Foundation Model availability

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        TheaterView                              │
│  • Observes SDKObserver.nativeDialogLines                       │
│  • Observes SDKObserver.isGenerating                            │
│  • Observes SDKObserver.sessionInitState                        │
│  • Calls observer.generateNextExchange() on confirm             │
├─────────────────────────────────────────────────────────────────┤
│                        SDKObserver                               │
│  • @Published nativeDialogLines: [NativeDialogLine]             │
│  • @Published sessionInitState: SessionInitState                │
│  • Solo mode: Uses LLMManager → Foundation Models               │
│  • Multiplayer: Uses sdk.generate() → SDK AIProvider            │
├─────────────────────────────────────────────────────────────────┤
│                    LLMManager (existing)                         │
│  • Wraps LLMBridge                                              │
│  • Session management, memory handling                          │
├─────────────────────────────────────────────────────────────────┤
│                     LLMBridge (existing)                         │
│  • Direct Foundation Models access                               │
│  • LanguageModelSession, streaming                              │
└─────────────────────────────────────────────────────────────────┘

Settings LLM Test (standalone - bypasses SDK for testing):
┌─────────────────────────────────────────────────────────────────┐
│                      LLMTestView (NEW)                          │
│  • Simple chat UI                                               │
│  • Direct to LLMBridge (no SDK, no game logic)                  │
│  • For testing Foundation Model availability                    │
└─────────────────────────────────────────────────────────────────┘
```

## Data Models

### NativeDialogLine

```swift
struct NativeDialogLine: Identifiable, Equatable {
    let id: UUID
    let text: String
    let translation: String?
    let role: String
    let isUser: Bool
    let timestamp: Date
}
```

### SessionInitState

```swift
enum SessionInitState: Equatable {
    case idle
    case initializing
    case ready
    case error(String)
}
```

### LLMTestMessage (for Settings test view)

```swift
struct LLMTestMessage: Identifiable, Equatable {
    let id: UUID
    let content: String
    let isUser: Bool
    let timestamp: Date
}
```

## UI States

### TheaterView

| State | UI |
|-------|-----|
| `sessionInitState == .initializing` | Full-screen loading overlay with ProgressView and "Preparing conversation..." |
| `sessionInitState == .error` | Error message + retry button |
| `isGenerating == true` | Typing indicator bubble at bottom of chat |
| `sessionInitState == .ready` | Normal dialog view |

### LLMTestView

| State | UI |
|-------|-----|
| `llmAvailability != .available` | Status message explaining why LLM unavailable |
| `isGenerating == true` | Typing indicator, disabled send button |
| Normal | Chat bubbles + text input + send button |

## Dialog Generation Flow (Solo Mode)

1. User selects scenario → navigates to TheaterView
2. TheaterView.onAppear:
   - Set `sessionInitState = .initializing`
   - Show loading overlay
   - Call `observer.initializeTheaterSession(...)`
3. SDKObserver.initializeTheaterSession:
   - Initialize LLMManager with scenario/roles/languages
   - On success: `sessionInitState = .ready`
   - Generate first exchange
4. First exchange appears (AI line + suggested user line)
5. User speaks the suggested line (word-by-word matching via SpeechManager)
6. On confirm:
   - Set `isGenerating = true`
   - Call `observer.generateNextExchange()`
   - Append new AI line + new suggested user line
   - Set `isGenerating = false`
7. Repeat steps 5-6 until session ends

## Prompt Engineering

### System Prompt Template

```
You are a language learning assistant playing the role of {aiRole} in a {scenario} scenario.
The user is playing {userRole}.

RULES:
1. Respond primarily in {targetLanguage}
2. Keep responses concise (1-3 sentences)
3. Stay in character as {aiRole}
4. After your line, suggest what the user should say next
5. Format: First your dialog line, then on a new line "USER SHOULD SAY: " followed by the suggested response

Example format:
Buenos días! Qué le puedo servir?
USER SHOULD SAY: Me gustaría un café con leche, por favor.
```

### Parsing Response

Split response on "USER SHOULD SAY:" to extract:
- AI's dialog line (with translation)
- User's suggested line (with translation)

## Implementation Plan

### Phase 1: SDKObserver Updates

1. Add `NativeDialogLine` model
2. Add `SessionInitState` enum
3. Add `@Published nativeDialogLines: [NativeDialogLine]`
4. Add `@Published sessionInitState: SessionInitState`
5. Add `initializeTheaterSession()` method
6. Add `generateNextExchange()` method
7. Update prompt template to include "USER SHOULD SAY:" format

### Phase 2: TheaterView Updates

1. Remove `MockDialogLine` struct
2. Remove hardcoded dialog data
3. Observe `observer.nativeDialogLines` instead of local state
4. Add loading overlay for `sessionInitState == .initializing`
5. Add typing indicator for `isGenerating == true`
6. Add error state UI
7. Call `observer.initializeTheaterSession()` in `.onAppear`
8. Call `observer.generateNextExchange()` in `confirmCurrentLine()`

### Phase 3: Settings LLM Test Menu

1. Create `LLMTestView.swift`
2. Add `LLMTestMessage` model
3. Implement chat UI (ScrollView + bubbles)
4. Implement text input + send
5. Add typing indicator
6. Handle LLM availability states
7. Add NavigationLink in SettingsView

## Fallback Strategy

When Foundation Model is unavailable:
- Show status message in loading overlay
- Option 1: Fall back to mock data (development)
- Option 2: Show "Feature requires iOS 26+ device" message

## Testing

| Environment | Behavior |
|-------------|----------|
| Simulator (no macOS 26) | Falls back to mock or shows unavailable |
| Simulator (macOS 26 + Apple Intelligence) | Uses Foundation Models via host |
| Physical device (iOS 26+) | Native Foundation Models |
| Physical device (< iOS 26) | Shows unavailable message |

## Files to Modify

- `BringABrainLanguage/Core/SDKObserver.swift`
- `BringABrainLanguage/Features/Theater/TheaterView.swift`
- `BringABrainLanguage/Features/Settings/SettingsView.swift`

## Files to Create

- `BringABrainLanguage/Core/Models/NativeDialogLine.swift`
- `BringABrainLanguage/Features/Settings/LLMTestView.swift`
