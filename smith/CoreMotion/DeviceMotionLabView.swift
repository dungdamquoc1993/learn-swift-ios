import SwiftUI

struct DeviceMotionLabView: View {
    @State private var model = DeviceMotionLabModel()

    var body: some View {
        Group {
            if model.isAvailable {
                List {
                    Section {
                        SpiritLevelView(
                            rollDegrees: model.sample.attitude.rollDegrees,
                            pitchDegrees: model.sample.attitude.pitchDegrees
                        )
                        .frame(height: 220)
                        .listRowInsets(EdgeInsets())
                    } footer: {
                        Text("Tilt the phone. The bubble moves with roll and pitch from CMAttitude.")
                    }

                    AttitudeMetricsView(attitude: model.sample.attitude)
                    Vector3MetricsView(title: "Gravity", sample: model.sample.gravity, unit: "g")
                    Vector3MetricsView(title: "User Acceleration", sample: model.sample.userAcceleration, unit: "g")
                    Vector3MetricsView(title: "Rotation Rate", sample: model.sample.rotationRate, unit: "rad/s")
                }
            } else {
                LabUnavailableView(labName: "Device Motion")
            }
        }
        .navigationTitle("Device Motion")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { model.start() }
        .onDisappear { model.stop() }
    }
}

@MainActor
@Observable
final class DeviceMotionLabModel {
    var sample = DeviceMotionSample.zero

    var isAvailable: Bool {
        MotionManagerService.shared.isDeviceMotionAvailable
    }

    func start() {
        MotionManagerService.shared.startDeviceMotion { [weak self] motion in
            self?.sample = motion
        }
    }

    func stop() {
        MotionManagerService.shared.stopAll()
    }
}

#Preview {
    NavigationStack {
        DeviceMotionLabView()
    }
}
