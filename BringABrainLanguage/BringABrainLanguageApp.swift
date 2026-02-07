import SwiftUI
import SwiftData
import BabLanguageSDK

@main
struct BringABrainLanguageApp: App {
    
    let modelContainer: ModelContainer
    @StateObject private var sdkObserver = SDKObserver(sdk: BrainSDK())
    
    init() {
        let fileManager = FileManager.default
        if let appSupportURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
            if !fileManager.fileExists(atPath: appSupportURL.path) {
                try? fileManager.createDirectory(at: appSupportURL, withIntermediateDirectories: true)
            }
        }
        
        do {
            let schema = Schema(BabLanguageSchemaV1.models)
            let modelConfiguration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false
            )
            modelContainer = try ModelContainer(
                for: schema,
                migrationPlan: BabLanguageMigrationPlan.self,
                configurations: [modelConfiguration]
            )
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
