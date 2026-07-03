import AVFoundation
import SoundAnalysis
import SwiftUI

struct SoundClassificationLabView: View {
    @State private var model = SoundLabModel()

    var body: some View {
        Group {
            if model.microphoneStatus == .authorized {
                List {
                    Section {
                        HStack {
                            Button {
                                model.start()
                            } label: {
                                Label("Start", systemImage: "play.fill")
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(model.isListening)

                            Button {
                                model.stop()
                            } label: {
                                Label("Stop", systemImage: "stop.fill")
                            }
                            .buttonStyle(.bordered)
                            .disabled(!model.isListening)
                        }
                    } header: {
                        Text("Controls")
                    } footer: {
                        Text("SNClassifySoundRequest classifies ambient sounds such as speech, music, laughter, and appliances.")
                    }

                    if let topResult = model.topResult {
                        Section {
                            VStack(alignment: .leading, spacing: 10) {
                                Text(topResult.label)
                                    .font(.title3.bold())
                                ConfidenceBar(confidence: topResult.confidence)
                                Text(topResult.confidencePercent)
                                    .font(.subheadline.monospacedDigit())
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.vertical, 4)
                        } header: {
                            Text("Live Classification")
                        }
                    }

                    if !model.history.isEmpty {
                        Section {
                            ForEach(model.history) { entry in
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(entry.label)
                                            .font(.subheadline.weight(.semibold))
                                        Text(entry.timestamp.formatted(date: .omitted, time: .standard))
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    Text(String(format: "%.0f%%", entry.confidence * 100))
                                        .font(.subheadline.monospacedDigit())
                                        .foregroundStyle(.teal)
                                }
                            }
                        } header: {
                            Text("Recent Labels")
                        }
                    }
                }
            } else {
                MicrophonePermissionBanner(status: model.microphoneStatus) {
                    model.requestMicrophoneAccess()
                }
            }
        }
        .navigationTitle("Sound")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { model.refreshMicrophoneStatus() }
        .onDisappear { model.stop() }
    }
}

@MainActor
@Observable
final class SoundLabModel {
    var microphoneStatus: MicrophoneAuthorizationStatus = .notDetermined
    var topResult: ClassificationResult?
    var history: [SoundHistoryEntry] = []
    var isListening = false

    private let audioEngine = AVAudioEngine()
    private var streamAnalyzer: SNAudioStreamAnalyzer?
    private var soundRequest: SNClassifySoundRequest?
    private let observer = SoundResultObserver()
    private let historyLimit = 5

    func refreshMicrophoneStatus() {
        microphoneStatus = mapMicrophoneStatus(AVAudioApplication.shared.recordPermission)
    }

    func requestMicrophoneAccess() {
        AVAudioApplication.requestRecordPermission { [weak self] granted in
            Task { @MainActor in
                self?.refreshMicrophoneStatus()
                if granted {
                    self?.start()
                }
            }
        }
    }

    func start() {
        guard microphoneStatus == .authorized, !isListening else { return }

        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playAndRecord, mode: .measurement, options: [.duckOthers, .defaultToSpeaker])
            try session.setActive(true, options: .notifyOthersOnDeactivation)

            let inputNode = audioEngine.inputNode
            let inputFormat = inputNode.outputFormat(forBus: 0)

            let request = try SNClassifySoundRequest(classifierIdentifier: .version1)
            let analyzer = SNAudioStreamAnalyzer(format: inputFormat)
            try analyzer.add(request, withObserver: observer)

            observer.onClassification = { [weak self] result in
                Task { @MainActor in
                    self?.handleClassification(result)
                }
            }

            inputNode.installTap(onBus: 0, bufferSize: 8192, format: inputFormat) { buffer, time in
                analyzer.analyze(buffer, atAudioFramePosition: time.sampleTime)
            }

            soundRequest = request
            streamAnalyzer = analyzer
            audioEngine.prepare()
            try audioEngine.start()
            isListening = true
        } catch {
            stop()
            topResult = nil
        }
    }

    func stop() {
        if audioEngine.isRunning {
            audioEngine.inputNode.removeTap(onBus: 0)
            audioEngine.stop()
        }

        streamAnalyzer = nil
        soundRequest = nil
        observer.onClassification = nil
        isListening = false

        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    private func handleClassification(_ result: SNClassificationResult) {
        guard let best = result.classifications.max(by: { $0.confidence < $1.confidence }),
              best.confidence > 0.2 else { return }

        let classification = ClassificationResult(label: best.identifier, confidence: Double(best.confidence))
        topResult = classification

        let entry = SoundHistoryEntry(
            label: classification.label,
            confidence: classification.confidence,
            timestamp: .now
        )

        if history.first?.label != entry.label {
            history.insert(entry, at: 0)
            if history.count > historyLimit {
                history.removeLast(history.count - historyLimit)
            }
        }
    }

    private func mapMicrophoneStatus(_ permission: AVAudioApplication.recordPermission) -> MicrophoneAuthorizationStatus {
        switch permission {
        case .undetermined: .notDetermined
        case .granted: .authorized
        case .denied: .denied
        @unknown default: .restricted
        }
    }
}

private final class SoundResultObserver: NSObject, SNResultsObserving {
    var onClassification: ((SNClassificationResult) -> Void)?

    func request(_ request: SNRequest, didProduce result: SNResult) {
        guard let classification = result as? SNClassificationResult else { return }
        onClassification?(classification)
    }

    func request(_ request: SNRequest, didFailWithError error: Error) {}
}

#Preview {
    NavigationStack {
        SoundClassificationLabView()
    }
}
