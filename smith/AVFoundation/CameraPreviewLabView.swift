import AVFoundation
import SwiftUI

struct CameraPreviewLabView: View {
    @State private var service = CameraCaptureService()
    @State private var cameraStatus = AVPermissionStatus.notDetermined

    var body: some View {
        Group {
            if cameraStatus == .authorized {
                List {
                    Section {
                        CameraPreviewRepresentable(session: service.session)
                            .frame(height: 320)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .listRowInsets(EdgeInsets())
                    } footer: {
                        Text("AVCaptureVideoPreviewLayer shows the live camera feed from AVCaptureSession.")
                    }

                    Section("Camera") {
                        Button("Switch Camera") {
                            service.switchCamera()
                        }

                        AVMetricRow(label: "Position", value: service.cameraPosition == .back ? "Back" : "Front")
                        AVMetricRow(label: "Torch Available", value: service.isTorchAvailable ? "Yes" : "No")
                        AVMetricRow(label: "Session", value: service.isRunning ? "Running" : "Stopped")
                    }

                    if let errorMessage = service.errorMessage {
                        Section {
                            Label(errorMessage, systemImage: "exclamationmark.triangle")
                                .foregroundStyle(.red)
                        }
                    }
                }
            } else {
                AVPermissionBanner(
                    title: "Camera Access",
                    message: "This demo shows a live camera preview.",
                    status: cameraStatus,
                    requestAction: { requestCameraAccess() }
                )
            }
        }
        .navigationTitle("Camera Preview")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            refreshCameraStatus()
            if cameraStatus == .authorized {
                service.configure(mode: .previewOnly)
                service.start()
            }
        }
        .onDisappear {
            service.stop()
        }
    }

    private func refreshCameraStatus() {
        cameraStatus = AVPermissionStatus.camera(from: AVCaptureDevice.authorizationStatus(for: .video))
    }

    private func requestCameraAccess() {
        AVCaptureDevice.requestAccess(for: .video) { _ in
            Task { @MainActor in
                refreshCameraStatus()
                if cameraStatus == .authorized {
                    service.configure(mode: .previewOnly)
                    service.start()
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        CameraPreviewLabView()
    }
}
