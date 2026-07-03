import SwiftUI

struct CoreBluetoothHubView: View {
    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(BLELab.allCases.filter(\.isDemoLab)) { lab in
                        NavigationLink(value: lab) {
                            BLELabRow(lab: lab)
                        }
                    }
                } header: {
                    Text("Core Bluetooth")
                } footer: {
                    Text("Learn the central and peripheral roles from Apple's Core Bluetooth framework.")
                }

                Section("Reference") {
                    NavigationLink(value: BLELab.reference) {
                        BLELabRow(lab: .reference)
                    }
                }
            }
            .navigationTitle("Core Bluetooth")
            .navigationDestination(for: BLELab.self) { lab in
                switch lab {
                case .central:
                    BLECentralLabView()
                case .peripheral:
                    BLEPeripheralLabView()
                case .reference:
                    BLEReferenceView()
                }
            }
        }
    }
}

#Preview {
    CoreBluetoothHubView()
}
