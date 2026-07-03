import CoreBluetooth
import SwiftUI

struct BLECentralLabView: View {
    @State private var model = BLECentralLabModel()
    @State private var writeText = "move_forward"

    var body: some View {
        Group {
            if model.managerState == .poweredOn {
                List {
                    sessionSection
                    scanSection

                    if model.connectionPhase == .connected {
                        servicesSection
                        logSection
                    } else if case .failed(let message) = model.connectionPhase {
                        Section {
                            Label(message, systemImage: "exclamationmark.triangle")
                                .foregroundStyle(.red)
                        }
                    }
                }
            } else {
                BLEPoweredOffView(state: model.managerState)
            }
        }
        .navigationTitle("Central")
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear {
            model.stopScanning()
            model.disconnect()
        }
    }

    private var sessionSection: some View {
        Section {
            HStack {
                Text("Bluetooth")
                Spacer()
                BLEStateBadge(state: model.managerState)
            }
            BLEMetricRow(label: "Connection", value: connectionLabel)
            if model.connectionPhase == .connected {
                BLEMetricRow(label: "Device", value: model.connectedName)
                Button("Disconnect", role: .destructive) {
                    model.disconnect()
                }
            }
        } header: {
            Text("Session")
        }
    }

    private var scanSection: some View {
        Section {
            Toggle("Filter StudySmith Service", isOn: $model.filterStudySmithOnly)
                .onChange(of: model.filterStudySmithOnly) { _, value in
                    model.setFilter(value)
                }

            HStack {
                Button {
                    model.startScanning()
                } label: {
                    Label("Scan", systemImage: "dot.radiowaves.left.and.right")
                }
                .buttonStyle(.borderedProminent)
                .disabled(model.isScanning || model.connectionPhase == .connected)

                Button {
                    model.stopScanning()
                } label: {
                    Label("Stop", systemImage: "stop.fill")
                }
                .buttonStyle(.bordered)
                .disabled(!model.isScanning)
            }

            if model.discoveredPeripherals.isEmpty {
                Text("No peripherals yet. Start scanning, or run the Peripheral Simulator on another device.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(model.discoveredPeripherals) { item in
                    Button {
                        model.connect(peripheralID: item.id)
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(item.name)
                                    .font(.headline)
                                Text(item.id.uuidString)
                                    .font(.caption2.monospaced())
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                            }
                            Spacer()
                            VStack(alignment: .trailing, spacing: 4) {
                                Text("\(item.rssi) dBm")
                                    .font(.subheadline.monospacedDigit())
                                if item.isStudySmithService {
                                    Text("StudySmith")
                                        .font(.caption2.weight(.semibold))
                                        .foregroundStyle(.teal)
                                }
                            }
                        }
                    }
                    .disabled(model.connectionPhase == .connected || model.connectionPhase == .connecting)
                }
            }
        } header: {
            Text("Scan")
        } footer: {
            Text("CBCentralManager discovers peripherals, connects, and walks the GATT tree.")
        }
    }

    private var servicesSection: some View {
        Section {
            ForEach(model.services) { service in
                DisclosureGroup(service.uuid.uuidString) {
                    ForEach(service.characteristics) { characteristic in
                        VStack(alignment: .leading, spacing: 8) {
                            Text(characteristic.uuid.uuidString)
                                .font(.caption.monospaced())
                            Text(characteristic.propertiesText)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(characteristic.valueText)
                                .font(.subheadline)

                            HStack {
                                if characteristic.properties.contains(.read) {
                                    Button("Read") {
                                        model.read(characteristicID: characteristic.id)
                                    }
                                    .buttonStyle(.bordered)
                                }
                                if characteristic.properties.contains(.notify) || characteristic.properties.contains(.indicate) {
                                    Button(characteristic.isNotifying ? "Unnotify" : "Notify") {
                                        model.setNotify(
                                            characteristicID: characteristic.id,
                                            enabled: !characteristic.isNotifying
                                        )
                                    }
                                    .buttonStyle(.bordered)
                                }
                            }

                            if characteristic.properties.contains(.write)
                                || characteristic.properties.contains(.writeWithoutResponse) {
                                TextField("Write UTF-8 text", text: $writeText)
                                    .textFieldStyle(.roundedBorder)
                                Button("Write") {
                                    model.write(characteristicID: characteristic.id, text: writeText)
                                }
                                .buttonStyle(.borderedProminent)
                            }
                        }
                        .padding(.vertical, 6)
                    }
                }
            }
        } header: {
            Text("GATT")
        }
    }

    private var logSection: some View {
        Section {
            ForEach(model.logMessages, id: \.self) { message in
                Text(message)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        } header: {
            Text("Event Log")
        }
    }

    private var connectionLabel: String {
        switch model.connectionPhase {
        case .disconnected: "Disconnected"
        case .connecting: "Connecting"
        case .connected: "Connected"
        case .failed: "Failed"
        }
    }
}

@MainActor
@Observable
final class BLECentralLabModel: BLECentralEngineDelegate {
    private let engine = BLECentralEngine()

    private(set) var managerState: CBManagerState = .unknown
    private(set) var isScanning = false
    private(set) var connectionPhase: BLEConnectionPhase = .disconnected
    private(set) var discoveredPeripherals: [BLEPeripheralItem] = []
    private(set) var connectedName = ""
    private(set) var services: [BLEServiceItem] = []
    private(set) var logMessages: [String] = []
    var filterStudySmithOnly = false

    init() {
        engine.delegate = self
        syncFromEngine()
    }

    func centralEngineDidUpdate() {
        syncFromEngine()
    }

    private func syncFromEngine() {
        managerState = engine.managerState
        isScanning = engine.isScanning
        connectionPhase = engine.connectionPhase
        discoveredPeripherals = engine.discoveredPeripherals
        connectedName = engine.connectedName
        services = engine.services
        logMessages = engine.logMessages
        filterStudySmithOnly = engine.filterStudySmithOnly
    }

    func setFilter(_ enabled: Bool) {
        filterStudySmithOnly = enabled
        engine.setFilterStudySmithOnly(enabled)
    }

    func startScanning() { engine.startScanning() }
    func stopScanning() { engine.stopScanning() }
    func connect(peripheralID: UUID) { engine.connect(peripheralID: peripheralID) }
    func disconnect() { engine.disconnect() }
    func read(characteristicID: String) { engine.read(characteristicID: characteristicID) }
    func write(characteristicID: String, text: String) { engine.write(characteristicID: characteristicID, text: text) }
    func setNotify(characteristicID: String, enabled: Bool) { engine.setNotify(characteristicID: characteristicID, enabled: enabled) }
}

#Preview {
    NavigationStack {
        BLECentralLabView()
    }
}
