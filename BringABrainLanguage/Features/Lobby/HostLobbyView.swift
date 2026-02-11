import SwiftUI

struct HostLobbyView: View {
    @StateObject private var bleHostManager = BLEHostManager()
    @EnvironmentObject var observer: SDKObserver
    
    @State private var hostName = ""
    @State private var selectedScenarioId = ""
    @State private var selectedDifficulty = "Easy"
    @State private var llmAvailability: LLMAvailability = .unknown
    @State private var isGameStarted = false
    @Namespace private var namespace
    
    private let difficulties = ["Easy", "Hard"]
    
    private let scenarios: [ScenarioDisplayData] = [
        ScenarioDisplayData(
            id: "coffee-shop",
            name: "Coffee Shop",
            description: "Order a latte like a local",
            difficulty: "A1",
            isPremium: false,
            imageName: "cup.and.saucer.fill",
            userRole: "Customer",
            aiRole: "Barista"
        ),
        ScenarioDisplayData(
            id: "business-meeting",
            name: "Business Meeting",
            description: "Present your quarterly results",
            difficulty: "B2",
            isPremium: false,
            imageName: "briefcase.fill",
            userRole: "Presenter",
            aiRole: "Manager"
        )
    ]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // — Header / Status Row —
                headerSection
                
                // — Scenario Carousel —
                scenarioSection
                
                // — Difficulty Picker —
                difficultySection
                
                // — Connected Players —
                playersSection
                
                // — Start Button —
                startButton
            }
            .padding()
        }
        .navigationTitle("Host Lobby")
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            llmAvailability = LLMBridge().checkAvailability()
            if !bleHostManager.isAdvertising {
                bleHostManager.startAdvertising(
                    hostName: observer.userProfile?.nativeLanguage ?? "Host"
                )
            }
        }
        .onDisappear {
            if bleHostManager.isAdvertising {
                bleHostManager.stopAdvertising()
            }
        }
    }
    
    // MARK: - Header
    
    private var headerSection: some View {
        HStack(spacing: 12) {
            // AI Ready badge
            HStack(spacing: 6) {
                Image(systemName: llmAvailability == .available
                      ? "checkmark.seal.fill"
                      : "xmark.seal.fill")
                    .foregroundStyle(llmAvailability == .available ? .green : .red)
                    .symbolEffect(.bounce, value: llmAvailability)
                
                Text(llmAvailability == .available ? "AI Ready" : "No AI")
                    .font(.caption.bold())
                    .foregroundStyle(llmAvailability == .available ? .green : .red)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(.ultraThinMaterial)
            .clipShape(Capsule())
            
            Spacer()
            
            // Advertising indicator
            if bleHostManager.isAdvertising {
                HStack(spacing: 6) {
                    Image(systemName: "antenna.radiowaves.left.and.right")
                        .symbolEffect(.variableColor.iterative)
                    Text("Broadcasting")
                        .font(.caption.bold())
                }
                .foregroundStyle(.blue)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(.ultraThinMaterial)
                .clipShape(Capsule())
            }
        }
    }
    
    // MARK: - Scenario Carousel
    
    private var scenarioSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Scenario")
                .font(.headline)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    ForEach(scenarios) { scenario in
                        scenarioCarouselCard(scenario)
                    }
                }
                .padding(.horizontal, 2)
                .padding(.vertical, 4)
            }
        }
    }
    
    @ViewBuilder
    private func scenarioCarouselCard(_ scenario: ScenarioDisplayData) -> some View {
        let isSelected = selectedScenarioId == scenario.id
        
        Button {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                selectedScenarioId = scenario.id
            }
            // Sync with SDK
            observer.sdk.setLobbyScenario(scenarioId: scenario.id)
        } label: {
            VStack(alignment: .leading, spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            isSelected
                            ? AnyShapeStyle(.linearGradient(
                                colors: [.purple, .blue],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                              ))
                            : AnyShapeStyle(Color.purple.opacity(0.1))
                        )
                        .frame(height: 80)
                    
                    Image(systemName: scenario.imageName)
                        .font(.system(size: 32))
                        .foregroundStyle(isSelected ? .white : .purple)
                }
                
                Text(scenario.name)
                    .font(.subheadline.bold())
                    .foregroundStyle(.primary)
                
                Text(scenario.description)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            .frame(width: 150)
            .padding(12)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(
                        isSelected ? Color.purple : Color.clear,
                        lineWidth: 2
                    )
            )
            .shadow(color: isSelected ? .purple.opacity(0.3) : .clear, radius: 8)
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Difficulty
    
    private var difficultySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Difficulty")
                .font(.headline)
            
            Picker("Difficulty", selection: $selectedDifficulty) {
                ForEach(difficulties, id: \.self) { difficulty in
                    Text(difficulty).tag(difficulty)
                }
            }
            .pickerStyle(.segmented)
            .onChange(of: selectedDifficulty) { _, newValue in
                observer.sdk.setLobbyDifficulty(difficultyLevel: newValue.lowercased())
            }
        }
    }
    
    // MARK: - Connected Players
    
    private var playersSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Connected Players")
                    .font(.headline)
                
                Spacer()
                
                Text("\(bleHostManager.connectedPeers.count)/\(BLEConstants.maxPeers)")
                    .font(.subheadline.bold())
                    .foregroundStyle(.secondary)
            }
            
            if bleHostManager.connectedPeers.isEmpty {
                emptyPlayersCard
            } else {
                VStack(spacing: 8) {
                    ForEach(
                        Array(bleHostManager.connectedPeers.enumerated()),
                        id: \.element.identifier
                    ) { index, peer in
                        playerRow(index: index, identifier: peer.identifier.uuidString)
                    }
                }
            }
        }
    }
    
    private var emptyPlayersCard: some View {
        HStack(spacing: 12) {
            Image(systemName: "person.3.fill")
                .font(.title2)
                .foregroundStyle(.tertiary)
                .symbolEffect(.breathe)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Waiting for players…")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text("Others can find you via Bluetooth")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            
            Spacer()
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
    
    private func playerRow(index: Int, identifier: String) -> some View {
        HStack(spacing: 12) {
            Circle()
                .fill(playerColor(for: index))
                .frame(width: 36, height: 36)
                .overlay(
                    Text("\(index + 1)")
                        .font(.caption.bold())
                        .foregroundStyle(.white)
                )
            
            Text("Player \(index + 1)")
                .font(.subheadline.weight(.medium))
            
            Spacer()
            
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private func playerColor(for index: Int) -> Color {
        let colors: [Color] = [.blue, .purple, .orange, .green]
        return colors[index % colors.count]
    }
    
    // MARK: - Start Button
    
    private var startButton: some View {
        Button {
            observer.sdk.startLobbyGame()
        } label: {
            HStack {
                Image(systemName: "play.fill")
                Text("Start Game")
                    .fontWeight(.semibold)
            }
            .font(.headline)
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                bleHostManager.connectedPeers.isEmpty || selectedScenarioId.isEmpty
                ? AnyShapeStyle(.gray.opacity(0.3))
                : AnyShapeStyle(.linearGradient(
                    colors: [.purple, .blue],
                    startPoint: .leading,
                    endPoint: .trailing
                  ))
            )
            .foregroundColor(
                bleHostManager.connectedPeers.isEmpty || selectedScenarioId.isEmpty
                ? .gray
                : .white
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .disabled(bleHostManager.connectedPeers.isEmpty || selectedScenarioId.isEmpty)
        .padding(.top, 8)
    }
}
