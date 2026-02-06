import XCTest
@testable import BringABrainLanguage

final class OnboardingStepTests: XCTestCase {

    func testOnboardingStepTitles() {
        XCTAssertEqual(OnboardingStep.welcome.title, "Welcome")
        XCTAssertEqual(OnboardingStep.profile.title, "About You")
        XCTAssertEqual(OnboardingStep.languages.title, "Languages")
        XCTAssertEqual(OnboardingStep.interests.title, "Interests")
        XCTAssertEqual(OnboardingStep.complete.title, "All Set!")
    }

    func testOnboardingStepProgress() {
        XCTAssertEqual(OnboardingStep.welcome.progress, 0.0, accuracy: 0.001)
        XCTAssertEqual(OnboardingStep.profile.progress, 0.25, accuracy: 0.001)
        XCTAssertEqual(OnboardingStep.languages.progress, 0.5, accuracy: 0.001)
        XCTAssertEqual(OnboardingStep.interests.progress, 0.75, accuracy: 0.001)
        XCTAssertEqual(OnboardingStep.complete.progress, 1.0, accuracy: 0.001)
    }
    
    func testOnboardingStepCount() {
        XCTAssertEqual(OnboardingStep.allCases.count, 5)
    }
}
