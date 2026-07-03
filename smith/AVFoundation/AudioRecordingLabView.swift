import AVFoundation
import SwiftUI

struct AudioRecordingLabView: View {
    @State private var model = AudioRecordingLabModel()

    var body: some View {
        Group {
            if model.microphoneStatus == .authorized {
                List {
                    Section {
                        HStack {
                            Button {
                                model.startRecording()
                            } label: {
                                Label("Record", systemImage: "mic.fill")
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(model.isRecording)

                            Button {
                                model.stopRecording()
                            } label: {
                                Label("Stop", systemImage: "stop.fill")
                            }
                            .buttonStyle(.bordered)
                            .disabled(!model.isRecording)
                        }
                    } header: {
                        Text("Controls")
                    } footer: {
                        Text("AVAudioRecorder writes microphone audio to an .m4a file, then AVAudioPlayer plays it back.")
                    }

                    Section("State") {
                        AVMetricRow(label: "Status", value: model.statusText)
                    }

                    if case .finished(let url, let duration, _) = model.recordingState {
                        Section("Recording") {
                            FileInfoView(url: url, duration: duration)
                            Button {
                                model.playRecording()
                            } label: {
                                Label(model.isPlayingBack ? "Stop Playback" : "Play Recording", systemImage: "play.circle")
                            }
                        }
                    }

                    if case .failed(let message) = model.recordingState {
                        Section {
                            Label(message, systemImage: "exclamationmark.triangle")
                                .foregroundStyle(.red)
                        }
                    }
                }
            } else {
                AVPermissionBanner(
                    title: "Microphone Access",
                    message: "This demo records audio from the microphone.",
                    status: model.microphoneStatus,
                    requestAction: { model.requestMicrophoneAccess() }
                )
            }
        }
        .navigationTitle("Audio Recording")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { model.refreshMicrophoneStatus() }
        .onDisappear { model.cleanup() }
    }
}

@MainActor
@Observable
final class AudioRecordingLabModel {
    var microphoneStatus: AVPermissionStatus = .notDetermined
    var recordingState: RecordingState = .idle
    var isRecording = false
    var isPlayingBack = false
    var statusText = "Idle"

    private var recorder: AVAudioRecorder?
    private var playbackPlayer: AVAudioPlayer?
    private var recordingURL: URL?

    func refreshMicrophoneStatus() {
        microphoneStatus = AVPermissionStatus.microphone(from: AVAudioApplication.shared.recordPermission)
    }

    func requestMicrophoneAccess() {
        AVAudioApplication.requestRecordPermission { [weak self] _ in
            Task { @MainActor in
                self?.refreshMicrophoneStatus()
            }
        }
    }

    func startRecording() {
        guard microphoneStatus == .authorized else { return }

        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
            try session.setActive(true)

            let url = FileManager.default.temporaryDirectory.appendingPathComponent("avlab-recording.m4a")
            recordingURL = url

            let settings: [String: Any] = [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: 44_100,
                AVNumberOfChannelsKey: 1,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue,
            ]

            let recorder = try AVAudioRecorder(url: url, settings: settings)
            recorder.prepareToRecord()
            recorder.record()

            self.recorder = recorder
            isRecording = true
            recordingState = .idle
            statusText = "Recording..."
        } catch {
            recordingState = .failed(error.localizedDescription)
            statusText = "Failed"
        }
    }

    func stopRecording() {
        guard let recorder, let url = recordingURL else { return }

        recorder.stop()
        isRecording = false
        self.recorder = nil

        let duration = recorder.currentTime
        let size = (try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize).map(Int64.init) ?? 0
        recordingState = .finished(url: url, duration: duration, fileSize: size)
        statusText = "Recorded"
    }

    func playRecording() {
        guard case .finished(let url, _, _) = recordingState else { return }

        if isPlayingBack {
            playbackPlayer?.stop()
            isPlayingBack = false
            return
        }

        do {
            playbackPlayer = try AVAudioPlayer(contentsOf: url)
            playbackPlayer?.play()
            isPlayingBack = true
        } catch {
            recordingState = .failed(error.localizedDescription)
        }
    }

    func cleanup() {
        recorder?.stop()
        playbackPlayer?.stop()
        isRecording = false
        isPlayingBack = false
    }
}

#Preview {
    NavigationStack {
        AudioRecordingLabView()
    }
}
