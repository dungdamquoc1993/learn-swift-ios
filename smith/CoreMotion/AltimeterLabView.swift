import CoreMotion
import SwiftUI

struct AltimeterLabView: View {
    @State private var model = AltimeterLabModel()

    var body: some View {
        Group {
            if model.isAvailable {
                List {
                    Section {
                        MetricRow(
                            label: "Relative Altitude",
                            value: String(format: "%.2f m", model.sample.relativeAltitude)
                        )
                        MetricRow(
                            label: "Pressure",
                            value: String(format: "%.2f kPa", model.sample.pressure)
                        )
                    } header: {
                        Text("CMAltimeter")
                    } footer: {
                        Text("Relative altitude changes as barometric pressure changes. Values are relative to the start point.")
                    }
                }
            } else {
                LabUnavailableView(labName: "Altimeter")
            }
        }
        .navigationTitle("Altimeter")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { model.start() }
        .onDisappear { model.stop() }
    }
}

@MainActor
@Observable
final class AltimeterLabModel {
    var sample = AltitudeSample(relativeAltitude: 0, pressure: 0)
    private var altimeter: CMAltimeter?

    var isAvailable: Bool {
        CMAltimeter.isRelativeAltitudeAvailable()
    }

    func start() {
        guard isAvailable else { return }
        let altimeter = CMAltimeter()
        self.altimeter = altimeter
        altimeter.startRelativeAltitudeUpdates(to: .main) { [weak self] data, _ in
            guard let self, let data else { return }
            self.sample = AltitudeSample(data)
        }
    }

    func stop() {
        altimeter?.stopRelativeAltitudeUpdates()
        altimeter = nil
    }
}

#Preview {
    NavigationStack {
        AltimeterLabView()
    }
}
