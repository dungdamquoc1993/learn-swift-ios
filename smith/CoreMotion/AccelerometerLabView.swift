import SwiftUI

struct AccelerometerLabView: View {
    @State private var model = AccelerometerLabModel()

    var body: some View {
        Group {
            if model.isAvailable {
                List {
                    Vector3MetricsView(
                        title: "Raw Acceleration",
                        sample: model.sample,
                        unit: "g",
                        footer: "CMAccelerometerData includes gravity. Compare with Device Motion userAcceleration."
                    )
                }
            } else {
                LabUnavailableView(labName: "Accelerometer")
            }
        }
        .navigationTitle("Accelerometer")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { model.start() }
        .onDisappear { model.stop() }
    }
}

@MainActor
@Observable
final class AccelerometerLabModel {
    var sample = Vector3Sample.zero

    var isAvailable: Bool {
        MotionManagerService.shared.isAccelerometerAvailable
    }

    func start() {
        MotionManagerService.shared.startAccelerometer { [weak self] sample in
            self?.sample = sample
        }
    }

    func stop() {
        MotionManagerService.shared.stopAll()
    }
}

#Preview {
    NavigationStack {
        AccelerometerLabView()
    }
}
