import SwiftUI
import BabLanguageSDK

struct OnboardingCoordinator: View {
    @EnvironmentObject var observer: SDKObserver
    @State private var currentStep: OnboardingStep = .welcome
    
    @State private var displayName: String = ""
    @State private var nativeLanguage: String = "en"
    @State private var targetLanguage: String = "es"
    @State private var proficiencyLevel: String = "A1"
    @State private var selectedInterests: Set<String> = []
    @State private var dailyGoalMinutes: Int = 15
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ProgressView(value: currentStep.progress)
                    .tint(.purple)
                    .padding(.horizontal)
                
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
            .navigationTitle(currentStep.title)
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
            let now = Int64(Date().timeIntervalSince1970 * 1000)
            
            let profile = BabLanguageSDK.UserProfile(
                id: UUID().uuidString,
                displayName: displayName,
                nativeLanguage: nativeLanguage,
                targetLanguages: [],
                currentTargetLanguage: targetLanguage,
                interests: [],
                learningGoals: [],
                dailyGoalMinutes: Int32(dailyGoalMinutes),
                voiceSpeed: .normal,
                showTranslations: .onTap,
                onboardingCompleted: true,
                createdAt: now,
                lastActiveAt: now
            )
            
            await observer.completeOnboarding(profile: profile)
        }
    }
}

struct WelcomeStepView: View {
    let onContinue: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: "brain.head.profile")
                .font(.system(size: 80))
                .foregroundStyle(.purple.gradient)
                .symbolEffect(.breathe)
            
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
            .tint(.purple)
            
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
                .autocorrectionDisabled()
            
            Spacer()
            
            Button("Continue") {
                onContinue()
            }
            .buttonStyle(.borderedProminent)
            .disabled(displayName.isEmpty)
            .tint(.purple)
        }
        .padding()
    }
}

struct LanguageStepView: View {
    @Binding var nativeLanguage: String
    @Binding var targetLanguage: String
    @Binding var proficiencyLevel: String
    let onContinue: () -> Void
    
    let languages = [
        "en": "English",
        "es": "Spanish",
        "fr": "French",
        "de": "German",
        "it": "Italian",
        "ja": "Japanese",
        "ko": "Korean",
        "zh": "Chinese"
    ]
    
    let levels = ["A1", "A2", "B1", "B2", "C1", "C2"]
    
    var body: some View {
        VStack(spacing: 24) {
            Text("Set up your languages")
                .font(.title2.bold())
            
            Form {
                Section("I speak") {
                    Picker("Native Language", selection: $nativeLanguage) {
                        ForEach(languages.keys.sorted(), id: \.self) { key in
                            Text(languages[key] ?? key).tag(key)
                        }
                    }
                }
                
                Section("I want to learn") {
                    Picker("Target Language", selection: $targetLanguage) {
                        ForEach(languages.keys.sorted(), id: \.self) { key in
                            Text(languages[key] ?? key).tag(key)
                        }
                    }
                    
                    Picker("Current Level", selection: $proficiencyLevel) {
                        ForEach(levels, id: \.self) { level in
                            Text(level).tag(level)
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            
            Spacer()
            
            Button("Continue") {
                onContinue()
            }
            .buttonStyle(.borderedProminent)
            .tint(.purple)
        }
        .padding()
    }
}

struct InterestsStepView: View {
    @Binding var selectedInterests: Set<String>
    @Binding var dailyGoalMinutes: Int
    let onContinue: () -> Void
    
    let allInterests = ["Travel", "Business", "Food", "Culture", "Tech", "Art", "Music", "Movies"]
    
    var body: some View {
        VStack(spacing: 24) {
            Text("What interests you?")
                .font(.title2.bold())
            
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 12) {
                    ForEach(allInterests, id: \.self) { interest in
                        InterestChip(
                            title: interest,
                            isSelected: selectedInterests.contains(interest)
                        ) {
                            if selectedInterests.contains(interest) {
                                selectedInterests.remove(interest)
                            } else {
                                selectedInterests.insert(interest)
                            }
                        }
                    }
                }
                .padding()
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Daily Goal: \(dailyGoalMinutes) min")
                    .font(.headline)
                Slider(value: Binding(
                    get: { Double(dailyGoalMinutes) },
                    set: { dailyGoalMinutes = Int($0) }
                ), in: 5...60, step: 5)
                .tint(.purple)
            }
            .padding(.horizontal)
            
            Spacer()
            
            Button("Continue") {
                onContinue()
            }
            .buttonStyle(.borderedProminent)
            .tint(.purple)
        }
        .padding()
    }
}

struct InterestChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.purple : Color.gray.opacity(0.2))
                .foregroundColor(isSelected ? .white : .primary)
                .clipShape(Capsule())
        }
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
                .symbolEffect(.bounce)
            
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
            .tint(.purple)
            
            Spacer().frame(height: 40)
        }
        .padding()
    }
}

