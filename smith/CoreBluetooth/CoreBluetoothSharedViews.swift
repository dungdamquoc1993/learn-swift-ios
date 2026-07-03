import CoreBluetooth
import SwiftUI

struct BLELabRow: View {
    let lab: BLELab

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

struct BLEStateBadge: View {
    let state: CBManagerState

    var body: some View {
        Text(label)
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.15), in: Capsule())
            .foregroundStyle(color)
    }

    private var label: String {
        switch state {
        case .unknown: "Unknown"
        case .resetting: "Resetting"
        case .unsupported: "Unsupported"
        case .unauthorized: "Unauthorized"
        case .poweredOff: "Powered Off"
        case .poweredOn: "Powered On"
        @unknown default: "Unknown"
        }
    }

    private var color: Color {
        state == .poweredOn ? .green : .orange
    }
}

struct BLEMetricRow: View {
    let label: String
    let value: String

    var body: some View {
        LabeledContent(label, value: value)
            .font(.subheadline)
    }
}

struct BLEPoweredOffView: View {
    let state: CBManagerState

    var body: some View {
        ContentUnavailableView {
            Label(title, systemImage: "bolt.slash")
        } description: {
            Text(message)
        }
    }

    private var title: String {
        switch state {
        case .unauthorized: "Bluetooth Unauthorized"
        case .poweredOff: "Bluetooth Off"
        case .unsupported: "Bluetooth Unsupported"
        default: "Bluetooth Unavailable"
        }
    }

    private var message: String {
        switch state {
        case .unauthorized:
            "Enable Bluetooth permission for StudySmith in Settings."
        case .poweredOff:
            "Turn on Bluetooth in Control Center or Settings."
        case .unsupported:
            "This device does not support Bluetooth Low Energy."
        default:
            "Wait until Core Bluetooth finishes initializing."
        }
    }
}
