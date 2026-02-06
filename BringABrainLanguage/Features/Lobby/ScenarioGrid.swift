import SwiftUI

struct ScenarioGrid: View {
    @EnvironmentObject var observer: SDKObserver
    let namespace: Namespace.ID
    
    let columns = [
        GridItem(.adaptive(minimum: 160), spacing: 16)
    ]
    
    @State private var scenarios: [ScenarioDisplayData] = []
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 16) {
                scenarioCards
            }
            .padding()
        }
        .task {
            await loadScenarios()
        }
    }
    
    @ViewBuilder
    private var scenarioCards: some View {
        ForEach(scenarios, id: \.id) { (scenario: ScenarioDisplayData) in
            NavigationLink(value: scenario) {
                if scenario.isPremium {
                    PremiumGate {
                        ScenarioCard(scenario: scenario, namespace: namespace)
                    }
                } else {
                    ScenarioCard(scenario: scenario, namespace: namespace)
                }
            }
            .buttonStyle(.plain)
        }
    }
    
    private func loadScenarios() async {
        try? await Task.sleep(for: .seconds(0.5))
        
        self.scenarios = [
            ScenarioDisplayData(id: "1", name: "Coffee Shop", description: "Order a latte like a local", difficulty: "A1", isPremium: false, imageName: "cup.and.saucer.fill"),
            ScenarioDisplayData(id: "2", name: "Job Interview", description: "Answer common questions", difficulty: "B2", isPremium: true, imageName: "briefcase.fill"),
            ScenarioDisplayData(id: "3", name: "Train Station", description: "Buy a ticket to Paris", difficulty: "A2", isPremium: false, imageName: "tram.fill"),
            ScenarioDisplayData(id: "4", name: "Grocery Store", description: "Find ingredients for dinner", difficulty: "A1", isPremium: false, imageName: "basket.fill"),
            ScenarioDisplayData(id: "5", name: "Emergency", description: "Call for help", difficulty: "C1", isPremium: true, imageName: "cross.case.fill")
        ]
    }
}
