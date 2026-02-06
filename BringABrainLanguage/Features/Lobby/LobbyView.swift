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
