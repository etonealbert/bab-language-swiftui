import Foundation
import BabLanguageSDK
import SwiftData

class MainDispatcher: NSObject, KotlinCoroutineContext {
    static let shared = MainDispatcher()
    
    func fold(initial: Any?, operation: @escaping (Any?, any KotlinCoroutineContextElement) -> Any?) -> Any? {
        return initial
    }
    
    func get(key_ key: any KotlinCoroutineContextKey) -> (any KotlinCoroutineContextElement)? {
        return nil
    }
    
    func minusKey(key: any KotlinCoroutineContextKey) -> any KotlinCoroutineContext {
        return self
    }
    
    func plus(context: any KotlinCoroutineContext) -> any KotlinCoroutineContext {
        return self
    }
}

enum SDKFactory {
    
    @MainActor
    static func createSDK(modelContext: ModelContext) -> BrainSDK {
        let userProfileRepo = SwiftDataUserProfileRepository(modelContext: modelContext)
        let vocabularyRepo = SwiftDataVocabularyRepository(modelContext: modelContext)
        let progressRepo = SwiftDataProgressRepository(modelContext: modelContext)
        let dialogHistoryRepo = SwiftDataDialogHistoryRepository(modelContext: modelContext)
        
        return BrainSDK(
            aiProvider: nil,
            coroutineContext: MainDispatcher.shared,
            userProfileRepository: userProfileRepo,
            vocabularyRepository: vocabularyRepo,
            progressRepository: progressRepo,
            dialogHistoryRepository: dialogHistoryRepo
        )
    }
}
