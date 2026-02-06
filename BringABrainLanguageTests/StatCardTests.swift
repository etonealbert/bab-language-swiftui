import XCTest
import SwiftUI
@testable import BringABrainLanguage

final class StatCardTests: XCTestCase {
    func testStatCard_Initialization() {
        let title = "Test Title"
        let value = "123"
        let card = StatCard(title: title, value: value)
        
        XCTAssertNotNil(card)
    }
}
