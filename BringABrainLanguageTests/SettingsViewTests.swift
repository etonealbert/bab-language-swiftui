//
//  SettingsViewTests.swift
//  BringABrainLanguageTests
//
//  Created by Antigravity on 06/02/2026.
//

import XCTest
import SwiftUI
@testable import BringABrainLanguage
// import BabLanguageSDK // Might be needed if we mock SDK

final class SettingsViewTests: XCTestCase {
    
    func testSettingsRowInitialization() {
        let icon = "star.fill"
        let title = "Test Row"
        let value = "Value"
        
        let row = SettingsRow(icon: icon, title: title, color: .blue)
        XCTAssertNotNil(row)
        
        let rowWithValue = SettingsRow(icon: icon, title: title, value: value, color: .red)
        XCTAssertNotNil(rowWithValue)
    }
}
