import CoreBluetooth
import Foundation

@MainActor
protocol BLECentralEngineDelegate: AnyObject {
    func centralEngineDidUpdate()
}

@MainActor
final class BLECentralEngine: NSObject {
    weak var delegate: BLECentralEngineDelegate?

    private(set) var managerState: CBManagerState = .unknown
    private(set) var isScanning = false
    private(set) var connectionPhase: BLEConnectionPhase = .disconnected
    private(set) var discoveredPeripherals: [BLEPeripheralItem] = []
    private(set) var connectedName = ""
    private(set) var services: [BLEServiceItem] = []
    private(set) var logMessages: [String] = []
    private(set) var filterStudySmithOnly = false

    private var centralManager: CBCentralManager!
    private var connectedPeripheral: CBPeripheral?
    private var peripheralMap: [UUID: CBPeripheral] = [:]
    private var characteristicMap: [String: CBCharacteristic] = [:]

    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: .main)
    }

    func setFilterStudySmithOnly(_ enabled: Bool) {
        filterStudySmithOnly = enabled
    }

    func startScanning() {
        guard managerState == .poweredOn else { return }
        discoveredPeripherals.removeAll()
        peripheralMap.removeAll()
        appendLog("Started scanning.")

        let services = filterStudySmithOnly ? [BLELabUUID.service] : nil
        centralManager.scanForPeripherals(
            withServices: services,
            options: [CBCentralManagerScanOptionAllowDuplicatesKey: true]
        )
        isScanning = true
        notify()
    }

    func stopScanning() {
        guard isScanning else { return }
        centralManager.stopScan()
        isScanning = false
        appendLog("Stopped scanning.")
        notify()
    }

    func connect(peripheralID: UUID) {
        guard let peripheral = peripheralMap[peripheralID] else { return }
        stopScanning()
        connectionPhase = .connecting
        connectedName = peripheral.name ?? "Unnamed"
        connectedPeripheral = peripheral
        peripheral.delegate = self
        centralManager.connect(peripheral, options: nil)
        appendLog("Connecting to \(connectedName)...")
        notify()
    }

    func disconnect() {
        guard let peripheral = connectedPeripheral else { return }
        centralManager.cancelPeripheralConnection(peripheral)
    }

    func read(characteristicID: String) {
        guard let characteristic = characteristicMap[characteristicID],
              let peripheral = connectedPeripheral else { return }
        peripheral.readValue(for: characteristic)
        appendLog("Read requested for \(characteristic.uuid.uuidString).")
    }

    func write(characteristicID: String, text: String) {
        guard let characteristic = characteristicMap[characteristicID],
              let peripheral = connectedPeripheral,
              let data = text.data(using: .utf8) else { return }

        let writeType: CBCharacteristicWriteType =
            characteristic.properties.contains(.write) ? .withResponse : .withoutResponse
        peripheral.writeValue(data, for: characteristic, type: writeType)
        appendLog("Wrote \"\(text)\" to \(characteristic.uuid.uuidString).")
    }

    func setNotify(characteristicID: String, enabled: Bool) {
        guard let characteristic = characteristicMap[characteristicID],
              let peripheral = connectedPeripheral else { return }
        peripheral.setNotifyValue(enabled, for: characteristic)
        appendLog("\(enabled ? "Subscribed to" : "Unsubscribed from") \(characteristic.uuid.uuidString).")
    }

    private func resetConnectionState() {
        connectedPeripheral = nil
        connectedName = ""
        services = []
        characteristicMap = [:]
        connectionPhase = .disconnected
    }

    private func appendLog(_ message: String) {
        let entry = "\(Date().formatted(date: .omitted, time: .standard)) — \(message)"
        logMessages.insert(entry, at: 0)
        if logMessages.count > 20 {
            logMessages.removeLast()
        }
    }

    private func notify() {
        delegate?.centralEngineDidUpdate()
    }

    private func rebuildServiceItems(from peripheral: CBPeripheral) {
        services = (peripheral.services ?? []).map { service in
            BLEServiceItem(
                id: service.uuid.uuidString,
                uuid: service.uuid,
                characteristics: (service.characteristics ?? []).map { characteristic in
                    characteristicMap[characteristic.uuid.uuidString] = characteristic
                    return BLECharacteristicItem(
                        id: characteristic.uuid.uuidString,
                        uuid: characteristic.uuid,
                        properties: characteristic.properties,
                        valueText: bleDataDescription(characteristic.value),
                        isNotifying: characteristic.isNotifying
                    )
                }
            )
        }
    }

    private func updateCharacteristicValue(_ characteristic: CBCharacteristic) {
        guard let index = services.firstIndex(where: { service in
            service.characteristics.contains { $0.id == characteristic.uuid.uuidString }
        }) else { return }

        services[index].characteristics = services[index].characteristics.map { item in
            guard item.id == characteristic.uuid.uuidString else { return item }
            var updated = item
            updated.valueText = bleDataDescription(characteristic.value)
            updated.isNotifying = characteristic.isNotifying
            return updated
        }
    }
}

extension BLECentralEngine: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        managerState = central.state
        appendLog("Central state: \(central.state.rawValue).")
        if central.state != .poweredOn {
            stopScanning()
            resetConnectionState()
        }
        notify()
    }

    func centralManager(
        _ central: CBCentralManager,
        didDiscover peripheral: CBPeripheral,
        advertisementData: [String: Any],
        rssi RSSI: NSNumber
    ) {
        let item = BLEPeripheralItem(
            id: peripheral.identifier,
            name: peripheral.name ?? advertisementData[CBAdvertisementDataLocalNameKey] as? String ?? "Unnamed",
            rssi: RSSI.intValue,
            isStudySmithService: (advertisementData[CBAdvertisementDataServiceUUIDsKey] as? [CBUUID])?
                .contains(BLELabUUID.service) ?? false
        )

        peripheralMap[peripheral.identifier] = peripheral
        if let index = discoveredPeripherals.firstIndex(where: { $0.id == item.id }) {
            discoveredPeripherals[index] = item
        } else {
            discoveredPeripherals.append(item)
        }
        discoveredPeripherals.sort { $0.rssi > $1.rssi }
        notify()
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        connectionPhase = .connected
        connectedPeripheral = peripheral
        connectedName = peripheral.name ?? "Unnamed"
        appendLog("Connected to \(connectedName).")
        peripheral.discoverServices(nil)
        notify()
    }

    func centralManager(
        _ central: CBCentralManager,
        didFailToConnect peripheral: CBPeripheral,
        error: Error?
    ) {
        connectionPhase = .failed(error?.localizedDescription ?? "Connection failed.")
        appendLog("Failed to connect.")
        notify()
    }

    func centralManager(
        _ central: CBCentralManager,
        didDisconnectPeripheral peripheral: CBPeripheral,
        error: Error?
    ) {
        appendLog("Disconnected.")
        resetConnectionState()
        notify()
    }
}

extension BLECentralEngine: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let error {
            connectionPhase = .failed(error.localizedDescription)
            appendLog("Service discovery failed.")
            notify()
            return
        }

        peripheral.services?.forEach { service in
            peripheral.discoverCharacteristics(nil, for: service)
        }
        appendLog("Discovered \(peripheral.services?.count ?? 0) services.")
        rebuildServiceItems(from: peripheral)
        notify()
    }

    func peripheral(
        _ peripheral: CBPeripheral,
        didDiscoverCharacteristicsFor service: CBService,
        error: Error?
    ) {
        if let error {
            appendLog("Characteristic discovery failed for \(service.uuid.uuidString).")
            notify()
            return
        }

        rebuildServiceItems(from: peripheral)
        appendLog("Discovered characteristics for \(service.uuid.uuidString).")
        notify()
    }

    func peripheral(
        _ peripheral: CBPeripheral,
        didUpdateValueFor characteristic: CBCharacteristic,
        error: Error?
    ) {
        if let error {
            appendLog("Read failed: \(error.localizedDescription)")
        } else {
            appendLog("Updated value for \(characteristic.uuid.uuidString).")
            updateCharacteristicValue(characteristic)
        }
        notify()
    }

    func peripheral(
        _ peripheral: CBPeripheral,
        didWriteValueFor characteristic: CBCharacteristic,
        error: Error?
    ) {
        if let error {
            appendLog("Write failed: \(error.localizedDescription)")
        } else {
            appendLog("Write confirmed for \(characteristic.uuid.uuidString).")
            updateCharacteristicValue(characteristic)
        }
        notify()
    }

    func peripheral(
        _ peripheral: CBPeripheral,
        didUpdateNotificationStateFor characteristic: CBCharacteristic,
        error: Error?
    ) {
        if let error {
            appendLog("Notify state failed: \(error.localizedDescription)")
        } else {
            appendLog("Notify state changed for \(characteristic.uuid.uuidString).")
            updateCharacteristicValue(characteristic)
        }
        notify()
    }
}
