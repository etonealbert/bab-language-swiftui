import CoreBluetooth

enum BLEConstants {

    static let serviceUUID = CBUUID(string: "BAB10000-1A46-0001-0000-000000000001")
    static let gameStateCharacteristicUUID = CBUUID(string: "BAB10000-1A46-0001-0000-000000000002")
    static let playerActionCharacteristicUUID = CBUUID(string: "BAB10000-1A46-0001-0000-000000000003")
    static let chatMessageCharacteristicUUID = CBUUID(string: "BAB10000-1A46-0001-0000-000000000004")
    static let playerInfoCharacteristicUUID = CBUUID(string: "BAB10000-1A46-0001-0000-000000000005")
    
    static let maxPeers = 4
    static let connectionTimeout: TimeInterval = 30
    static let scanDuration: TimeInterval = 15
}

enum BLEError: LocalizedError {
    case bluetoothNotAvailable
    case bluetoothNotAuthorized
    case bluetoothPoweredOff
    case connectionFailed
    case connectionTimeout
    case serviceNotFound
    case characteristicNotFound
    case writeFailure
    case invalidData
    case maxPeersReached
    
    var errorDescription: String? {
        switch self {
        case .bluetoothNotAvailable:
            return "Bluetooth is not available on this device"
        case .bluetoothNotAuthorized:
            return "Bluetooth access not authorized. Please enable in Settings."
        case .bluetoothPoweredOff:
            return "Bluetooth is turned off. Please enable Bluetooth."
        case .connectionFailed:
            return "Failed to connect to the host"
        case .connectionTimeout:
            return "Connection timed out"
        case .serviceNotFound:
            return "Game service not found on host"
        case .characteristicNotFound:
            return "Required characteristic not found"
        case .writeFailure:
            return "Failed to send data to peer"
        case .invalidData:
            return "Received invalid data from peer"
        case .maxPeersReached:
            return "Maximum number of players reached"
        }
    }
}
