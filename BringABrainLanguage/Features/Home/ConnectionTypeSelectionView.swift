import SwiftUI

enum ConnectionType: String, CaseIterable {
    case bluetooth = "Bluetooth"
    case online = "Online"
}

struct ConnectionTypeSelectionView: View {
    let mode: PlayMode
    let onSelect: (ConnectionType) -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 28) {
                // Header
                VStack(spacing: 12) {
                    Image(systemName: mode == .host
                          ? "antenna.radiowaves.left.and.right"
                          : "magnifyingglass")
                        .font(.system(size: 48, weight: .light))
                        .foregroundStyle(
                            .linearGradient(
                                colors: [.purple, .blue],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .symbolEffect(.pulse, options: .repeating)
                    
                    Text("Select Connection")
                        .font(.title2.bold())
                    
                    Text(mode == .host
                         ? "How would you like to host?"
                         : "How would you like to join?")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 8)
                
                // Options
                VStack(spacing: 16) {
                    // Bluetooth (Local) — always available
                    connectionOptionCard(
                        icon: "antenna.radiowaves.left.and.right",
                        title: "Bluetooth",
                        subtitle: "Connect with nearby players",
                        gradient: [Color.blue, Color.cyan]
                    ) {
                        dismiss()
                        onSelect(.bluetooth)
                    }
                    
                    // Online (Cloud) — premium gated
                    PremiumGate {
                        connectionOptionCard(
                            icon: "globe",
                            title: "Online",
                            subtitle: "Play with anyone worldwide",
                            gradient: [Color.purple, Color.pink]
                        ) {
                            dismiss()
                            onSelect(.online)
                        }
                    }
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .padding()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundStyle(.secondary)
                }
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(28)
    }
    
    @ViewBuilder
    private func connectionOptionCard(
        icon: String,
        title: String,
        subtitle: String,
        gradient: [Color],
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(
                            .linearGradient(
                                colors: gradient,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 52, height: 52)
                    
                    Image(systemName: icon)
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(.white)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding()
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(.quaternary, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}
