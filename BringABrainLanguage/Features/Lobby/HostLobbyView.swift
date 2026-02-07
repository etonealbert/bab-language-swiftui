import SwiftUI

struct HostLobbyView: View {
    @StateObject private var bleHostManager = BLEHostManager()
    @EnvironmentObject var observer: SDKObserver
    @State private var hostName = ""
    
    var body: some View {
        VStack(spacing: 24) {
            if bleHostManager.isAdvertising {
                advertisingView
            } else {
                setupView
            }
        }
        .padding()
        .navigationTitle("Host Party")
    }
    
    private var setupView: some View {
        VStack(spacing: 20) {
            TextField("Your Name", text: $hostName)
                .textFieldStyle(.roundedBorder)
                .font(.title3)
            
            Button {
                bleHostManager.startAdvertising(hostName: hostName.isEmpty ? "Host" : hostName)
            } label: {
                Label("Start Hosting", systemImage: "antenna.radiowaves.left.and.right")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.tint)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }
    
    private var advertisingView: some View {
        VStack(spacing: 20) {
            Image(systemName: "antenna.radiowaves.left.and.right")
                .font(.system(size: 60))
                .symbolEffect(.variableColor.iterative)
                .foregroundStyle(.tint)
            
            Text("Waiting for players...")
                .font(.title2)
            
            Text("\(bleHostManager.connectedPeers.count) connected")
                .foregroundStyle(.secondary)
            
            Button("Stop Hosting") {
                bleHostManager.stopAdvertising()
            }
            .buttonStyle(.bordered)
        }
    }
}
