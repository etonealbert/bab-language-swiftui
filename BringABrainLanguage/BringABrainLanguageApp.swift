//
//  BringABrainLanguageApp.swift
//  BringABrainLanguage
//
//  Created by Whatsername on 06/02/2026.
//

import SwiftUI
import SwiftData

@main
struct BringABrainLanguageApp: App {
    
    let modelContainer: ModelContainer
    
    init() {
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
        }
        .modelContainer(modelContainer)
    }
}
