import Testing
import SwiftUI
@testable import BringABrainLanguage

struct LobbyComponentsTests {

    @Test func statPillInitialization() {
        let pill = StatPill(icon: "flame.fill", value: "5", color: .orange)
        
        #expect(pill.icon == "flame.fill")
        #expect(pill.value == "5")
        #expect(pill.color == .orange)
    }

    @Test func scenarioCardInitialization() {
        let displayData = ScenarioDisplayData(
            id: "1",
            name: "Coffee Shop",
            description: "Order a coffee",
            difficulty: "A1",
            isPremium: true,
            imageName: "cup.and.saucer"
        )
        
        let namespace = Namespace().wrappedValue
        let card = ScenarioCard(scenario: displayData, namespace: namespace)
        
        #expect(card.scenario.name == "Coffee Shop")
        #expect(card.scenario.isPremium == true)
    }
}
