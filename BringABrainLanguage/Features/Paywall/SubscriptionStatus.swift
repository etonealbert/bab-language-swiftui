import Foundation

enum AppSubscriptionStatus: Equatable {
    case unknown
    case notSubscribed
    case subscribed
}

enum SubscriptionError: Error {
    case verificationFailed
    case purchaseFailed
    case productNotFound
}
