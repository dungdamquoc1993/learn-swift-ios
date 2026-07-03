import CoreMotion
import SwiftUI

struct MotionActivityLabView: View {
    @State private var model = MotionActivityLabModel()

    var body: some View {
        Group {
            if !model.isServiceAvailable {
                LabUnavailableView(labName: "Motion Activity")
            } else if model.authorizationStatus == .authorized {
                List {
                    Section {
                        MetricRow(label: "Primary", value: model.sample.primaryLabel)
                        MetricRow(label: "Confidence", value: model.sample.confidenceLabel)
                    } header: {
                        Text("Current Activity")
                    }

                    Section {
                        activityFlag("Stationary", isOn: model.sample.stationary)
                        activityFlag("Walking", isOn: model.sample.walking)
                        activityFlag("Running", isOn: model.sample.running)
                        activityFlag("Automotive", isOn: model.sample.automotive)
                        activityFlag("Cycling", isOn: model.sample.cycling)
                        activityFlag("Unknown", isOn: model.sample.unknown)
                    } header: {
                        Text("Flags")
                    } footer: {
                        Text("CMMotionActivityManager classifies movement using on-device motion processing.")
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
        .navigationTitle("Motion Activity")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { model.start() }
        .onDisappear { model.stop() }
    }

    private func activityFlag(_ title: String, isOn: Bool) -> some View {
        LabeledContent(title) {
            Image(systemName: isOn ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(isOn ? .teal : .secondary)
        }
    }
}

@MainActor
@Observable
final class MotionActivityLabModel {
    var sample = ActivitySample.idle
    var authorizationStatus: MotionAuthorizationStatus = .notDetermined

    private let activityManager = CMMotionActivityManager()

    var isServiceAvailable: Bool {
        CMMotionActivityManager.isActivityAvailable()
    }

    func start() {
        refreshAuthorizationStatus()
        guard authorizationStatus == .authorized else { return }
        startUpdates()
    }

    func stop() {
        activityManager.stopActivityUpdates()
    }

    func requestAuthorization() {
        activityManager.queryActivityStarting(from: .now, to: .now, to: .main) { [weak self] _, _ in
            Task { @MainActor in
                guard let self else { return }
                self.authorizationStatus = MotionAuthorizationStatus.from(CMMotionActivityManager.authorizationStatus())
                if self.authorizationStatus == .authorized {
                    self.startUpdates()
                }
            }
        }
    }

    private func refreshAuthorizationStatus() {
        authorizationStatus = MotionAuthorizationStatus.from(CMMotionActivityManager.authorizationStatus())
    }

    private func startUpdates() {
        activityManager.startActivityUpdates(to: .main) { [weak self] activity in
            guard let self, let activity else { return }
            self.sample = ActivitySample(activity)
        }
    }
}

#Preview {
    NavigationStack {
        MotionActivityLabView()
    }
}
