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
            let schema = Schema(BabLanguageSchemaV1.models)
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
        
        let swiftDataUserProfileRepo = SwiftDataUserProfileRepository(modelContainer: container)
        let swiftDataRepo = SwiftDataUserProfileRepository(modelContainer: modelContainer)
                
        // 3. Initialize SDK with the Bridge
        // This uses the new constructor you added in v1.0.7
        let sdk = BrainSDK(userProfileRepository: swiftDataRepo)
        
        // 4. Initialize the UI Observer
        self._sdkObserver = StateObject(wrappedValue: SDKObserver(sdk: sdk))
        
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(sdkObserver)
        }
        .modelContainer(modelContainer)
    }
}
