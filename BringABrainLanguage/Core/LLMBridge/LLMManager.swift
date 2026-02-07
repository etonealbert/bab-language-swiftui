import Foundation
#if canImport(UIKit)
import UIKit
#endif

enum LLMManagerError: Error, Equatable {
    case notInitialized
    case generationFailed(String)
    case notSupported
    
    static func == (lhs: LLMManagerError, rhs: LLMManagerError) -> Bool {
        switch (lhs, rhs) {
        case (.notInitialized, .notInitialized):
            return true
        case (.notSupported, .notSupported):
            return true
        case (.generationFailed(let l), .generationFailed(let r)):
            return l == r
        default:
            return false
        }
    }
}

struct LLMConfiguration: Equatable {
    let targetLanguage: String
    let nativeLanguage: String
    let scenario: String
    let userRole: String
    let aiRole: String
}

final class LLMManager {
    
    static let shared = LLMManager()
    
    private let bridge = LLMBridge()
    private var configuration: LLMConfiguration?
    private var _isInitialized = false
    private var _needsReinitialize = false
    
    #if canImport(UIKit)
    private var memoryWarningObserver: NSObjectProtocol?
    #endif
    
    private init() {
        #if canImport(UIKit)
        memoryWarningObserver = NotificationCenter.default.addObserver(
            forName: UIApplication.didReceiveMemoryWarningNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleMemoryWarning()
        }
        #endif
    }
    
    deinit {
        #if canImport(UIKit)
        if let observer = memoryWarningObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        #endif
    }
    
    var isReady: Bool {
        bridge.checkAvailability() == .available && _isInitialized && !_needsReinitialize
    }
    
    var isInitialized: Bool {
        _isInitialized
    }
    
    var needsReinitialize: Bool {
        _needsReinitialize
    }
    
    var currentConfiguration: LLMConfiguration? {
        configuration
    }
    
    func initialize(
        targetLanguage: String,
        nativeLanguage: String,
        scenario: String,
        userRole: String,
        aiRole: String
    ) async {
        configuration = LLMConfiguration(
            targetLanguage: targetLanguage,
            nativeLanguage: nativeLanguage,
            scenario: scenario,
            userRole: userRole,
            aiRole: aiRole
        )
        
        _ = await bridge.initializeForLanguageLearning(
            targetLanguage: targetLanguage,
            nativeLanguage: nativeLanguage,
            scenario: scenario,
            userRole: userRole,
            aiRole: aiRole
        )
        
        _isInitialized = true
        _needsReinitialize = false
    }
    
    func handleMemoryWarning() {
        bridge.dispose()
        _needsReinitialize = _isInitialized
    }
    
    func reinitializeIfNeeded() async {
        guard _needsReinitialize, let config = configuration else { return }
        
        _ = await bridge.initializeForLanguageLearning(
            targetLanguage: config.targetLanguage,
            nativeLanguage: config.nativeLanguage,
            scenario: config.scenario,
            userRole: config.userRole,
            aiRole: config.aiRole
        )
        
        _needsReinitialize = false
    }
    
    func generate(prompt: String) async throws -> String {
        guard _isInitialized else {
            throw LLMManagerError.notInitialized
        }
        
        if _needsReinitialize {
            await reinitializeIfNeeded()
        }
        
        do {
            return try await bridge.generate(prompt: prompt)
        } catch let error as LLMBridgeError {
            switch error {
            case .sessionNotInitialized:
                throw LLMManagerError.notInitialized
            case .generationFailed(let message):
                throw LLMManagerError.generationFailed(message)
            case .notSupported:
                throw LLMManagerError.notSupported
            }
        }
    }
    
    func generateStream(prompt: String, onToken: @escaping (String) -> Void) async throws {
        guard _isInitialized else {
            throw LLMManagerError.notInitialized
        }
        
        if _needsReinitialize {
            await reinitializeIfNeeded()
        }
        
        try await bridge.generateStream(prompt: prompt, onToken: onToken)
    }
    
    func reset() {
        bridge.dispose()
        configuration = nil
        _isInitialized = false
        _needsReinitialize = false
    }
}
