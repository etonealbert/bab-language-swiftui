import Foundation

enum LLMBridgeFactory {
    static func createBridge() -> Any? {
        if #available(iOS 26.0, *) {
            return IOSLLMBridge()
        }
        return nil
    }
    
    static var isAvailable: Bool {
        if #available(iOS 26.0, *) {
            return true
        }
        return false
    }
}
