import CoreBluetooth
import Foundation

@MainActor
protocol BLEPeripheralEngineDelegate: AnyObject {
    func peripheralEngineDidUpdate()
}

@MainActor
final class BLEPeripheralEngine: NSObject {
    weak var delegate: BLEPeripheralEngineDelegate?

    private(set) var managerState: CBManagerState = .unknown
    private(set) var isAdvertising = false
    private(set) var commandValue = "hello"
    private(set) var statusValue = "ready"
    private(set) var subscribedCentrals = 0
    private(set) var logMessages: [String] = []

    private var peripheralManager: CBPeripheralManager!
    private var commandCharacteristic: CBMutableCharacteristic?
    private var statusCharacteristic: CBMutableCharacteristic?

    override init() {
        super.init()
        peripheralManager = CBPeripheralManager(delegate: self, queue: .main)
    }

    func startAdvertising() {
        guard managerState == .poweredOn, !isAdvertising else { return }
        setupServiceIfNeeded()

        peripheralManager.startAdvertising([
            CBAdvertisementDataLocalNameKey: BLELabUUID.localName,
            CBAdvertisementDataServiceUUIDsKey: [BLELabUUID.service],
        ])
        isAdvertising = true
        appendLog("Started advertising \(BLELabUUID.localName).")
        notify()
    }

    func stopAdvertising() {
        guard isAdvertising else { return }
        peripheralManager.stopAdvertising()
        isAdvertising = false
        appendLog("Stopped advertising.")
        notify()
    }

    func updateStatus(_ value: String) {
        statusValue = value
        guard let characteristic = statusCharacteristic,
              let data = value.data(using: .utf8) else { return }
        characteristic.value = data
        let didSend = peripheralManager.updateValue(
            data,
            for: characteristic,
            onSubscribedCentrals: nil
        )
        appendLog(didSend ? "Status updated to \"\(value)\"." : "Status update queued.")
        notify()
    }

    private func setupServiceIfNeeded() {
        guard commandCharacteristic == nil else { return }

        let command = CBMutableCharacteristic(
            type: BLELabUUID.command,
            properties: [.read, .write, .notify],
            value: nil,
            permissions: [.readable, .writeable]
        )
        let status = CBMutableCharacteristic(
            type: BLELabUUID.status,
            properties: [.read],
            value: statusValue.data(using: .utf8),
            permissions: [.readable]
        )

        let service = CBMutableService(type: BLELabUUID.service, primary: true)
        service.characteristics = [command, status]
        peripheralManager.add(service)

        commandCharacteristic = command
        statusCharacteristic = status
        appendLog("Published GATT service.")
    }

    private func appendLog(_ message: String) {
        let entry = "\(Date().formatted(date: .omitted, time: .standard)) — \(message)"
        logMessages.insert(entry, at: 0)
        if logMessages.count > 20 {
            logMessages.removeLast()
        }
    }

    private func notify() {
        delegate?.peripheralEngineDidUpdate()
    }
}

extension BLEPeripheralEngine: CBPeripheralManagerDelegate {
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        managerState = peripheral.state
        appendLog("Peripheral state: \(peripheral.state.rawValue).")
        if peripheral.state != .poweredOn {
            isAdvertising = false
        }
        notify()
    }

    func peripheralManagerDidStartAdvertising(_ peripheral: CBPeripheralManager, error: Error?) {
        if let error {
            isAdvertising = false
            appendLog("Advertising failed: \(error.localizedDescription)")
        } else {
            appendLog("Advertising confirmed.")
        }
        notify()
    }

    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveRead request: CBATTRequest) {
        if request.characteristic.uuid == BLELabUUID.command {
            request.value = commandValue.data(using: .utf8)
        } else if request.characteristic.uuid == BLELabUUID.status {
            request.value = statusValue.data(using: .utf8)
        } else {
            peripheral.respond(to: request, withResult: .attributeNotFound)
            return
        }

        peripheral.respond(to: request, withResult: .success)
        appendLog("Responded to read on \(request.characteristic.uuid.uuidString).")
        notify()
    }

    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveWrite requests: [CBATTRequest]) {
        for request in requests {
            guard request.characteristic.uuid == BLELabUUID.command,
                  let data = request.value,
                  let text = String(data: data, encoding: .utf8) else {
                peripheral.respond(to: request, withResult: .writeNotPermitted)
                continue
            }

            commandValue = text
            commandCharacteristic?.value = data
            peripheral.respond(to: request, withResult: .success)
            appendLog("Received write: \"\(text)\".")

            _ = peripheralManager.updateValue(
                data,
                for: commandCharacteristic!,
                onSubscribedCentrals: nil
            )
        }
        notify()
    }

    func peripheralManager(
        _ peripheral: CBPeripheralManager,
        central: CBCentral,
        didSubscribeTo characteristic: CBCharacteristic
    ) {
        subscribedCentrals += 1
        appendLog("Central subscribed to \(characteristic.uuid.uuidString).")
        notify()
    }

    func peripheralManager(
        _ peripheral: CBPeripheralManager,
        central: CBCentral,
        didUnsubscribeFrom characteristic: CBCharacteristic
    ) {
        subscribedCentrals = max(0, subscribedCentrals - 1)
        appendLog("Central unsubscribed from \(characteristic.uuid.uuidString).")
        notify()
    }
}
