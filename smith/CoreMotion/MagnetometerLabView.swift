import SwiftUI

struct MagnetometerLabView: View {
    @State private var model = MagnetometerLabModel()

    var body: some View {
        Group {
            if model.isAvailable {
                List {
                    Vector3MetricsView(
                        title: "Magnetic Field",
                        sample: model.sample,
                        unit: "µT",
                        footer: "CMMagnetometerData measures the ambient magnetic field relative to the device."
                    )
                }
            } else {
                LabUnavailableView(labName: "Magnetometer")
            }
        }
        .navigationTitle("Magnetometer")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { model.start() }
        .onDisappear { model.stop() }
    }
}

@MainActor
@Observable
final class MagnetometerLabModel {
    var sample = Vector3Sample.zero

    var isAvailable: Bool {
        MotionManagerService.shared.isMagnetometerAvailable
    }

    func start() {
        MotionManagerService.shared.startMagnetometer { [weak self] sample in
            self?.sample = sample
        }
    }

    func stop() {
        MotionManagerService.shared.stopAll()
    }
}

#Preview {
    NavigationStack {
        MagnetometerLabView()
    }
}
