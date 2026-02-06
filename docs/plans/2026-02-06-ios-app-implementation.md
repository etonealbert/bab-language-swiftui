# Bring a Brain Language - iOS Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Build the complete iOS frontend for "Bring a Brain Language" - a collaborative language learning app using SwiftUI and the BabLanguageSDK.

**Architecture:** Headless SDK pattern where BabLanguageSDK (Kotlin Multiplatform) owns all business logic. SwiftUI is pure presentation. SDKObserver bridges Kotlin StateFlow to SwiftUI @Published. SwiftData provides persistence via repository injection.

**Tech Stack:** SwiftUI (iOS 18+), SwiftData, BabLanguageSDK, StoreKit 2, Foundation Models (iOS 26+)

**Reference Docs:**
- Design Document: `docs/plans/2026-02-06-ios-app-design.md`
- SDK Integration: `BabLanguageSDK-docs/integration-guide.md`
- SDK Architecture: `BabLanguageSDK-docs/sdk-architecture.md`
- CoreData Patterns: `BabLanguageSDK-docs/coredata-persistence-guide.md`
- Foundation Models: `BabLanguageSDK-docs/ios-foundation-model-integration.md`
- Animation Research: `iOS 18 Animation Enhancements Research.txt`
- SwiftData Research: `SwiftData Research and Usage.txt`

---

## Phase 1: Foundation (SwiftData + SDK Setup)

### Task 1.1: Clean Up Xcode Template

**Files:**
- Delete: `BringABrainLanguage/Item.swift`
- Modify: `BringABrainLanguage/BringABrainLanguageApp.swift`
- Modify: `BringABrainLanguage/ContentView.swift`

**Step 1: Delete the template Item.swift**

```bash
rm BringABrainLanguage/Item.swift
```

**Step 2: Replace BringABrainLanguageApp.swift with minimal shell**

```swift
import SwiftUI

@main
struct BringABrainLanguageApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
```

**Step 3: Replace ContentView.swift with placeholder**

```swift
import SwiftUI

struct ContentView: View {
    var body: some View {
        Text("Bring a Brain Language")
            .font(.largeTitle)
    }
}

#Preview {
    ContentView()
}
```

**Step 4: Build to verify clean state**

Run: `Cmd+B` in Xcode or `xcodebuild -scheme BringABrainLanguage build`
Expected: Build succeeds with no errors

**Step 5: Commit**

```bash
git add -A
git commit -m "chore: clean up Xcode template, remove Item.swift"
```

---

### Task 1.2: Create SwiftData Models

**Files:**
- Create: `BringABrainLanguage/Core/Models/SDUserProfile.swift`
- Create: `BringABrainLanguage/Core/Models/SDTargetLanguage.swift`
- Create: `BringABrainLanguage/Core/Models/SDVocabularyEntry.swift`
- Create: `BringABrainLanguage/Core/Models/SDUserProgress.swift`
- Create: `BringABrainLanguage/Core/Models/SDSavedSession.swift`
- Create: `BringABrainLanguage/Core/Models/SDDialogLine.swift`

**Step 1: Create Core/Models directory**

```bash
mkdir -p BringABrainLanguage/Core/Models
```

**Step 2: Create SDTargetLanguage.swift**

```swift
import Foundation
import SwiftData

@Model
final class SDTargetLanguage {
    var code: String = ""
    var proficiencyLevel: String = "A1"
    var startedAt: Date = Date()
    
    var profile: SDUserProfile?
    
    init(code: String, proficiencyLevel: String = "A1", startedAt: Date = Date()) {
        self.code = code
        self.proficiencyLevel = proficiencyLevel
        self.startedAt = startedAt
    }
}
```

**Step 3: Create SDUserProfile.swift**

```swift
import Foundation
import SwiftData

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
    
    init(id: String = UUID().uuidString) {
        self.id = id
    }
}
```

**Step 4: Create SDVocabularyEntry.swift**

```swift
import Foundation
import SwiftData

@Model
final class SDVocabularyEntry {
    @Attribute(.unique) var id: String
    var word: String = ""
    var translation: String = ""
    var language: String = ""
    var partOfSpeech: String?
    var exampleSentence: String?
    var audioUrl: String?
    
    // SM-2 SRS fields
    var masteryLevel: Int = 0
    var easeFactor: Float = 2.5
    var intervalDays: Int = 1
    var nextReviewAt: Date = Date()
    var totalReviews: Int = 0
    var correctReviews: Int = 0
    var firstSeenInDialogId: String?
    var firstSeenAt: Date = Date()
    var lastReviewedAt: Date?
    
    init(id: String = UUID().uuidString, word: String, translation: String, language: String) {
        self.id = id
        self.word = word
        self.translation = translation
        self.language = language
    }
}
```

**Step 5: Create SDUserProgress.swift**

```swift
import Foundation
import SwiftData

@Model
final class SDUserProgress {
    @Attribute(.unique) var id: String
    var language: String = ""
    var currentStreak: Int = 0
    var longestStreak: Int = 0
    var lastActivityDate: String = ""
    var todayMinutes: Int = 0
    var totalXP: Int = 0
    var weeklyXP: Int = 0
    var currentLevel: Int = 1
    var totalWordsLearned: Int = 0
    var wordsDueForReview: Int = 0
    var vocabularyMasteryPercent: Float = 0.0
    var totalSessions: Int = 0
    var totalMinutesPlayed: Int = 0
    var soloSessions: Int = 0
    var multiplayerSessions: Int = 0
    var estimatedCEFR: String = "A1"
    
    init(id: String = UUID().uuidString, language: String) {
        self.id = id
        self.language = language
    }
}
```

**Step 6: Create SDDialogLine.swift**

```swift
import Foundation
import SwiftData

@Model
final class SDDialogLine {
    @Attribute(.unique) var id: String
    var speakerId: String = ""
    var roleName: String = ""
    var textNative: String = ""
    var textTranslated: String = ""
    var timestamp: Date = Date()
    
    var session: SDSavedSession?
    
    init(id: String = UUID().uuidString, speakerId: String, roleName: String, textNative: String, textTranslated: String) {
        self.id = id
        self.speakerId = speakerId
        self.roleName = roleName
        self.textNative = textNative
        self.textTranslated = textTranslated
    }
}
```

**Step 7: Create SDSavedSession.swift**

```swift
import Foundation
import SwiftData

@Model
final class SDSavedSession {
    @Attribute(.unique) var id: String
    var scenarioId: String = ""
    var scenarioName: String = ""
    var playedAt: Date = Date()
    var durationMinutes: Int = 0
    var xpEarned: Int = 0
    
    @Relationship(deleteRule: .cascade, inverse: \SDDialogLine.session)
    var dialogLines: [SDDialogLine] = []
    
    init(id: String = UUID().uuidString, scenarioId: String, scenarioName: String) {
        self.id = id
        self.scenarioId = scenarioId
        self.scenarioName = scenarioName
    }
}
```

**Step 8: Build to verify models compile**

Run: `Cmd+B` in Xcode
Expected: Build succeeds

**Step 9: Commit**

```bash
git add -A
git commit -m "feat: add SwiftData models for user profile, vocabulary, progress, and sessions"
```

---

### Task 1.3: Create SwiftData Schema and Container Setup

**Files:**
- Create: `BringABrainLanguage/Core/Schema/BabLanguageSchema.swift`
- Modify: `BringABrainLanguage/BringABrainLanguageApp.swift`

**Step 1: Create Schema directory and file**

```bash
mkdir -p BringABrainLanguage/Core/Schema
```

**Step 2: Create BabLanguageSchema.swift**

```swift
import Foundation
import SwiftData

enum BabLanguageSchemaV1: VersionedSchema {
    static var versionIdentifier = Schema.Version(1, 0, 0)
    
    static var models: [any PersistentModel.Type] {
        [
            SDUserProfile.self,
            SDTargetLanguage.self,
            SDVocabularyEntry.self,
            SDUserProgress.self,
            SDSavedSession.self,
            SDDialogLine.self
        ]
    }
}

enum BabLanguageMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [BabLanguageSchemaV1.self]
    }
    
    static var stages: [MigrationStage] {
        []
    }
}
```

**Step 3: Update BringABrainLanguageApp.swift with ModelContainer**

```swift
import SwiftUI
import SwiftData

@main
struct BringABrainLanguageApp: App {
    
    let modelContainer: ModelContainer
    
    init() {
        do {
            let schema = Schema(BabLanguageSchemaV1.models)
            let modelConfiguration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false
            )
            modelContainer = try ModelContainer(
                for: schema,
                migrationPlan: BabLanguageMigrationPlan.self,
                configurations: [modelConfiguration]
            )
        } catch {
            fatalError("Could not initialize ModelContainer: \(error)")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(modelContainer)
    }
}
```

**Step 4: Build and run to verify container initializes**

Run: `Cmd+R` in Xcode
Expected: App launches without crash

**Step 5: Commit**

```bash
git add -A
git commit -m "feat: add SwiftData schema versioning and ModelContainer setup"
```

---

### Task 1.4: Create SDKObserver Bridge

**Files:**
- Create: `BringABrainLanguage/Core/SDKObserver.swift`

**Step 1: Create SDKObserver.swift**

```swift
import SwiftUI
import BabLanguageSDK

@MainActor
final class SDKObserver: ObservableObject {
    
    // MARK: - SDK Reference
    let sdk: BrainSDK
    
    // MARK: - Published State (from SDK StateFlows)
    @Published var sessionState: SessionState
    @Published var userProfile: UserProfile?
    @Published var vocabularyStats: VocabularyStats
    @Published var progress: UserProgress?
    @Published var dueReviews: [VocabularyEntry] = []
    
    // MARK: - UI State
    @Published var isGenerating: Bool = false
    @Published var showMemoryWarningBanner: Bool = false
    
    // MARK: - Derived State
    var isOnboardingRequired: Bool {
        sdk.isOnboardingRequired()
    }
    
    var isInActiveSession: Bool {
        sessionState.currentPhase == .active
    }
    
    var hasPendingVote: Bool {
        sessionState.pendingVote != nil
    }
    
    // MARK: - Private
    private var observationTasks: [Task<Void, Never>] = []
    
    // MARK: - Initialization
    
    init(sdk: BrainSDK = BrainSDK()) {
        self.sdk = sdk
        self.sessionState = sdk.state.value
        self.userProfile = sdk.userProfile.value
        self.vocabularyStats = sdk.vocabularyStats.value
        self.progress = sdk.progress.value
        
        startObserving()
    }
    
    // MARK: - StateFlow Observation
    
    private func startObserving() {
        observationTasks.append(Task {
            for await state in sdk.state {
                self.sessionState = state
                self.isGenerating = false
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
            for await prog in sdk.progress {
                self.progress = prog
            }
        })
        
        observationTasks.append(Task {
            for await reviews in sdk.dueReviews {
                self.dueReviews = reviews
            }
        })
    }
    
    // MARK: - SDK Actions
    
    func generate() {
        isGenerating = true
        sdk.generate()
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
        await sdk.endSession()
    }
    
    func completeOnboarding(profile: UserProfile) async {
        await sdk.completeOnboarding(profile: profile)
    }
    
    func recordReview(entryId: String, quality: ReviewQuality) async {
        await sdk.recordVocabularyReview(entryId: entryId, quality: quality)
    }
    
    func requestHint(level: HintLevel = .starterWords) {
        sdk.requestHint(level: level)
    }
    
    func castVote(approve: Bool) {
        sdk.castVote(approve: approve)
    }
    
    // MARK: - Cleanup
    
    deinit {
        observationTasks.forEach { $0.cancel() }
    }
}
```

**Step 2: Build to verify (will fail if SDK not imported correctly)**

Run: `Cmd+B` in Xcode
Expected: Build succeeds (assuming BabLanguageSDK is added via SPM)

**Step 3: Commit**

```bash
git add -A
git commit -m "feat: add SDKObserver bridge for StateFlow to @Published"
```

---

### Task 1.5: Integrate SDKObserver into App

**Files:**
- Modify: `BringABrainLanguage/BringABrainLanguageApp.swift`
- Modify: `BringABrainLanguage/ContentView.swift`

**Step 1: Update BringABrainLanguageApp.swift**

```swift
import SwiftUI
import SwiftData
import BabLanguageSDK

@main
struct BringABrainLanguageApp: App {
    
    let modelContainer: ModelContainer
    @StateObject private var observer: SDKObserver
    
    init() {
        // Initialize ModelContainer
        do {
            let schema = Schema(BabLanguageSchemaV1.models)
            let modelConfiguration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false
            )
            modelContainer = try ModelContainer(
                for: schema,
                migrationPlan: BabLanguageMigrationPlan.self,
                configurations: [modelConfiguration]
            )
        } catch {
            fatalError("Could not initialize ModelContainer: \(error)")
        }
        
        // Initialize SDK and Observer
        let sdk = BrainSDK()
        _observer = StateObject(wrappedValue: SDKObserver(sdk: sdk))
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(observer)
        }
        .modelContainer(modelContainer)
    }
}
```

**Step 2: Update ContentView.swift to use observer**

```swift
import SwiftUI

struct ContentView: View {
    @EnvironmentObject var observer: SDKObserver
    
    var body: some View {
        Group {
            if observer.isOnboardingRequired {
                Text("Onboarding Required")
                    .font(.title)
            } else {
                Text("Welcome to Bring a Brain!")
                    .font(.title)
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(SDKObserver())
}
```

**Step 3: Build and run**

Run: `Cmd+R` in Xcode
Expected: App launches and shows appropriate text based on onboarding state

**Step 4: Commit**

```bash
git add -A
git commit -m "feat: integrate SDKObserver into app entry point"
```

---

## Phase 2: Onboarding Flow

### Task 2.1: Create Onboarding Coordinator

**Files:**
- Create: `BringABrainLanguage/Features/Onboarding/OnboardingCoordinator.swift`
- Create: `BringABrainLanguage/Features/Onboarding/OnboardingStep.swift`

**Step 1: Create Onboarding directory**

```bash
mkdir -p BringABrainLanguage/Features/Onboarding
```

**Step 2: Create OnboardingStep.swift**

```swift
import Foundation

enum OnboardingStep: Int, CaseIterable {
    case welcome = 0
    case profile = 1
    case languages = 2
    case interests = 3
    case complete = 4
    
    var title: String {
        switch self {
        case .welcome: return "Welcome"
        case .profile: return "About You"
        case .languages: return "Languages"
        case .interests: return "Interests"
        case .complete: return "All Set!"
        }
    }
    
    var progress: Double {
        Double(rawValue) / Double(OnboardingStep.allCases.count - 1)
    }
}
```

**Step 3: Create OnboardingCoordinator.swift**

```swift
import SwiftUI

struct OnboardingCoordinator: View {
    @EnvironmentObject var observer: SDKObserver
    @State private var currentStep: OnboardingStep = .welcome
    
    // Collected data
    @State private var displayName: String = ""
    @State private var nativeLanguage: String = "en"
    @State private var targetLanguage: String = "es"
    @State private var proficiencyLevel: String = "A1"
    @State private var selectedInterests: Set<String> = []
    @State private var dailyGoalMinutes: Int = 15
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Progress bar
                ProgressView(value: currentStep.progress)
                    .tint(.purple)
                    .padding(.horizontal)
                
                // Content
                TabView(selection: $currentStep) {
                    WelcomeStepView(onContinue: nextStep)
                        .tag(OnboardingStep.welcome)
                    
                    ProfileStepView(
                        displayName: $displayName,
                        onContinue: nextStep
                    )
                    .tag(OnboardingStep.profile)
                    
                    LanguageStepView(
                        nativeLanguage: $nativeLanguage,
                        targetLanguage: $targetLanguage,
                        proficiencyLevel: $proficiencyLevel,
                        onContinue: nextStep
                    )
                    .tag(OnboardingStep.languages)
                    
                    InterestsStepView(
                        selectedInterests: $selectedInterests,
                        dailyGoalMinutes: $dailyGoalMinutes,
                        onContinue: nextStep
                    )
                    .tag(OnboardingStep.interests)
                    
                    CompleteStepView(onFinish: completeOnboarding)
                        .tag(OnboardingStep.complete)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut, value: currentStep)
            }
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    private func nextStep() {
        guard let nextIndex = OnboardingStep(rawValue: currentStep.rawValue + 1) else {
            return
        }
        withAnimation {
            currentStep = nextIndex
        }
    }
    
    private func completeOnboarding() {
        Task {
            // Build profile from collected data
            // Call observer.completeOnboarding(profile:)
        }
    }
}

// MARK: - Step Views (Placeholders)

struct WelcomeStepView: View {
    let onContinue: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: "brain.head.profile")
                .font(.system(size: 80))
                .foregroundStyle(.purple.gradient)
            
            Text("Bring a Brain")
                .font(.largeTitle.bold())
            
            Text("Learn languages through\nimmersive role-play")
                .font(.title3)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            
            Spacer()
            
            Button("Get Started") {
                onContinue()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            
            Spacer().frame(height: 40)
        }
        .padding()
    }
}

struct ProfileStepView: View {
    @Binding var displayName: String
    let onContinue: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            Text("What should we call you?")
                .font(.title2.bold())
            
            TextField("Your name", text: $displayName)
                .textFieldStyle(.roundedBorder)
                .padding(.horizontal, 40)
            
            Spacer()
            
            Button("Continue") {
                onContinue()
            }
            .buttonStyle(.borderedProminent)
            .disabled(displayName.isEmpty)
        }
        .padding()
    }
}

struct LanguageStepView: View {
    @Binding var nativeLanguage: String
    @Binding var targetLanguage: String
    @Binding var proficiencyLevel: String
    let onContinue: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            Text("Set up your languages")
                .font(.title2.bold())
            
            // Language pickers will go here
            Text("Language selection UI")
                .foregroundStyle(.secondary)
            
            Spacer()
            
            Button("Continue") {
                onContinue()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}

struct InterestsStepView: View {
    @Binding var selectedInterests: Set<String>
    @Binding var dailyGoalMinutes: Int
    let onContinue: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            Text("What interests you?")
                .font(.title2.bold())
            
            // Interest chips will go here
            Text("Interests selection UI")
                .foregroundStyle(.secondary)
            
            Spacer()
            
            Button("Continue") {
                onContinue()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}

struct CompleteStepView: View {
    let onFinish: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundStyle(.green)
            
            Text("You're all set!")
                .font(.largeTitle.bold())
            
            Text("Let's start learning")
                .font(.title3)
                .foregroundStyle(.secondary)
            
            Spacer()
            
            Button("Start Learning") {
                onFinish()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            
            Spacer().frame(height: 40)
        }
        .padding()
    }
}
```

**Step 4: Build to verify**

Run: `Cmd+B` in Xcode
Expected: Build succeeds

**Step 5: Commit**

```bash
git add -A
git commit -m "feat: add onboarding coordinator with multi-step flow"
```

---

### Task 2.2: Wire Onboarding to Root Navigation

**Files:**
- Create: `BringABrainLanguage/Features/Lobby/LobbyView.swift`
- Modify: `BringABrainLanguage/ContentView.swift`

**Step 1: Create Lobby directory and placeholder**

```bash
mkdir -p BringABrainLanguage/Features/Lobby
```

**Step 2: Create LobbyView.swift placeholder**

```swift
import SwiftUI

struct LobbyView: View {
    @EnvironmentObject var observer: SDKObserver
    
    var body: some View {
        NavigationStack {
            VStack {
                Text("Welcome, \(observer.userProfile?.displayName ?? "Learner")!")
                    .font(.title)
                
                Spacer()
                
                Text("Lobby - Coming Soon")
                    .foregroundStyle(.secondary)
                
                Spacer()
            }
            .navigationTitle("Home")
        }
    }
}

#Preview {
    LobbyView()
        .environmentObject(SDKObserver())
}
```

**Step 3: Update ContentView.swift for root navigation**

```swift
import SwiftUI

struct ContentView: View {
    @EnvironmentObject var observer: SDKObserver
    
    var body: some View {
        Group {
            if observer.isOnboardingRequired {
                OnboardingCoordinator()
            } else {
                MainTabView()
            }
        }
    }
}

struct MainTabView: View {
    var body: some View {
        TabView {
            LobbyView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
            
            Text("Vocabulary")
                .tabItem {
                    Label("Vocabulary", systemImage: "book.fill")
                }
            
            Text("Settings")
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(SDKObserver())
}
```

**Step 4: Build and run**

Run: `Cmd+R` in Xcode
Expected: App shows onboarding or tab view based on SDK state

**Step 5: Commit**

```bash
git add -A
git commit -m "feat: wire onboarding to root navigation with tab view"
```

---

## Phase 3: Paywall

### Task 3.1: Create SubscriptionManager

**Files:**
- Create: `BringABrainLanguage/Features/Paywall/SubscriptionManager.swift`
- Create: `BringABrainLanguage/Features/Paywall/SubscriptionStatus.swift`

**Step 1: Create Paywall directory**

```bash
mkdir -p BringABrainLanguage/Features/Paywall
```

**Step 2: Create SubscriptionStatus.swift**

```swift
import Foundation

enum SubscriptionStatus: Equatable {
    case unknown
    case notSubscribed
    case subscribed
}

enum SubscriptionError: Error {
    case verificationFailed
    case purchaseFailed
    case productNotFound
}
```

**Step 3: Create SubscriptionManager.swift**

```swift
import StoreKit
import SwiftUI

@MainActor
final class SubscriptionManager: ObservableObject {
    
    static let shared = SubscriptionManager()
    
    // MARK: - Published State
    @Published private(set) var subscriptionStatus: SubscriptionStatus = .unknown
    @Published private(set) var availableProducts: [Product] = []
    @Published private(set) var isLoading: Bool = false
    
    // MARK: - Product IDs
    private let productIDs = [
        "com.bablabs.bringabrain.monthly",
        "com.bablabs.bringabrain.yearly"
    ]
    
    // MARK: - Debug Mode
    #if DEBUG
    var isMockedPremium: Bool = false {
        didSet {
            subscriptionStatus = isMockedPremium ? .subscribed : .notSubscribed
            notifyStatusChange()
        }
    }
    #endif
    
    // MARK: - Initialization
    
    private init() {
        Task {
            await loadProducts()
            await updateSubscriptionStatus()
            await listenForTransactions()
        }
    }
    
    // MARK: - Load Products
    
    func loadProducts() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            availableProducts = try await Product.products(for: productIDs)
                .sorted { $0.price < $1.price }
        } catch {
            print("Failed to load products: \(error)")
        }
    }
    
    // MARK: - Purchase
    
    func purchase(_ product: Product) async throws -> Bool {
        let result = try await product.purchase()
        
        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            await transaction.finish()
            await updateSubscriptionStatus()
            return true
            
        case .userCancelled:
            return false
            
        case .pending:
            return false
            
        @unknown default:
            return false
        }
    }
    
    // MARK: - Restore Purchases
    
    func restorePurchases() async {
        await AppStore.sync()
        await updateSubscriptionStatus()
    }
    
    // MARK: - Subscription Status
    
    func updateSubscriptionStatus() async {
        #if DEBUG
        if isMockedPremium {
            subscriptionStatus = .subscribed
            notifyStatusChange()
            return
        }
        #endif
        
        var hasActiveSubscription = false
        
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result {
                if productIDs.contains(transaction.productID) {
                    hasActiveSubscription = true
                    break
                }
            }
        }
        
        subscriptionStatus = hasActiveSubscription ? .subscribed : .notSubscribed
        notifyStatusChange()
    }
    
    // MARK: - Transaction Listener
    
    private func listenForTransactions() async {
        for await result in Transaction.updates {
            if case .verified(let transaction) = result {
                await transaction.finish()
                await updateSubscriptionStatus()
            }
        }
    }
    
    // MARK: - Notify SDK
    
    private func notifyStatusChange() {
        NotificationCenter.default.post(
            name: .subscriptionStatusChanged,
            object: subscriptionStatus
        )
    }
    
    // MARK: - Helpers
    
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw SubscriptionError.verificationFailed
        case .verified(let safe):
            return safe
        }
    }
}

extension Notification.Name {
    static let subscriptionStatusChanged = Notification.Name("SubscriptionStatusChanged")
}
```

**Step 4: Build to verify**

Run: `Cmd+B` in Xcode
Expected: Build succeeds

**Step 5: Commit**

```bash
git add -A
git commit -m "feat: add SubscriptionManager with StoreKit 2 integration"
```

---

### Task 3.2: Create PaywallView

**Files:**
- Create: `BringABrainLanguage/Features/Paywall/PaywallView.swift`
- Create: `BringABrainLanguage/Features/Paywall/PremiumGate.swift`

**Step 1: Create PaywallView.swift**

```swift
import SwiftUI
import StoreKit

struct PaywallView: View {
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    @Environment(\.dismiss) private var dismiss
    
    let onContinueFree: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            // Hero
            VStack(spacing: 12) {
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 60))
                    .foregroundStyle(.purple.gradient)
                    .symbolEffect(.breathe)
                
                Text("Unlock Your Full Potential")
                    .font(.title.bold())
                
                Text("Get unlimited scenarios, cloud sync, and online multiplayer")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 40)
            
            Spacer()
            
            // Features
            FeatureListView()
            
            Spacer()
            
            // Products
            if subscriptionManager.isLoading {
                ProgressView()
            } else {
                VStack(spacing: 12) {
                    ForEach(subscriptionManager.availableProducts, id: \.id) { product in
                        ProductButton(product: product) {
                            await purchase(product)
                        }
                    }
                }
            }
            
            // Skip button
            Button("Continue with Free Version") {
                onContinueFree()
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .padding(.top, 8)
            
            // Restore
            Button("Restore Purchases") {
                Task { await subscriptionManager.restorePurchases() }
            }
            .font(.caption)
            .foregroundStyle(.secondary)
            
            // Legal
            LegalLinksView()
                .padding(.bottom)
        }
        .padding(.horizontal, 24)
    }
    
    private func purchase(_ product: Product) async {
        do {
            let success = try await subscriptionManager.purchase(product)
            if success {
                dismiss()
            }
        } catch {
            print("Purchase failed: \(error)")
        }
    }
}

// MARK: - Supporting Views

struct FeatureListView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            FeatureRow(icon: "theatermasks.fill", text: "20+ immersive scenarios")
            FeatureRow(icon: "globe", text: "Online multiplayer worldwide")
            FeatureRow(icon: "icloud.fill", text: "Sync progress across devices")
            FeatureRow(icon: "chart.line.uptrend.xyaxis", text: "Advanced vocabulary analytics")
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

struct FeatureRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.purple)
                .frame(width: 32)
            
            Text(text)
                .font(.subheadline)
        }
    }
}

struct ProductButton: View {
    let product: Product
    let onPurchase: () async -> Void
    
    @State private var isPurchasing = false
    
    var body: some View {
        Button {
            isPurchasing = true
            Task {
                await onPurchase()
                isPurchasing = false
            }
        } label: {
            HStack {
                VStack(alignment: .leading) {
                    Text(product.displayName)
                        .font(.headline)
                    Text(product.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                if isPurchasing {
                    ProgressView()
                } else {
                    Text(product.displayPrice)
                        .font(.headline)
                }
            }
            .padding()
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
        .disabled(isPurchasing)
    }
}

struct LegalLinksView: View {
    var body: some View {
        HStack(spacing: 16) {
            Link("Privacy Policy", destination: URL(string: "https://bablabs.com/privacy")!)
            Text("•")
            Link("Terms of Use", destination: URL(string: "https://bablabs.com/terms")!)
        }
        .font(.caption2)
        .foregroundStyle(.secondary)
    }
}
```

**Step 2: Create PremiumGate.swift**

```swift
import SwiftUI

struct PremiumGate<Content: View>: View {
    @ObservedObject private var subscriptionManager = SubscriptionManager.shared
    
    let content: () -> Content
    
    @State private var showPaywall = false
    
    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }
    
    var body: some View {
        Group {
            if subscriptionManager.subscriptionStatus == .subscribed {
                content()
            } else {
                content()
                    .overlay {
                        ZStack {
                            Color.black.opacity(0.4)
                            
                            VStack(spacing: 8) {
                                Image(systemName: "lock.fill")
                                    .font(.title)
                                Text("Premium")
                                    .font(.caption.bold())
                            }
                            .foregroundStyle(.white)
                        }
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .onTapGesture { showPaywall = true }
            }
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView { showPaywall = false }
        }
    }
}
```

**Step 3: Build to verify**

Run: `Cmd+B` in Xcode
Expected: Build succeeds

**Step 4: Commit**

```bash
git add -A
git commit -m "feat: add PaywallView and PremiumGate components"
```

---

## Phase 4: Lobby & Session (Tasks 4.1 - 4.5)

> Continue with similar detailed task structure for:
> - Task 4.1: ScenarioCard and ScenarioGrid
> - Task 4.2: DialogLibraryView
> - Task 4.3: ConnectionSheet (Host/Join)
> - Task 4.4: Complete LobbyView
> - Task 4.5: TheaterView with DialogBubbles

---

## Phase 5: Vocabulary (Tasks 5.1 - 5.3)

> Continue with similar detailed task structure for:
> - Task 5.1: VocabularyDashboard
> - Task 5.2: FlashcardReviewView with SRS
> - Task 5.3: WordDetailView

---

## Phase 6: Settings (Tasks 6.1 - 6.4)

> Continue with similar detailed task structure for:
> - Task 6.1: SettingsView main screen
> - Task 6.2: LanguageSettingsView
> - Task 6.3: LearningPreferencesView
> - Task 6.4: SocialLinksView and AboutView

---

## Phase 7: Premium Animations (Tasks 7.1 - 7.3)

> Continue with similar detailed task structure for:
> - Task 7.1: Zoom Transitions (Lobby → Theater)
> - Task 7.2: KeyframeAnimator for DialogBubbles
> - Task 7.3: SF Symbols effects throughout app

---

## Phase 8: iOS 26 Foundation Models (Tasks 8.1 - 8.2)

> Continue with similar detailed task structure for:
> - Task 8.1: IOSLLMBridge with @Generable
> - Task 8.2: Memory pressure handling

---

## Verification Checklist

Before marking the project complete, verify:

- [ ] App builds without warnings
- [ ] Onboarding flow completes and saves profile
- [ ] Paywall displays (mocked products OK)
- [ ] Lobby shows scenarios and stats
- [ ] Solo game launches and shows dialog
- [ ] Vocabulary review works with SRS
- [ ] Settings persist changes
- [ ] Zoom transitions work between Lobby and Theater
- [ ] SF Symbol animations active
- [ ] No memory leaks in Instruments
- [ ] Accessibility: VoiceOver labels present
- [ ] iPad layout adapts correctly

---

*Plan Version: 1.0 - February 2026*
