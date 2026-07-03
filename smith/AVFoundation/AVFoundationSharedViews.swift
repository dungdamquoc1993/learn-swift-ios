import AVFoundation
import SwiftUI

struct AVLabRow: View {
    let lab: AVLab

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: lab.systemImage)
                .font(.title3)
                .foregroundStyle(lab.isDemoLab ? .teal : .secondary)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 4) {
                Text(lab.title)
                    .font(.headline)
                Text(lab.subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.vertical, 4)
    }
}

struct AVPermissionBanner: View {
    let title: String
    let message: String
    let status: AVPermissionStatus
    let requestAction: () -> Void

    var body: some View {
        switch status {
        case .authorized:
            EmptyView()
        case .notDetermined:
            ContentUnavailableView {
                Label(title, systemImage: "lock.open")
            } description: {
                Text(message)
            } actions: {
                Button("Request Access", action: requestAction)
                    .buttonStyle(.borderedProminent)
            }
        case .denied, .restricted:
            ContentUnavailableView {
                Label("\(title) Denied", systemImage: "hand.raised")
            } description: {
                Text("Enable access in Settings to use this demo.")
            }
        }
    }
}

struct CameraPreviewRepresentable: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> PreviewView {
        let view = PreviewView()
        view.previewLayer.session = session
        view.previewLayer.videoGravity = .resizeAspectFill
        return view
    }

    func updateUIView(_ uiView: PreviewView, context: Context) {
        uiView.previewLayer.session = session
    }
}

final class PreviewView: UIView {
    override class var layerClass: AnyClass {
        AVCaptureVideoPreviewLayer.self
    }

    var previewLayer: AVCaptureVideoPreviewLayer {
        layer as! AVCaptureVideoPreviewLayer
    }
}

struct AVMetricRow: View {
    let label: String
    let value: String

    var body: some View {
        LabeledContent(label, value: value)
            .font(.subheadline)
    }
}

struct FileInfoView: View {
    let url: URL
    let duration: TimeInterval?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            AVMetricRow(label: "File", value: url.lastPathComponent)
            if let duration {
                AVMetricRow(label: "Duration", value: String(format: "%.1f s", duration))
            }
            if let size = try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize {
                AVMetricRow(label: "Size", value: ByteCountFormatter.string(fromByteCount: Int64(size), countStyle: .file))
            }
        }
    }
}
