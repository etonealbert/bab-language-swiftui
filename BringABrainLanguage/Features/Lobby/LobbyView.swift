import SwiftUI

struct LobbyView: View {
    @EnvironmentObject var observer: SDKObserver
    @Namespace private var namespace
    
    @State private var isSettingsLoading = false
    
    var body: some View {
        TabView {
            Tab("Scenarios", systemImage: "theatermasks.fill") {
                NavigationStack {
                    ScenarioGrid(namespace: namespace)
                        .navigationTitle("Scenarios")
                        .navigationDestination(for: ScenarioDisplayData.self) { scenario in
                            TheaterView(
                                scenarioId: scenario.id,
                                scenarioTitle: scenario.name,
                                namespace: namespace,
                                config: TheaterSessionConfig(
                                    scenarioId: scenario.id,
                                    scenarioTitle: scenario.name,
                                    targetLanguage: observer.userProfile?.currentTargetLanguage ?? "Spanish",
                                    nativeLanguage: observer.userProfile?.nativeLanguage ?? "English",
                                    userRole: scenario.userRole,
                                    aiRole: scenario.aiRole
                                )
                            )
                        }
                }
            }
            
            Tab("Library", systemImage: "books.vertical.fill") {
                DialogLibraryView()
            }
            
            Tab {
                VocabularyDashboard()
            } label: {
                Label("Vocabulary", systemImage: "flame.fill")
                    .symbolEffect(.breathe)
            }
            
            Tab {
                SettingsView()
                    .onAppear {
                        isSettingsLoading = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            isSettingsLoading = false
                        }
                    }
            } label: {
                Label("Settings", systemImage: "gearshape.fill")
                    .symbolEffect(.rotate, isActive: isSettingsLoading)
            }
        }
        .tabViewStyle(.sidebarAdaptable)
    }
}
