import SwiftUI

struct GyroscopeLabView: View {
    @State private var model = GyroscopeLabModel()

    var body: some View {
        Group {
            if model.isAvailable {
                List {
                    Vector3MetricsView(
                        title: "Rotation Rate",
                        sample: model.sample,
                        unit: "rad/s",
                        footer: "CMGyroData reports how fast the device rotates around each axis."
                    )
                }
            } else {
                LabUnavailableView(labName: "Gyroscope")
            }
        }
        .navigationTitle("Gyroscope")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { model.start() }
        .onDisappear { model.stop() }
    }
}

@MainActor
@Observable
final class GyroscopeLabModel {
    var sample = Vector3Sample.zero

    var isAvailable: Bool {
        MotionManagerService.shared.isGyroAvailable
    }

    func start() {
        MotionManagerService.shared.startGyroscope { [weak self] sample in
            self?.sample = sample
        }
    }

    func stop() {
        MotionManagerService.shared.stopAll()
    }
}

#Preview {
    NavigationStack {
        GyroscopeLabView()
    }
}
