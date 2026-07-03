import AVFoundation
import Foundation

enum AVLab: String, CaseIterable, Identifiable, Hashable {
    case audioSession
    case audioPlayback
    case audioRecording
    case cameraPreview
    case photoCapture
    case videoRecording
    case reference

    var id: String { rawValue }

    var title: String {
        switch self {
        case .audioSession: "Audio Session"
        case .audioPlayback: "Audio Playback"
        case .audioRecording: "Audio Recording"
        case .cameraPreview: "Camera Preview"
        case .photoCapture: "Photo Capture"
        case .videoRecording: "Video Recording"
        case .reference: "Reference"
        }
    }

    var subtitle: String {
        switch self {
        case .audioSession: "AVAudioSession — category, mode, output route"
        case .audioPlayback: "AVAudioPlayer — play bundled audio to speaker"
        case .audioRecording: "AVAudioRecorder — record microphone to file"
        case .cameraPreview: "AVCaptureSession — live camera preview"
        case .photoCapture: "AVCapturePhotoOutput — capture still photo"
        case .videoRecording: "AVCaptureMovieFileOutput — record video clip"
        case .reference: "AirPlay, depth, editing — not covered yet"
        }
    }

    var systemImage: String {
        switch self {
        case .audioSession: "speaker.wave.2.fill"
        case .audioPlayback: "play.circle.fill"
        case .audioRecording: "mic.circle.fill"
        case .cameraPreview: "camera.viewfinder"
        case .photoCapture: "camera.fill"
        case .videoRecording: "video.fill"
        case .reference: "info.circle"
        }
    }

    var isDemoLab: Bool {
        self != .reference
    }

    var needsCamera: Bool {
        switch self {
        case .cameraPreview, .photoCapture, .videoRecording: true
        default: false
        }
    }

    var needsMicrophone: Bool {
        switch self {
        case .audioRecording, .videoRecording: true
        default: false
        }
    }
}

enum AVPermissionStatus: Equatable {
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

    static func microphone(from permission: AVAudioApplication.recordPermission) -> AVPermissionStatus {
        switch permission {
        case .undetermined: .notDetermined
        case .granted: .authorized
        case .denied: .denied
        @unknown default: .restricted
        }
    }

    static func camera(from status: AVAuthorizationStatus) -> AVPermissionStatus {
        switch status {
        case .notDetermined: .notDetermined
        case .authorized: .authorized
        case .denied: .denied
        case .restricted: .restricted
        @unknown default: .restricted
        }
    }
}

enum AudioSessionCategoryOption: String, CaseIterable, Identifiable {
    case playback
    case record
    case playAndRecord

    var id: String { rawValue }

    var title: String {
        switch self {
        case .playback: "Playback"
        case .record: "Record"
        case .playAndRecord: "Play & Record"
        }
    }

    var category: AVAudioSession.Category {
        switch self {
        case .playback: .playback
        case .record: .record
        case .playAndRecord: .playAndRecord
        }
    }
}

enum RecordingState: Equatable {
    case idle
    case recording
    case finished(url: URL, duration: TimeInterval, fileSize: Int64)
    case failed(String)
}

enum VideoRecordingState: Equatable {
    case idle
    case recording
    case finished(url: URL, duration: TimeInterval, fileSize: Int64)
    case failed(String)
}

struct AVReferenceTopic: Identifiable {
    let id: String
    let name: String
    let summary: String
}

extension AVReferenceTopic {
    static let catalog: [AVReferenceTopic] = [
        AVReferenceTopic(
            id: "airplay",
            name: "AirPlay and Streaming",
            summary: "Stream wirelessly to Apple TV and other AirPlay devices. Requires AVPlayer and route picker integration."
        ),
        AVReferenceTopic(
            id: "offline",
            name: "Offline HLS",
            summary: "Download streamed assets for offline playback using AVAssetDownloadURLSession."
        ),
        AVReferenceTopic(
            id: "depth",
            name: "Depth and Metadata Capture",
            summary: "Capture depth data and photo metadata using AVCaptureDepthDataOutput on supported hardware."
        ),
        AVReferenceTopic(
            id: "external",
            name: "External Capture Devices",
            summary: "Connect USB-C or Continuity Camera devices through AVCaptureDevice.DiscoverySession."
        ),
        AVReferenceTopic(
            id: "editing",
            name: "AVMutableComposition",
            summary: "Combine and edit audio/video tracks before export with AVAssetExportSession."
        ),
        AVReferenceTopic(
            id: "fairplay",
            name: "FairPlay DRM",
            summary: "Handle protected streaming content with content key requests and secure playback policies."
        ),
    ]
}

enum CameraCaptureMode {
    case previewOnly
    case photo
    case movie
}
