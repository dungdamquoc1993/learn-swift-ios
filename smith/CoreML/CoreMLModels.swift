import Foundation

enum CoreMLLab: String, CaseIterable, Identifiable, Hashable {
    case vision
    case sound
    case speech

    var id: String { rawValue }

    var title: String {
        switch self {
        case .vision: "Vision"
        case .sound: "Sound"
        case .speech: "Speech"
        }
    }

    var subtitle: String {
        switch self {
        case .vision: "VNClassifyImageRequest — built-in image classifier"
        case .sound: "SNClassifySoundRequest — ambient sound classifier"
        case .speech: "SFSpeechRecognizer — speech-to-text"
        }
    }

    var systemImage: String {
        switch self {
        case .vision: "photo.on.rectangle.angled"
        case .sound: "waveform"
        case .speech: "mic.fill"
        }
    }

    var frameworkName: String {
        switch self {
        case .vision: "Vision"
        case .sound: "SoundAnalysis"
        case .speech: "Speech"
        }
    }
}

struct ClassificationResult: Identifiable, Equatable {
    let id: String
    let label: String
    let confidence: Double

    init(label: String, confidence: Double) {
        self.id = label
        self.label = label
        self.confidence = confidence
    }

    var confidencePercent: String {
        String(format: "%.1f%%", confidence * 100)
    }
}

enum VisionLabState: Equatable {
    case idle
    case loading
    case success([ClassificationResult])
    case failed(String)
}

enum MicrophoneAuthorizationStatus: Equatable {
    case notDetermined
    case authorized
    case denied
    case restricted

    var title: String {
        switch self {
        case .notDetermined: "Not Determined"
        case .authorized: "Authorized"
        case .denied: "Denied"
        case .restricted: "Restricted"
        }
    }
}

enum SpeechAuthorizationStatus: Equatable {
    case notDetermined
    case authorized
    case denied
    case restricted

    var title: String {
        switch self {
        case .notDetermined: "Not Determined"
        case .authorized: "Authorized"
        case .denied: "Denied"
        case .restricted: "Restricted"
        }
    }
}

struct SoundHistoryEntry: Identifiable, Equatable {
    let id = UUID()
    let label: String
    let confidence: Double
    let timestamp: Date
}

enum SpeechRecognitionMode: String, CaseIterable, Identifiable {
    case onDevice = "On-Device"
    case server = "Server"

    var id: String { rawValue }
}
