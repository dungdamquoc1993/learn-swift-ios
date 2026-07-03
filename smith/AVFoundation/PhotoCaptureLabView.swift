import AVFoundation
import SwiftUI

struct PhotoCaptureLabView: View {
    @State private var service = CameraCaptureService()
    @State private var cameraStatus = AVPermissionStatus.notDetermined
    @State private var isCapturing = false

    var body: some View {
        Group {
            if cameraStatus == .authorized {
                List {
                    Section {
                        CameraPreviewRepresentable(session: service.session)
                            .frame(height: 280)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .listRowInsets(EdgeInsets())
                    }

                    Section {
                        Button {
                            capturePhoto()
                        } label: {
                            Label(isCapturing ? "Capturing..." : "Capture Photo", systemImage: "camera.shutter.button")
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(isCapturing)
                    }

                    if let photo = service.lastPhoto {
                        Section("Last Photo") {
                            Image(uiImage: photo)
                                .resizable()
                                .scaledToFit()
                                .frame(maxHeight: 240)
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                            AVMetricRow(
                                label: "Size",
                                value: "\(Int(photo.size.width)) x \(Int(photo.size.height)) px"
                            )
                        }
                    }
                }
            } else {
                AVPermissionBanner(
                    title: "Camera Access",
                    message: "This demo captures still photos from the camera.",
                    status: cameraStatus,
                    requestAction: { requestCameraAccess() }
                )
            }
        }
        .navigationTitle("Photo Capture")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            refreshCameraStatus()
            if cameraStatus == .authorized {
                service.configure(mode: .photo)
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
                    service.configure(mode: .photo)
                    service.start()
                }
            }
        }
    }

    private func capturePhoto() {
        isCapturing = true
        Task {
            _ = await service.capturePhoto()
            isCapturing = false
        }
    }
}

#Preview {
    NavigationStack {
        PhotoCaptureLabView()
    }
}
