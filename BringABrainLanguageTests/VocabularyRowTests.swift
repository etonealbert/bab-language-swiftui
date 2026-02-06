import XCTest
import SwiftUI
@testable import BringABrainLanguage

final class VocabularyRowTests: XCTestCase {
    func testVocabularyRow_Initialization() {
        let entry = SDVocabularyEntry(word: "Hola", translation: "Hello", language: "es")
        let row = VocabularyRow(entry: entry)
        XCTAssertNotNil(row)
    }
}
