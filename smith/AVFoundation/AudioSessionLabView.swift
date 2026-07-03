import AVFoundation
import SwiftUI

struct AudioSessionLabView: View {
    @State private var model = AudioSessionLabModel()

    var body: some View {
        List {
            Section {
                Picker("Category", selection: $model.selectedCategory) {
                    ForEach(AudioSessionCategoryOption.allCases) { option in
                        Text(option.title).tag(option)
                    }
                }
                .onChange(of: model.selectedCategory) { _, newValue in
                    model.applyCategory(newValue)
                }

                Toggle("Override To Speaker", isOn: $model.speakerOverride)
                    .onChange(of: model.speakerOverride) { _, enabled in
                        model.setSpeakerOverride(enabled)
                    }
            } header: {
                Text("Configuration")
            } footer: {
                Text("AVAudioSession decides how your app shares the microphone and speaker with other apps.")
            }

            Section("Current Session") {
                AVMetricRow(label: "Category", value: model.categoryDescription)
                AVMetricRow(label: "Mode", value: model.modeDescription)
                AVMetricRow(label: "Output", value: model.outputRouteDescription)
                AVMetricRow(label: "Input", value: model.inputRouteDescription)
            }
        }
        .navigationTitle("Audio Session")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { model.refresh() }
    }
}

@MainActor
@Observable
final class AudioSessionLabModel {
    var selectedCategory: AudioSessionCategoryOption = .playback
    var speakerOverride = false
    var categoryDescription = ""
    var modeDescription = ""
    var outputRouteDescription = ""
    var inputRouteDescription = ""

    func refresh() {
        let session = AVAudioSession.sharedInstance()
        categoryDescription = session.category.rawValue
        modeDescription = session.mode.rawValue
        outputRouteDescription = session.currentRoute.outputs.map(\.portName).joined(separator: ", ")
        inputRouteDescription = {
            let routes = session.currentRoute.inputs.map(\.portName).joined(separator: ", ")
            return routes.isEmpty ? "None" : routes
        }()

        if session.category == .playback {
            selectedCategory = .playback
        } else if session.category == .record {
            selectedCategory = .record
        } else if session.category == .playAndRecord {
            selectedCategory = .playAndRecord
        }
    }

    func applyCategory(_ option: AudioSessionCategoryOption) {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(option.category, mode: .default, options: [.defaultToSpeaker, .allowBluetooth])
            try session.setActive(true)
            refresh()
        } catch {
            refresh()
        }
    }

    func setSpeakerOverride(_ enabled: Bool) {
        do {
            try AVAudioSession.sharedInstance().overrideOutputAudioPort(enabled ? .speaker : .none)
            refresh()
        } catch {
            refresh()
        }
    }
}

#Preview {
    NavigationStack {
        AudioSessionLabView()
    }
}
