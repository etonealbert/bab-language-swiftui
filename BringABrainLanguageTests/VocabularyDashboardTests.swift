import XCTest
import SwiftUI
import SwiftData
@testable import BringABrainLanguage

@MainActor
final class VocabularyDashboardTests: XCTestCase {
    func testVocabularyDashboard_Initialization() throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: SDVocabularyEntry.self, configurations: config)
        
        let view = VocabularyDashboard()
            .modelContainer(container)
            
        XCTAssertNotNil(view)
    }
}
