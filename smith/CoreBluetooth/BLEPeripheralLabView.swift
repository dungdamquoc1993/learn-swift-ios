import CoreBluetooth
import SwiftUI

struct BLEPeripheralLabView: View {
    @State private var model = BLEPeripheralLabModel()
    @State private var statusDraft = "ready"

    var body: some View {
        Group {
            if model.managerState == .poweredOn {
                List {
                    Section {
                        HStack {
                            Text("Bluetooth")
                            Spacer()
                            BLEStateBadge(state: model.managerState)
                        }
                        BLEMetricRow(label: "Local Name", value: BLELabUUID.localName)
                        BLEMetricRow(label: "Service UUID", value: BLELabUUID.service.uuidString)
                        BLEMetricRow(label: "Subscribers", value: "\(model.subscribedCentrals)")

                        HStack {
                            Button {
                                model.startAdvertising()
                            } label: {
                                Label("Advertise", systemImage: "dot.radiowaves.left.and.right")
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(model.isAdvertising)

                            Button {
                                model.stopAdvertising()
                            } label: {
                                Label("Stop", systemImage: "stop.fill")
                            }
                            .buttonStyle(.bordered)
                            .disabled(!model.isAdvertising)
                        }
                    } header: {
                        Text("Advertisement")
                    } footer: {
                        Text("Open the Central lab or nRF Connect on your Mac mini and connect to StudySmith BLE.")
                    }

                    Section {
                        BLEMetricRow(label: "Command", value: model.commandValue)
                        BLEMetricRow(label: "Status", value: model.statusValue)

                        TextField("New status value", text: $statusDraft)
                            .textFieldStyle(.roundedBorder)

                        Button("Push Status Update") {
                            model.updateStatus(statusDraft)
                        }
                        .buttonStyle(.bordered)
                    } header: {
                        Text("Characteristics")
                    } footer: {
                        Text("Command supports read, write, notify. Status is read-only.")
                    }

                    Section("Event Log") {
                        ForEach(model.logMessages, id: \.self) { message in
                            Text(message)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            } else {
                BLEPoweredOffView(state: model.managerState)
            }
        }
        .navigationTitle("Peripheral")
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear {
            model.stopAdvertising()
        }
    }
}

@MainActor
@Observable
final class BLEPeripheralLabModel: BLEPeripheralEngineDelegate {
    private let engine = BLEPeripheralEngine()

    private(set) var managerState: CBManagerState = .unknown
    private(set) var isAdvertising = false
    private(set) var commandValue = "hello"
    private(set) var statusValue = "ready"
    private(set) var subscribedCentrals = 0
    private(set) var logMessages: [String] = []

    init() {
        engine.delegate = self
        syncFromEngine()
    }

    func peripheralEngineDidUpdate() {
        syncFromEngine()
    }

    private func syncFromEngine() {
        managerState = engine.managerState
        isAdvertising = engine.isAdvertising
        commandValue = engine.commandValue
        statusValue = engine.statusValue
        subscribedCentrals = engine.subscribedCentrals
        logMessages = engine.logMessages
    }

    func startAdvertising() { engine.startAdvertising() }
    func stopAdvertising() { engine.stopAdvertising() }
    func updateStatus(_ value: String) { engine.updateStatus(value) }
}

#Preview {
    NavigationStack {
        BLEPeripheralLabView()
    }
}
