import CoreMotion
import SwiftUI

struct PedometerLabView: View {
    @State private var model = PedometerLabModel()

    var body: some View {
        Group {
            if !model.isServiceAvailable {
                LabUnavailableView(labName: "Pedometer")
            } else if model.authorizationStatus == .authorized {
                List {
                    Section {
                        MetricRow(label: "Steps", value: "\(model.sample.steps)")
                        if let distance = model.sample.distanceMeters {
                            MetricRow(label: "Distance", value: String(format: "%.0f m", distance))
                        }
                        if let ascended = model.sample.floorsAscended {
                            MetricRow(label: "Floors Up", value: "\(ascended)")
                        }
                        if let descended = model.sample.floorsDescended {
                            MetricRow(label: "Floors Down", value: "\(descended)")
                        }
                    } header: {
                        Text("Today")
                    } footer: {
                        Text("CMPedometer reads system step data. Walk around to see values update.")
                    }

                    Section {
                        MetricRow(label: "Status", value: model.authorizationStatus.title)
                    } header: {
                        Text("Authorization")
                    }
                }
            } else {
                MotionAuthorizationBanner(status: model.authorizationStatus) {
                    model.requestAuthorization()
                }
            }
        }
        .navigationTitle("Pedometer")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { model.start() }
        .onDisappear { model.stop() }
    }
}

@MainActor
@Observable
final class PedometerLabModel {
    var sample = PedometerSample(steps: 0, distanceMeters: nil, floorsAscended: nil, floorsDescended: nil)
    var authorizationStatus: MotionAuthorizationStatus = .notDetermined

    private let pedometer = CMPedometer()

    var isServiceAvailable: Bool {
        CMPedometer.isStepCountingAvailable()
    }

    func start() {
        refreshAuthorizationStatus()
        guard authorizationStatus == .authorized else { return }
        startUpdates()
    }

    func stop() {
        pedometer.stopUpdates()
    }

    func requestAuthorization() {
        let now = Date()
        pedometer.queryPedometerData(from: now, to: now) { [weak self] _, _ in
            Task { @MainActor in
                guard let self else { return }
                self.authorizationStatus = MotionAuthorizationStatus.from(CMPedometer.authorizationStatus())
                if self.authorizationStatus == .authorized {
                    self.startUpdates()
                }
            }
        }
    }

    private func refreshAuthorizationStatus() {
        authorizationStatus = MotionAuthorizationStatus.from(CMPedometer.authorizationStatus())
    }

    private func startUpdates() {
        let startOfDay = Calendar.current.startOfDay(for: .now)
        pedometer.startUpdates(from: startOfDay) { [weak self] data, error in
            Task { @MainActor in
                guard let self else { return }
                if let data, let sample = PedometerSample(data) {
                    self.sample = sample
                } else if error != nil {
                    self.authorizationStatus = MotionAuthorizationStatus.from(CMPedometer.authorizationStatus())
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        PedometerLabView()
    }
}
