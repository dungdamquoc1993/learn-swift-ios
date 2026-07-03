import SwiftUI

struct AVFoundationHubView: View {
    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(AVLab.allCases.filter(\.isDemoLab)) { lab in
                        NavigationLink(value: lab) {
                            AVLabRow(lab: lab)
                        }
                    }
                } header: {
                    Text("Hardware Demos")
                } footer: {
                    Text("AVFoundation controls microphone, speaker, and camera through capture sessions and audio players.")
                }

                Section("Reference") {
                    NavigationLink(value: AVLab.reference) {
                        AVLabRow(lab: .reference)
                    }
                }
            }
            .navigationTitle("AVFoundation")
            .navigationDestination(for: AVLab.self) { lab in
                switch lab {
                case .audioSession:
                    AudioSessionLabView()
                case .audioPlayback:
                    AudioPlaybackLabView()
                case .audioRecording:
                    AudioRecordingLabView()
                case .cameraPreview:
                    CameraPreviewLabView()
                case .photoCapture:
                    PhotoCaptureLabView()
                case .videoRecording:
                    VideoRecordingLabView()
                case .reference:
                    AVReferenceView()
                }
            }
        }
    }
}

#Preview {
    AVFoundationHubView()
}
