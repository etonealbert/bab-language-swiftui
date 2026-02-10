import SwiftUI
import SwiftData
import BabLanguageSDK

@main
struct BringABrainLanguageApp: App {
    
    let modelContainer: ModelContainer
    @StateObject private var sdkObserver: SDKObserver
    
    init() {
        let fileManager = FileManager.default
        if let appSupportURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
            if !fileManager.fileExists(atPath: appSupportURL.path) {
                try? fileManager.createDirectory(at: appSupportURL, withIntermediateDirectories: true)
            }
        }
        
        let container: ModelContainer
        do {
            let schema = Schema(BabLanguageSchemaV2.models)
            let modelConfiguration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false
            )
            container = try ModelContainer(
                for: schema,
                migrationPlan: BabLanguageMigrationPlan.self,
                configurations: [modelConfiguration]
            )
        } catch {
            fatalError("Could not initialize ModelContainer: \(error)")
        }
        self.modelContainer = container
        
        let swiftDataRepo = SwiftDataUserProfileRepository(modelContainer: container)
        let sdk = BrainSDK(userProfileRepository: swiftDataRepo)
        
        self._sdkObserver = StateObject(
            wrappedValue: SDKObserver(sdk: sdk, modelContext: container.mainContext)
        )
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(sdkObserver)
        }
        .modelContainer(modelContainer)
    }
}
