import Foundation

enum OnboardingStep: Int, CaseIterable {
    case welcome = 0
    case profile = 1
    case languages = 2
    case interests = 3
    case complete = 4
    
    var title: String {
        switch self {
        case .welcome: return "Welcome"
        case .profile: return "About You"
        case .languages: return "Languages"
        case .interests: return "Interests"
        case .complete: return "All Set!"
        }
    }
    
    var progress: Double {
        Double(rawValue) / Double(OnboardingStep.allCases.count - 1)
    }
}
