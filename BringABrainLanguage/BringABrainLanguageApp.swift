import SwiftUI
import SwiftData
import BabLanguageSDK

@main
struct BringABrainLanguageApp: App {
    
    let modelContainer: ModelContainer
    @StateObject private var sdkObserver: SDKObserver
    
    init() {
        do {
            let schema = Schema(BabLanguageSchemaV1.models)
            let modelConfiguration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false
            )
            let container = try ModelContainer(
                for: schema,
                migrationPlan: BabLanguageMigrationPlan.self,
                configurations: [modelConfiguration]
            )
            self.modelContainer = container
            
            let sdk = SDKFactory.createSDK(modelContext: container.mainContext)
            _sdkObserver = StateObject(wrappedValue: SDKObserver(sdk: sdk))
        } catch {
            fatalError("Could not initialize ModelContainer: \(error)")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(sdkObserver)
        }
        .modelContainer(modelContainer)
    }
}
