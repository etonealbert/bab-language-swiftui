import SwiftUI

struct JoinScanView: View {
    @StateObject private var bleJoinManager = BLEJoinManager()
    @EnvironmentObject var observer: SDKObserver
    
    var body: some View {
        VStack(spacing: 0) {
            if bleJoinManager.isConnected {
                guestLobbyView
            } else if bleJoinManager.isScanning {
                scanningView
            } else {
                idleView
            }
        }
        .navigationTitle(bleJoinManager.isConnected ? "Guest Lobby" : "Join Party")
        .navigationBarTitleDisplayMode(.large)
        .onDisappear {
            if bleJoinManager.isScanning {
                bleJoinManager.stopScanning()
            }
        }
    }
    
    // MARK: - Idle State
    
    private var idleView: some View {
        VStack(spacing: 28) {
            Spacer()
            
            Image(systemName: "antenna.radiowaves.left.and.right")
                .font(.system(size: 64, weight: .light))
                .foregroundStyle(
                    .linearGradient(
                        colors: [.cyan, .blue],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .symbolEffect(.pulse, options: .repeating)
            
            VStack(spacing: 8) {
                Text("Find a Game")
                    .font(.title2.bold())
                Text("Scan for nearby hosts broadcasting via Bluetooth")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Button {
                bleJoinManager.startScanning()
            } label: {
                HStack {
                    Image(systemName: "magnifyingglass")
                    Text("Start Scanning")
                        .fontWeight(.semibold)
                }
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    .linearGradient(
                        colors: [.cyan, .blue],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .padding(.horizontal)
            
            Spacer()
        }
        .padding()
    }
    
    // MARK: - Scanning State (Radar Animation)
    
    private var scanningView: some View {
        VStack(spacing: 24) {
            // Radar animation
            RadarPulseView(baseColor: .cyan)
                .padding(.top, 20)
            
            Text("Scanning for hosts…")
                .font(.headline)
                .foregroundStyle(.secondary)
            
            // Discovered hosts list
            if !bleJoinManager.discoveredHosts.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Nearby Hosts")
                        .font(.subheadline.bold())
                        .padding(.horizontal)
                    
                    ForEach(bleJoinManager.discoveredHosts, id: \.identifier) { host in
                        hostRow(host)
                    }
                }
                .padding(.top, 4)
            }
            
            Spacer()
            
            Button {
                bleJoinManager.stopScanning()
            } label: {
                Text("Stop Scanning")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(.ultraThinMaterial)
                    .clipShape(Capsule())
            }
            .padding(.bottom)
        }
        .padding()
    }
    
    @ViewBuilder
    private func hostRow(_ host: CBPeripheral) -> some View {
        Button {
            bleJoinManager.connect(to: host)
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(
                            .linearGradient(
                                colors: [.cyan, .blue],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 42, height: 42)
                    
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(.white)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(host.name ?? "Unknown Host")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.primary)
                    
                    Text("Tap to connect")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right.circle.fill")
                    .font(.title3)
                    .foregroundStyle(.blue.opacity(0.6))
            }
            .padding(14)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
        .padding(.horizontal)
    }
    
    // MARK: - Guest Lobby (Post-Connection)
    
    private var guestLobbyView: some View {
        ScrollView {
            VStack(spacing: 28) {
                // Connected badge
                VStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 52))
                        .foregroundStyle(.green)
                        .symbolEffect(.bounce, value: bleJoinManager.isConnected)
                    
                    Text("Connected!")
                        .font(.title2.bold())
                }
                .padding(.top, 8)
                
                // Host's selected scenario (read-only)
                lobbyInfoSection
                
                // Waiting indicator
                waitingSection
            }
            .padding()
        }
    }
    
    private var lobbyInfoSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Scenario
            VStack(alignment: .leading, spacing: 8) {
                Label("Scenario", systemImage: "theatermasks.fill")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
                
                if let lobbyState = observer.sessionState?.lobbyState,
                   !lobbyState.selectedScenarioId.isEmpty {
                    Text(lobbyState.selectedScenarioId.replacingOccurrences(of: "-", with: " ").capitalized)
                        .font(.title3.bold())
                } else {
                    HStack(spacing: 8) {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Waiting for host to select…")
                            .font(.subheadline)
                            .foregroundStyle(.tertiary)
                    }
                }
            }
            
            Divider()
            
            // Difficulty
            VStack(alignment: .leading, spacing: 8) {
                Label("Difficulty", systemImage: "speedometer")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
                
                if let lobbyState = observer.sessionState?.lobbyState,
                   !lobbyState.difficultyLevel.isEmpty {
                    Text(lobbyState.difficultyLevel.capitalized)
                        .font(.headline)
                } else {
                    Text("—")
                        .font(.headline)
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(.quaternary, lineWidth: 1)
        )
    }
    
    private var waitingSection: some View {
        VStack(spacing: 14) {
            Image(systemName: "hourglass")
                .font(.system(size: 28))
                .foregroundStyle(.blue)
                .symbolEffect(.breathe)
            
            Text("Waiting for host to start the game…")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// CoreBluetooth import needed for CBPeripheral type in hostRow
import CoreBluetooth
