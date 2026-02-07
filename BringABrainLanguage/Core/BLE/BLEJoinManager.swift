import SwiftUI
import CoreBluetooth

@MainActor
class BLEJoinManager: NSObject, ObservableObject {
    @Published var isScanning = false
    @Published var isConnected = false
    @Published var discoveredHosts: [CBPeripheral] = []
    @Published var connectionError: Error?
    
    private var centralManager: CBCentralManager!
    private var connectedPeripheral: CBPeripheral?
    private var gameStateCharacteristic: CBCharacteristic?
    
    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    func startScanning() {
        guard centralManager.state == .poweredOn else {
            connectionError = BLEError.bluetoothPoweredOff
            return
        }
        
        discoveredHosts.removeAll()
        centralManager.scanForPeripherals(
            withServices: [BLEConstants.serviceUUID],
            options: [CBCentralManagerScanOptionAllowDuplicatesKey: false]
        )
        isScanning = true
        
        Task {
            try? await Task.sleep(for: .seconds(BLEConstants.scanDuration))
            if isScanning {
                stopScanning()
            }
        }
    }
    
    func stopScanning() {
        centralManager.stopScan()
        isScanning = false
    }
    
    func connect(to peripheral: CBPeripheral) {
        stopScanning()
        connectedPeripheral = peripheral
        peripheral.delegate = self
        centralManager.connect(peripheral, options: nil)
    }
    
    func disconnect() {
        if let peripheral = connectedPeripheral {
            centralManager.cancelPeripheralConnection(peripheral)
        }
        connectedPeripheral = nil
        gameStateCharacteristic = nil
        isConnected = false
    }
}

extension BLEJoinManager: CBCentralManagerDelegate {
    nonisolated func centralManagerDidUpdateState(_ central: CBCentralManager) {
        Task { @MainActor in
            switch central.state {
            case .poweredOn:
                self.connectionError = nil
            case .poweredOff:
                self.connectionError = BLEError.bluetoothPoweredOff
                self.stopScanning()
            case .unauthorized:
                self.connectionError = BLEError.bluetoothNotAuthorized
            case .unsupported:
                self.connectionError = BLEError.bluetoothNotAvailable
            default:
                break
            }
        }
    }
    
    nonisolated func centralManager(
        _ central: CBCentralManager,
        didDiscover peripheral: CBPeripheral,
        advertisementData: [String: Any],
        rssi RSSI: NSNumber
    ) {
        Task { @MainActor in
            if !discoveredHosts.contains(where: { $0.identifier == peripheral.identifier }) {
                discoveredHosts.append(peripheral)
            }
        }
    }
    
    nonisolated func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        Task { @MainActor in
            isConnected = true
            peripheral.discoverServices([BLEConstants.serviceUUID])
        }
    }
    
    nonisolated func centralManager(
        _ central: CBCentralManager,
        didFailToConnect peripheral: CBPeripheral,
        error: Error?
    ) {
        Task { @MainActor in
            connectionError = BLEError.connectionFailed
            isConnected = false
        }
    }
    
    nonisolated func centralManager(
        _ central: CBCentralManager,
        didDisconnectPeripheral peripheral: CBPeripheral,
        error: Error?
    ) {
        Task { @MainActor in
            isConnected = false
            connectedPeripheral = nil
        }
    }
}

extension BLEJoinManager: CBPeripheralDelegate {
    nonisolated func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let services = peripheral.services else { return }
        
        for service in services where service.uuid == BLEConstants.serviceUUID {
            peripheral.discoverCharacteristics(
                [BLEConstants.gameStateCharacteristicUUID, BLEConstants.playerActionCharacteristicUUID],
                for: service
            )
        }
    }
    
    nonisolated func peripheral(
        _ peripheral: CBPeripheral,
        didDiscoverCharacteristicsFor service: CBService,
        error: Error?
    ) {
        guard let characteristics = service.characteristics else { return }
        
        Task { @MainActor in
            for characteristic in characteristics {
                if characteristic.uuid == BLEConstants.gameStateCharacteristicUUID {
                    gameStateCharacteristic = characteristic
                    peripheral.setNotifyValue(true, for: characteristic)
                }
            }
        }
    }
    
    nonisolated func peripheral(
        _ peripheral: CBPeripheral,
        didUpdateValueFor characteristic: CBCharacteristic,
        error: Error?
    ) {
        guard characteristic.uuid == BLEConstants.gameStateCharacteristicUUID,
              let _ = characteristic.value else { return }
    }
}
