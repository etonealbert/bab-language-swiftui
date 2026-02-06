import SwiftUI
import BabLanguageSDK

struct SettingsView: View {
    @EnvironmentObject var observer: SDKObserver
    
    // Local state for notifications (since they might not be in UserProfile or need local handling)
    @AppStorage("dailyReminderEnabled") private var dailyReminderEnabled = false
    @AppStorage("reminderTime") private var reminderTime = Date() // Store as time interval or date
    
    var body: some View {
        NavigationStack {
            Form {
                if let profile = observer.userProfile {
                    profileSection(profile)
                    languagesSection(profile)
                    learningSection(profile)
                } else {
                    Section {
                        Text("Loading profile...")
                    }
                }
                
                notificationsSection
                shareSection
                aboutSection
            }
            .navigationTitle("Settings")
        }
    }
    
    // MARK: - Sections
    
    private func profileSection(_ profile: UserProfile) -> some View {
        Section("Profile") {
            NavigationLink(destination: ProfileEditView()) {
                SettingsRow(
                    icon: "person.fill",
                    title: profile.displayName,
                    value: "Edit",
                    color: .blue
                )
            }
            
            SettingsRow(
                icon: "face.smiling.fill",
                title: "Avatar",
                value: "Coming Soon",
                color: .purple
            )
        }
    }
    
    private func languagesSection(_ profile: UserProfile) -> some View {
        Section("Languages") {
            SettingsRow(
                icon: "bubble.left.and.bubble.right.fill",
                title: "Native Language",
                value: profile.nativeLanguage.uppercased(),
                color: .green
            )
            
            NavigationLink(destination: LanguageSettingsView()) {
                SettingsRow(
                    icon: "globe",
                    title: "Target Languages",
                    value: profile.currentTargetLanguage.uppercased(),
                    color: .cyan
                )
            }
        }
    }
    
    private func learningSection(_ profile: UserProfile) -> some View {
        Section("Learning Preferences") {
            // TODO: Re-enable when SDK profile update is fixed
            /*
            Picker(selection: Binding(
                get: { profile.dailyGoalMinutes },
                set: { newValue in updateProfile { $0.dailyGoalMinutes = newValue } }
            )) {
                Text("5 min").tag(5)
                Text("10 min").tag(10)
                Text("15 min").tag(15)
                Text("30 min").tag(30)
            } label: {
                SettingsRow(icon: "target", title: "Daily Goal", color: .orange)
            }
            */
            Text("Learning Preferences (Coming Soon)")
        }
    }
    
    private var notificationsSection: some View {
        Section("Notifications") {
            Toggle(isOn: $dailyReminderEnabled) {
                SettingsRow(icon: "bell.fill", title: "Daily Reminder", color: .red)
            }
            
            if dailyReminderEnabled {
                DatePicker(selection: $reminderTime, displayedComponents: .hourAndMinute) {
                    SettingsRow(icon: "clock.fill", title: "Time", color: .gray)
                }
            }
        }
    }
    
    private var shareSection: some View {
        Section("Share & Connect") {
            Button {
                UIPasteboard.general.string = "https://bringabrain.com/join"
            } label: {
                SettingsRow(icon: "link", title: "Copy Referral Link", color: .blue)
            }
            
            Link(destination: URL(string: "https://instagram.com")!) {
                SettingsRow(icon: "camera.fill", title: "Instagram", color: .purple)
            }
            
            Link(destination: URL(string: "https://tiktok.com")!) {
                SettingsRow(icon: "music.note", title: "TikTok", color: .black)
            }
            
            Link(destination: URL(string: "https://discord.com")!) {
                SettingsRow(icon: "bubble.left.fill", title: "Discord", color: .indigo)
            }
        }
    }
    
    private var aboutSection: some View {
        Section("About") {
            HStack {
                SettingsRow(icon: "info.circle.fill", title: "Version", color: .gray)
                Spacer()
                Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0")
                    .foregroundColor(.secondary)
            }
            
            Button {
                
            } label: {
                SettingsRow(icon: "star.fill", title: "Rate on App Store", color: .yellow)
            }
            
            Link(destination: URL(string: "https://bringabrain.com/privacy")!) {
                SettingsRow(icon: "hand.raised.fill", title: "Privacy Policy", color: .gray)
            }
            
            Link(destination: URL(string: "https://bringabrain.com/terms")!) {
                SettingsRow(icon: "doc.text.fill", title: "Terms of Service", color: .gray)
            }
            
            Link(destination: URL(string: "mailto:support@bringabrain.com")!) {
                SettingsRow(icon: "envelope.fill", title: "Contact Support", color: .blue)
            }
        }
    }
    
    private func updateProfile(_ action: @escaping (inout UserProfile) -> Void) {
        Task {
            /*
            try? await observer.sdk.updateProfile { profile in
                var newProfile = profile
                action(&newProfile)
                return newProfile
            }
            */
        }
    }
}
