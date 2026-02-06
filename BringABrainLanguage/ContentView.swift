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
