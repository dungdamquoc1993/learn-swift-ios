import SwiftUI

struct CoreMLLabRow: View {
    let lab: CoreMLLab

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: lab.systemImage)
                .font(.title3)
                .foregroundStyle(.teal)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 4) {
                Text(lab.title)
                    .font(.headline)
                Text(lab.subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                Text(lab.frameworkName)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.teal)
            }
        }
        .padding(.vertical, 4)
    }
}

struct ClassificationRow: View {
    let result: ClassificationResult
    let rank: Int

    var body: some View {
        HStack {
            Text("\(rank).")
                .font(.subheadline.monospacedDigit())
                .foregroundStyle(.secondary)
                .frame(width: 20, alignment: .leading)

            Text(result.label)
                .font(.subheadline)
                .lineLimit(2)

            Spacer(minLength: 8)

            Text(result.confidencePercent)
                .font(.subheadline.monospacedDigit().weight(.semibold))
                .foregroundStyle(.teal)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(result.label), confidence \(result.confidencePercent)")
    }
}

struct ConfidenceBar: View {
    let confidence: Double

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(.quaternary)
                Capsule()
                    .fill(.teal)
                    .frame(width: proxy.size.width * min(max(confidence, 0), 1))
            }
        }
        .frame(height: 8)
        .accessibilityLabel("Confidence \(Int(confidence * 100)) percent")
    }
}

struct MicrophonePermissionBanner: View {
    let status: MicrophoneAuthorizationStatus
    let requestAction: () -> Void

    var body: some View {
        switch status {
        case .authorized:
            EmptyView()
        case .notDetermined:
            ContentUnavailableView {
                Label("Microphone Access", systemImage: "mic")
            } description: {
                Text("This demo needs the microphone to analyze live audio.")
            } actions: {
                Button("Request Access", action: requestAction)
                    .buttonStyle(.borderedProminent)
            }
        case .denied, .restricted:
            ContentUnavailableView {
                Label("Microphone Denied", systemImage: "hand.raised")
            } description: {
                Text("Enable microphone access in Settings to use this demo.")
            }
        }
    }
}

struct SpeechPermissionBanner: View {
    let speechStatus: SpeechAuthorizationStatus
    let microphoneStatus: MicrophoneAuthorizationStatus
    let requestAction: () -> Void

    var body: some View {
        if speechStatus == .authorized && microphoneStatus == .authorized {
            EmptyView()
        } else if speechStatus == .notDetermined || microphoneStatus == .notDetermined {
            ContentUnavailableView {
                Label("Permissions Needed", systemImage: "mic.fill.badge.plus")
            } description: {
                Text("Speech recognition needs both microphone and speech recognition permission.")
            } actions: {
                Button("Request Access", action: requestAction)
                    .buttonStyle(.borderedProminent)
            }
        } else {
            ContentUnavailableView {
                Label("Access Denied", systemImage: "hand.raised")
            } description: {
                Text("Enable microphone and speech recognition in Settings.")
            }
        }
    }
}
