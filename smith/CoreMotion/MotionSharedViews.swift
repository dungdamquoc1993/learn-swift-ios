import SwiftUI

struct MetricRow: View {
    let label: String
    let value: String

    var body: some View {
        LabeledContent(label, value: value)
            .font(.subheadline.monospacedDigit())
    }
}

struct Vector3MetricsView: View {
    let title: String
    let sample: Vector3Sample
    let unit: String
    var footer: String?

    var body: some View {
        Section {
            MetricRow(label: "X", value: formatted(sample.x))
            MetricRow(label: "Y", value: formatted(sample.y))
            MetricRow(label: "Z", value: formatted(sample.z))
        } header: {
            Text(title)
        } footer: {
            if let footer {
                Text(footer)
            }
        }
    }

    private func formatted(_ value: Double) -> String {
        String(format: "%.3f %@", value, unit)
    }
}

struct AttitudeMetricsView: View {
    let attitude: AttitudeSample

    var body: some View {
        Section("Attitude") {
            MetricRow(label: "Pitch", value: degrees(attitude.pitchDegrees))
            MetricRow(label: "Roll", value: degrees(attitude.rollDegrees))
            MetricRow(label: "Yaw", value: degrees(attitude.yawDegrees))
        }
    }

    private func degrees(_ value: Double) -> String {
        String(format: "%.1f°", value)
    }
}

struct AvailabilityBadge: View {
    let isAvailable: Bool

    var body: some View {
        Text(isAvailable ? "Available" : "Unavailable")
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(isAvailable ? Color.green.opacity(0.15) : Color.orange.opacity(0.15), in: Capsule())
            .foregroundStyle(isAvailable ? .green : .orange)
    }
}

struct MotionLabRow: View {
    let lab: MotionLab

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

            Spacer(minLength: 8)

            if lab.isDemoLab {
                AvailabilityBadge(isAvailable: lab.isAvailable)
            }
        }
        .padding(.vertical, 4)
    }
}

struct SpiritLevelView: View {
    let rollDegrees: Double
    let pitchDegrees: Double

    var body: some View {
        GeometryReader { proxy in
            let size = min(proxy.size.width, proxy.size.height)
            let radius = size / 2
            let maxOffset = radius * 0.35
            let bubbleX = clamp(rollDegrees / 45 * maxOffset, to: maxOffset)
            let bubbleY = clamp(pitchDegrees / 45 * maxOffset, to: maxOffset)

            ZStack {
                Circle()
                    .strokeBorder(.quaternary, lineWidth: 2)
                Circle()
                    .strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [6, 6]))
                    .padding(radius * 0.35)
                Circle()
                    .fill(.teal.opacity(0.25))
                    .frame(width: radius * 0.22, height: radius * 0.22)
                    .offset(x: bubbleX, y: bubbleY)
                Circle()
                    .fill(.teal)
                    .frame(width: radius * 0.12, height: radius * 0.12)
                    .offset(x: bubbleX, y: bubbleY)
            }
            .frame(width: size, height: size)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .aspectRatio(1, contentMode: .fit)
        .accessibilityLabel("Spirit level bubble")
        .accessibilityValue("Roll \(Int(rollDegrees)) degrees, pitch \(Int(pitchDegrees)) degrees")
    }

    private func clamp(_ value: Double, to limit: Double) -> Double {
        min(max(value, -limit), limit)
    }
}

struct MotionAuthorizationBanner: View {
    let status: MotionAuthorizationStatus
    let requestAction: () -> Void

    var body: some View {
        switch status {
        case .authorized:
            EmptyView()
        case .notDetermined:
            ContentUnavailableView {
                Label("Permission Needed", systemImage: "figure.walk.motion")
            } description: {
                Text("This demo reads motion and fitness data from the device.")
            } actions: {
                Button("Request Access", action: requestAction)
                    .buttonStyle(.borderedProminent)
            }
        case .denied, .restricted:
            ContentUnavailableView {
                Label("Access Denied", systemImage: "hand.raised")
            } description: {
                Text("Enable Motion & Fitness access in Settings to use this demo.")
            }
        case .unavailable:
            ContentUnavailableView {
                Label("Unavailable", systemImage: "exclamationmark.triangle")
            } description: {
                Text("This motion service is not available on this device.")
            }
        }
    }
}

struct LabUnavailableView: View {
    let labName: String

    var body: some View {
        ContentUnavailableView {
            Label("Unavailable", systemImage: "iphone.slash")
        } description: {
            Text("\(labName) is not supported on this device or simulator.")
        }
    }
}
