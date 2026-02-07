import SwiftUI
import CoreBluetooth

@MainActor
class BLEHostManager: NSObject, ObservableObject {
    @Published var isAdvertising = false
    @Published var connectedPeers: [CBCentral] = []
    @Published var connectionError: Error?
    
    private var peripheralManager: CBPeripheralManager!
    private var gameStateCharacteristic: CBMutableCharacteristic!
    
    override init() {
        super.init()
        peripheralManager = CBPeripheralManager(delegate: self, queue: nil)
    }
    
    func startAdvertising(hostName: String) {
        guard peripheralManager.state == .poweredOn else {
            connectionError = BLEError.bluetoothPoweredOff
            return
        }
        
        let service = CBMutableService(type: BLEConstants.serviceUUID, primary: true)
        
        gameStateCharacteristic = CBMutableCharacteristic(
            type: BLEConstants.gameStateCharacteristicUUID,
            properties: [.read, .notify],
            value: nil,
            permissions: .readable
        )
        
        let playerActionCharacteristic = CBMutableCharacteristic(
            type: BLEConstants.playerActionCharacteristicUUID,
            properties: [.write],
            value: nil,
            permissions: .writeable
        )
        
        service.characteristics = [gameStateCharacteristic, playerActionCharacteristic]
        peripheralManager.add(service)
        
        peripheralManager.startAdvertising([
            CBAdvertisementDataServiceUUIDsKey: [BLEConstants.serviceUUID],
            CBAdvertisementDataLocalNameKey: hostName
        ])
        
        isAdvertising = true
    }
    
    func stopAdvertising() {
        peripheralManager.stopAdvertising()
        peripheralManager.removeAllServices()
        connectedPeers.removeAll()
        isAdvertising = false
    }
    
    func broadcastGameState(_ state: Data) {
        guard let characteristic = gameStateCharacteristic else { return }
        peripheralManager.updateValue(
            state,
            for: characteristic,
            onSubscribedCentrals: nil
        )
    }
}

extension BLEHostManager: CBPeripheralManagerDelegate {
    nonisolated func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        Task { @MainActor in
            switch peripheral.state {
            case .poweredOn:
                self.connectionError = nil
            case .poweredOff:
                self.connectionError = BLEError.bluetoothPoweredOff
                self.stopAdvertising()
            case .unauthorized:
                self.connectionError = BLEError.bluetoothNotAuthorized
            case .unsupported:
                self.connectionError = BLEError.bluetoothNotAvailable
            default:
                break
            }
        }
    }
    
    nonisolated func peripheralManager(
        _ peripheral: CBPeripheralManager,
        central: CBCentral,
        didSubscribeTo characteristic: CBCharacteristic
    ) {
        Task { @MainActor in
            if connectedPeers.count < BLEConstants.maxPeers {
                connectedPeers.append(central)
            }
        }
    }
    
    nonisolated func peripheralManager(
        _ peripheral: CBPeripheralManager,
        central: CBCentral,
        didUnsubscribeFrom characteristic: CBCharacteristic
    ) {
        Task { @MainActor in
            connectedPeers.removeAll { $0.identifier == central.identifier }
        }
    }
    
    nonisolated func peripheralManager(
        _ peripheral: CBPeripheralManager,
        didReceiveWrite requests: [CBATTRequest]
    ) {
        for request in requests {
            if request.characteristic.uuid == BLEConstants.playerActionCharacteristicUUID,
               let _ = request.value {
                peripheral.respond(to: request, withResult: .success)
            }
        }
    }
}
