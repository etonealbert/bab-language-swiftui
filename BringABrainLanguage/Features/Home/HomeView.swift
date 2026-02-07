import SwiftUI

enum PlayMode: String, Identifiable {
    case solo
    case host
    case join
    
    var id: String { rawValue }
}

struct HomeView: View {
    @EnvironmentObject var observer: SDKObserver
    @State private var selectedMode: PlayMode?
    @Namespace private var namespace
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    ModeCard(
                        icon: "theatermasks.fill",
                        title: "Solo Mode",
                        subtitle: "Practice on your own",
                        description: "AI plays all other roles"
                    ) {
                        selectedMode = .solo
                    }
                    
                    ModeCard(
                        icon: "antenna.radiowaves.left.and.right",
                        title: "Host Party",
                        subtitle: "Start a local game",
                        description: "Friends join via Bluetooth"
                    ) {
                        selectedMode = .host
                    }
                    
                    ModeCard(
                        icon: "magnifyingglass",
                        title: "Join Party",
                        subtitle: "Scan for nearby hosts",
                        description: "Connect and play together"
                    ) {
                        selectedMode = .join
                    }
                }
                .padding()
            }
            .navigationTitle("Choose Your Mode")
            .navigationDestination(item: $selectedMode) { mode in
                destinationView(for: mode)
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
