import SwiftUI

struct JoinScanView: View {
    @StateObject private var bleJoinManager = BLEJoinManager()
    @EnvironmentObject var observer: SDKObserver
    
    var body: some View {
        VStack(spacing: 24) {
            if bleJoinManager.isScanning {
                scanningView
            } else if bleJoinManager.isConnected {
                connectedView
            } else {
                idleView
            }
        }
        .padding()
        .navigationTitle("Join Party")
    }
    
    private var idleView: some View {
        VStack(spacing: 20) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 60))
                .foregroundStyle(.tint)
            
            Button {
                bleJoinManager.startScanning()
            } label: {
                Label("Scan for Hosts", systemImage: "antenna.radiowaves.left.and.right")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.tint)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }
    
    private var scanningView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
            
            Text("Scanning for nearby hosts...")
                .font(.title3)
            
            if !bleJoinManager.discoveredHosts.isEmpty {
                List(bleJoinManager.discoveredHosts, id: \.identifier) { host in
                    Button {
                        bleJoinManager.connect(to: host)
                    } label: {
                        HStack {
                            Image(systemName: "person.circle.fill")
                            Text(host.name ?? "Unknown Host")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .listStyle(.plain)
            }
            
            Button("Stop Scanning") {
                bleJoinManager.stopScanning()
            }
            .buttonStyle(.bordered)
        }
    }
    
    private var connectedView: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundStyle(.green)
            
            Text("Connected!")
                .font(.title2)
            
            Text("Waiting for host to start...")
                .foregroundStyle(.secondary)
        }
    }
}
