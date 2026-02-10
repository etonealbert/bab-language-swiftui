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
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
            
            VocabularyDashboard()
                .tabItem {
                    Label("Vocabulary", systemImage: "book.fill")
                }
            
            ChatHistoryView()
                .tabItem {
                    Label("History", systemImage: "clock.arrow.circlepath")
                }
            
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
        }
    }
}
