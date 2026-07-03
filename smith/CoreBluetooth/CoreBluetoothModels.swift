import CoreBluetooth
import Foundation

enum BLELab: String, CaseIterable, Identifiable, Hashable {
    case central
    case peripheral
    case reference

    var id: String { rawValue }

    var title: String {
        switch self {
        case .central: "Central"
        case .peripheral: "Peripheral Simulator"
        case .reference: "Reference"
        }
    }

    var subtitle: String {
        switch self {
        case .central: "CBCentralManager — scan, connect, read/write/notify"
        case .peripheral: "CBPeripheralManager — advertise a local GATT service"
        case .reference: "Roles, GATT, and testing tips"
        }
    }

    var systemImage: String {
        switch self {
        case .central: "antenna.radiowaves.left.and.right"
        case .peripheral: "dot.radiowaves.left.and.right"
        case .reference: "info.circle"
        }
    }

    var isDemoLab: Bool {
        self != .reference
    }
}

enum BLELabUUID {
    static let service = CBUUID(string: "A1B2C3D4-E5F6-7890-ABCD-EF1234567890")
    static let command = CBUUID(string: "A1B2C3D4-E5F6-7890-ABCD-EF1234567891")
    static let status = CBUUID(string: "A1B2C3D4-E5F6-7890-ABCD-EF1234567892")
    static let localName = "StudySmith BLE"
}

enum BLEConnectionPhase: Equatable {
    case disconnected
    case connecting
    case connected
    case failed(String)
}

struct BLEPeripheralItem: Identifiable, Equatable {
    let id: UUID
    var name: String
    var rssi: Int
    var isStudySmithService: Bool

    static func == (lhs: BLEPeripheralItem, rhs: BLEPeripheralItem) -> Bool {
        lhs.id == rhs.id
    }
}

struct BLEServiceItem: Identifiable, Equatable {
    let id: String
    let uuid: CBUUID
    var characteristics: [BLECharacteristicItem]
}

struct BLECharacteristicItem: Identifiable, Equatable {
    let id: String
    let uuid: CBUUID
    let properties: CBCharacteristicProperties
    var valueText: String
    var isNotifying: Bool

    var propertiesText: String {
        var parts: [String] = []
        if properties.contains(.read) { parts.append("read") }
        if properties.contains(.write) { parts.append("write") }
        if properties.contains(.writeWithoutResponse) { parts.append("writeNoResp") }
        if properties.contains(.notify) { parts.append("notify") }
        if properties.contains(.indicate) { parts.append("indicate") }
        return parts.joined(separator: ", ")
    }
}

struct BLEReferenceTopic: Identifiable {
    let id: String
    let title: String
    let summary: String
}

extension BLEReferenceTopic {
    static let catalog: [BLEReferenceTopic] = [
        BLEReferenceTopic(
            id: "roles",
            title: "Central vs Peripheral",
            summary: "A central scans and connects. A peripheral advertises services. Your iPhone can act as either role."
        ),
        BLEReferenceTopic(
            id: "gatt",
            title: "GATT Hierarchy",
            summary: "Peripheral exposes services. Each service has characteristics. Characteristics may have descriptors and support read, write, and notify."
        ),
        BLEReferenceTopic(
            id: "testing",
            title: "Testing With Mac mini",
            summary: "Run Peripheral Simulator on iPhone, then connect from nRF Connect or LightBlue on Mac. Or run Central on iPhone and connect to another BLE device."
        ),
        BLEReferenceTopic(
            id: "background",
            title: "Background Modes",
            summary: "Foreground labs are enough for learning. Background BLE needs UIBackgroundModes bluetooth-central or bluetooth-peripheral."
        ),
        BLEReferenceTopic(
            id: "channel",
            title: "Channel Sounding",
            summary: "iOS 26+ can measure distance between BLE devices. Requires supported hardware and a dedicated session configuration."
        ),
    ]
}

func bleDataDescription(_ data: Data?) -> String {
    guard let data, !data.isEmpty else { return "Empty" }
    let utf8 = String(data: data, encoding: .utf8) ?? ""
    let hex = data.map { String(format: "%02X", $0) }.joined(separator: " ")
    if utf8.isEmpty {
        return hex
    }
    return "\(utf8) (\(hex))"
}
