import AVFoundation
import UIKit

@MainActor
@Observable
final class CameraCaptureService: NSObject {
    let session = AVCaptureSession()

    var isRunning = false
    var isRecordingMovie = false
    var errorMessage: String?
    var lastPhoto: UIImage?
    var lastVideoURL: URL?
    var cameraPosition: AVCaptureDevice.Position = .back
    var videoDimensionsText = ""
    var isTorchAvailable = false

    private let sessionQueue = DispatchQueue(label: "avfoundation.camera.session")
    private var photoOutput: AVCapturePhotoOutput?
    private var movieOutput: AVCaptureMovieFileOutput?
    private var currentMode: CameraCaptureMode = .previewOnly
    private var photoContinuation: CheckedContinuation<UIImage?, Never>?
    private var movieContinuation: CheckedContinuation<URL?, Never>?

    func configure(mode: CameraCaptureMode, position: AVCaptureDevice.Position = .back) {
        currentMode = mode
        cameraPosition = position
        sessionQueue.async { [weak self] in
            self?.reconfigureSession()
        }
    }

    func start() {
        sessionQueue.async { [weak self] in
            guard let self, !self.session.isRunning else { return }
            self.session.startRunning()
            Task { @MainActor in
                self.isRunning = self.session.isRunning
            }
        }
    }

    func stop() {
        sessionQueue.async { [weak self] in
            guard let self else { return }
            if self.movieOutput?.isRecording == true {
                self.movieOutput?.stopRecording()
            }
            if self.session.isRunning {
                self.session.stopRunning()
            }
            Task { @MainActor in
                self.isRunning = false
                self.isRecordingMovie = false
            }
        }
    }

    func switchCamera() {
        cameraPosition = cameraPosition == .back ? .front : .back
        sessionQueue.async { [weak self] in
            self?.reconfigureSession()
        }
    }

    func capturePhoto() async -> UIImage? {
        await withCheckedContinuation { continuation in
            photoContinuation = continuation
            sessionQueue.async { [weak self] in
                guard let self, let photoOutput = self.photoOutput else {
                    Task { @MainActor in
                        self?.photoContinuation?.resume(returning: nil)
                        self?.photoContinuation = nil
                    }
                    return
                }
                let settings = AVCapturePhotoSettings()
                photoOutput.capturePhoto(with: settings, delegate: self)
            }
        }
    }

    func startRecording() -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("avlab-clip-\(UUID().uuidString).mov")
        lastVideoURL = url

        sessionQueue.async { [weak self] in
            guard let self, let movieOutput = self.movieOutput else { return }
            movieOutput.startRecording(to: url, recordingDelegate: self)
            Task { @MainActor in
                self.isRecordingMovie = true
            }
        }
        return url
    }

    func stopRecording() async -> URL? {
        await withCheckedContinuation { continuation in
            movieContinuation = continuation
            sessionQueue.async { [weak self] in
                guard let self, let movieOutput = self.movieOutput, movieOutput.isRecording else {
                    Task { @MainActor in
                        self?.movieContinuation?.resume(returning: nil)
                        self?.movieContinuation = nil
                    }
                    return
                }
                movieOutput.stopRecording()
            }
        }
    }

    private func reconfigureSession() {
        session.beginConfiguration()
        session.sessionPreset = currentMode == .movie ? .high : .photo

        for input in session.inputs {
            session.removeInput(input)
        }
        for output in session.outputs {
            session.removeOutput(output)
        }

        photoOutput = nil
        movieOutput = nil

        guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: cameraPosition),
              let videoInput = try? AVCaptureDeviceInput(device: videoDevice),
              session.canAddInput(videoInput) else {
            session.commitConfiguration()
            Task { @MainActor in
                self.errorMessage = "Could not access the camera."
            }
            return
        }

        session.addInput(videoInput)

        if currentMode == .movie,
           let audioDevice = AVCaptureDevice.default(for: .audio),
           let audioInput = try? AVCaptureDeviceInput(device: audioDevice),
           session.canAddInput(audioInput) {
            session.addInput(audioInput)
        }

        if currentMode == .photo {
            let output = AVCapturePhotoOutput()
            if session.canAddOutput(output) {
                session.addOutput(output)
                photoOutput = output
            }
        }

        if currentMode == .movie {
            let output = AVCaptureMovieFileOutput()
            if session.canAddOutput(output) {
                session.addOutput(output)
                movieOutput = output
            }
        }

        session.commitConfiguration()

        let dimensions = videoDevice.activeFormat.formatDescription.dimensions
        Task { @MainActor in
            self.errorMessage = nil
            self.videoDimensionsText = "\(dimensions.width) x \(dimensions.height)"
            self.isTorchAvailable = videoDevice.hasTorch
        }
    }
}

extension CameraCaptureService: AVCapturePhotoCaptureDelegate {
    nonisolated func photoOutput(
        _ output: AVCapturePhotoOutput,
        didFinishProcessingPhoto photo: AVCapturePhoto,
        error: Error?
    ) {
        let image = photo.fileDataRepresentation().flatMap(UIImage.init(data:))
        Task { @MainActor in
            if let image {
                self.lastPhoto = image
            } else if let error {
                self.errorMessage = error.localizedDescription
            }
            self.photoContinuation?.resume(returning: image)
            self.photoContinuation = nil
        }
    }
}

extension CameraCaptureService: AVCaptureFileOutputRecordingDelegate {
    nonisolated func fileOutput(
        _ output: AVCaptureFileOutput,
        didFinishRecordingTo outputFileURL: URL,
        from connections: [AVCaptureConnection],
        error: Error?
    ) {
        Task { @MainActor in
            self.isRecordingMovie = false
            if let error {
                self.errorMessage = error.localizedDescription
                self.movieContinuation?.resume(returning: nil)
            } else {
                self.lastVideoURL = outputFileURL
                self.movieContinuation?.resume(returning: outputFileURL)
            }
            self.movieContinuation = nil
        }
    }
}
