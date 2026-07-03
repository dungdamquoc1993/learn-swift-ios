import AVFoundation
import AVKit
import SwiftUI

struct VideoRecordingLabView: View {
    @State private var service = CameraCaptureService()
    @State private var cameraStatus = AVPermissionStatus.notDetermined
    @State private var microphoneStatus = AVPermissionStatus.notDetermined
    @State private var recordingState: VideoRecordingState = .idle
    @State private var player: AVPlayer?

    var body: some View {
        Group {
            if cameraStatus == .authorized && microphoneStatus == .authorized {
                List {
                    Section {
                        CameraPreviewRepresentable(session: service.session)
                            .frame(height: 240)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .listRowInsets(EdgeInsets())
                    }

                    Section {
                        HStack {
                            Button {
                                startRecording()
                            } label: {
                                Label("Record", systemImage: "record.circle")
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(service.isRecordingMovie)

                            Button {
                                stopRecording()
                            } label: {
                                Label("Stop", systemImage: "stop.fill")
                            }
                            .buttonStyle(.bordered)
                            .disabled(!service.isRecordingMovie)
                        }
                    } footer: {
                        Text("AVCaptureMovieFileOutput records video and microphone audio into a .mov file.")
                    }

                    if let player {
                        Section("Playback") {
                            VideoPlayer(player: player)
                                .frame(height: 220)
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }
                    }

                    if case .finished(let url, let duration, _) = recordingState {
                        Section("Last Clip") {
                            FileInfoView(url: url, duration: duration)
                        }
                    }

                    if case .failed(let message) = recordingState {
                        Section {
                            Label(message, systemImage: "exclamationmark.triangle")
                                .foregroundStyle(.red)
                        }
                    }
                }
            } else {
                ContentUnavailableView {
                    Label("Permissions Needed", systemImage: "video.fill")
                } description: {
                    Text("Video recording needs camera and microphone access.")
                } actions: {
                    Button("Request Access") {
                        requestPermissions()
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
        .navigationTitle("Video Recording")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            refreshPermissions()
            if cameraStatus == .authorized && microphoneStatus == .authorized {
                service.configure(mode: .movie)
                service.start()
            }
        }
        .onDisappear {
            player?.pause()
            service.stop()
        }
    }

    private func refreshPermissions() {
        cameraStatus = AVPermissionStatus.camera(from: AVCaptureDevice.authorizationStatus(for: .video))
        microphoneStatus = AVPermissionStatus.microphone(from: AVAudioApplication.shared.recordPermission)
    }

    private func requestPermissions() {
        AVCaptureDevice.requestAccess(for: .video) { _ in
            AVAudioApplication.requestRecordPermission { _ in
                Task { @MainActor in
                    refreshPermissions()
                    if cameraStatus == .authorized && microphoneStatus == .authorized {
                        service.configure(mode: .movie)
                        service.start()
                    }
                }
            }
        }
    }

    private func startRecording() {
        recordingState = .recording
        _ = service.startRecording()
    }

    private func stopRecording() {
        Task {
            if let url = await service.stopRecording() {
                let asset = AVURLAsset(url: url)
                let duration = (try? await asset.load(.duration)).map { CMTimeGetSeconds($0) } ?? 0
                let size = (try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize).map(Int64.init) ?? 0
                recordingState = .finished(url: url, duration: duration, fileSize: size)
                player = AVPlayer(url: url)
            } else {
                recordingState = .failed(service.errorMessage ?? "Recording failed.")
            }
        }
    }
}

#Preview {
    NavigationStack {
        VideoRecordingLabView()
    }
}
