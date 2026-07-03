import SwiftUI

struct CoreMotionHubView: View {
    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(MotionLab.allCases.filter(\.isDemoLab)) { lab in
                        NavigationLink(value: lab) {
                            MotionLabRow(lab: lab)
                        }
                    }
                } header: {
                    Text("iPhone Demos")
                } footer: {
                    Text("Processed device motion removes gravity bias. Raw accelerometer values still include gravity.")
                }

                Section("Reference") {
                    NavigationLink(value: MotionLab.unsupportedAPIs) {
                        MotionLabRow(lab: .unsupportedAPIs)
                    }
                }
            }
            .navigationTitle("Core Motion")
            .navigationDestination(for: MotionLab.self) { lab in
                switch lab {
                case .deviceMotion:
                    DeviceMotionLabView()
                case .accelerometer:
                    AccelerometerLabView()
                case .gyroscope:
                    GyroscopeLabView()
                case .magnetometer:
                    MagnetometerLabView()
                case .altimeter:
                    AltimeterLabView()
                case .pedometer:
                    PedometerLabView()
                case .motionActivity:
                    MotionActivityLabView()
                case .unsupportedAPIs:
                    MotionUnsupportedAPIsView()
                }
            }
        }
    }
}

#Preview {
    CoreMotionHubView()
}
