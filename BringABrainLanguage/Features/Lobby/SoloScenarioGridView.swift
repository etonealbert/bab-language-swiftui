import SwiftUI

struct SoloScenarioGridView: View {
    @EnvironmentObject var observer: SDKObserver
    var namespace: Namespace.ID
    
    var body: some View {
        ScenarioGrid(namespace: namespace)
            .navigationTitle("Solo Scenarios")
    }
}
