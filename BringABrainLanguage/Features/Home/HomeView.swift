import SwiftUI

enum PlayMode: String, Hashable, Codable {
    case solo
    case host
    case join
}

struct HomeView: View {
    @EnvironmentObject var observer: SDKObserver
    @State private var navigationPath = NavigationPath()
    @Namespace private var namespace
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            ScrollView {
                VStack(spacing: 20) {
                    ModeCard(
                        icon: "theatermasks.fill",
                        title: "Solo Mode",
                        subtitle: "Practice on your own",
                        description: "AI plays all other roles"
                    ) {
                        navigationPath.append(PlayMode.solo)
                    }
                    
                    ModeCard(
                        icon: "antenna.radiowaves.left.and.right",
                        title: "Host Party",
                        subtitle: "Start a local game",
                        description: "Friends join via Bluetooth"
                    ) {
                        navigationPath.append(PlayMode.host)
                    }
                    
                    ModeCard(
                        icon: "magnifyingglass",
                        title: "Join Party",
                        subtitle: "Scan for nearby hosts",
                        description: "Connect and play together"
                    ) {
                        navigationPath.append(PlayMode.join)
                    }
                }
                .padding()
            }
            .navigationTitle("Choose Your Mode")
            .navigationDestination(for: PlayMode.self) { mode in
                destinationView(for: mode)
            }
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
    
    @ViewBuilder
    private func destinationView(for mode: PlayMode) -> some View {
        switch mode {
        case .solo:
            SoloScenarioGridView(namespace: namespace)
        case .host:
            HostLobbyView()
        case .join:
            JoinScanView()
        }
    }
}
