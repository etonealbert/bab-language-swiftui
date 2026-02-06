//
//  SDKObserverTests.swift
//  BringABrainLanguageTests
//
//  Created by Whatsername on 06/02/2026.
//

import XCTest
@testable import BringABrainLanguage

final class SDKObserverTests: XCTestCase {
    
    func testSDKObserverStructureExists() {
        let typeName = String(describing: SDKObserver.self)
        XCTAssertEqual(typeName, "SDKObserver")
    }
}
