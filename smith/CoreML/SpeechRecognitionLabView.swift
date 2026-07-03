import AVFoundation
import Speech
import SwiftUI

struct SpeechRecognitionLabView: View {
    @State private var model = SpeechLabModel()

    var body: some View {
        Group {
            if model.speechStatus == .authorized && model.microphoneStatus == .authorized {
                List {
                    Section {
                        Picker("Locale", selection: $model.selectedLocaleIdentifier) {
                            ForEach(model.supportedLocales, id: \.identifier) { locale in
                                Text(locale.identifier).tag(locale.identifier)
                            }
                        }
                        .disabled(model.isRecording)

                        LabeledContent("Recognition") {
                            Text(model.recognitionMode.rawValue)
                                .foregroundStyle(.teal)
                        }

                        HStack {
                            Button {
                                model.startRecording()
                            } label: {
                                Label("Start", systemImage: "mic.fill")
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(model.isRecording || !model.isRecognizerAvailable)

                            Button {
                                model.stopRecording()
                            } label: {
                                Label("Stop", systemImage: "stop.fill")
                            }
                            .buttonStyle(.bordered)
                            .disabled(!model.isRecording)
                        }
                    } header: {
                        Text("Controls")
                    } footer: {
                        Text("SFSpeechRecognizer streams partial text while you speak, then commits a final transcript.")
                    }

                    Section {
                        if model.finalTranscript.isEmpty && model.partialTranscript.isEmpty {
                            Text("Tap Start and speak.")
                                .foregroundStyle(.secondary)
                        } else {
                            if !model.finalTranscript.isEmpty {
                                Text(model.finalTranscript)
                            }
                            if !model.partialTranscript.isEmpty {
                                Text(model.partialTranscript)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    } header: {
                        Text("Transcript")
                    }

                    if let errorMessage = model.errorMessage {
                        Section {
                            Label(errorMessage, systemImage: "exclamationmark.triangle")
                                .foregroundStyle(.red)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
            } else {
                SpeechPermissionBanner(
                    speechStatus: model.speechStatus,
                    microphoneStatus: model.microphoneStatus,
                    requestAction: { model.requestPermissions() }
                )
            }
        }
        .navigationTitle("Speech")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { model.refreshStatuses() }
        .onDisappear { model.stopRecording() }
        .onChange(of: model.selectedLocaleIdentifier) { _, _ in
            model.updateRecognizer()
        }
    }
}

@MainActor
@Observable
final class SpeechLabModel {
    var speechStatus: SpeechAuthorizationStatus = .notDetermined
    var microphoneStatus: MicrophoneAuthorizationStatus = .notDetermined
    var selectedLocaleIdentifier: String = Locale.current.identifier
    var recognitionMode: SpeechRecognitionMode = .server
    var finalTranscript = ""
    var partialTranscript = ""
    var errorMessage: String?
    var isRecording = false
    var isRecognizerAvailable = false

    let supportedLocales = SFSpeechRecognizer.supportedLocales().sorted {
        $0.identifier < $1.identifier
    }

    private let audioEngine = AVAudioEngine()
    private var speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?

    init() {
        updateRecognizer()
    }

    func refreshStatuses() {
        speechStatus = mapSpeechStatus(SFSpeechRecognizer.authorizationStatus())
        microphoneStatus = mapMicrophoneStatus(AVAudioApplication.shared.recordPermission)
        updateRecognizer()
    }

    func requestPermissions() {
        SFSpeechRecognizer.requestAuthorization { [weak self] status in
            Task { @MainActor in
                guard let self else { return }
                self.speechStatus = self.mapSpeechStatus(status)
                self.requestMicrophoneIfNeeded()
            }
        }
    }

    func updateRecognizer() {
        speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: selectedLocaleIdentifier))
        isRecognizerAvailable = speechRecognizer?.isAvailable ?? false
        recognitionMode = (speechRecognizer?.supportsOnDeviceRecognition == true) ? .onDevice : .server
    }

    func startRecording() {
        guard !isRecording else { return }
        guard let speechRecognizer, speechRecognizer.isAvailable else {
            errorMessage = "Speech recognizer is not available for \(selectedLocaleIdentifier)."
            return
        }

        stopRecording()
        errorMessage = nil
        partialTranscript = ""

        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.record, mode: .measurement, options: .duckOthers)
            try session.setActive(true, options: .notifyOthersOnDeactivation)

            let request = SFSpeechAudioBufferRecognitionRequest()
            request.shouldReportPartialResults = true
            if speechRecognizer.supportsOnDeviceRecognition {
                request.requiresOnDeviceRecognition = true
                recognitionMode = .onDevice
            } else {
                recognitionMode = .server
            }

            let inputNode = audioEngine.inputNode
            recognitionTask = speechRecognizer.recognitionTask(with: request) { [weak self] result, error in
                Task { @MainActor in
                    guard let self else { return }

                    if let result {
                        if result.isFinal {
                            self.finalTranscript = result.bestTranscription.formattedString
                            self.partialTranscript = ""
                        } else {
                            self.partialTranscript = result.bestTranscription.formattedString
                        }
                    }

                    if let error {
                        self.errorMessage = error.localizedDescription
                        self.stopRecording()
                    }
                }
            }

            let recordingFormat = inputNode.outputFormat(forBus: 0)
            inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
                request.append(buffer)
            }

            recognitionRequest = request
            audioEngine.prepare()
            try audioEngine.start()
            isRecording = true
        } catch {
            errorMessage = error.localizedDescription
            stopRecording()
        }
    }

    func stopRecording() {
        if audioEngine.isRunning {
            audioEngine.inputNode.removeTap(onBus: 0)
            audioEngine.stop()
        }

        recognitionRequest?.endAudio()
        recognitionTask?.cancel()

        recognitionRequest = nil
        recognitionTask = nil
        isRecording = false

        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    private func requestMicrophoneIfNeeded() {
        guard microphoneStatus == .notDetermined else { return }

        AVAudioApplication.requestRecordPermission { [weak self] _ in
            Task { @MainActor in
                self?.refreshStatuses()
            }
        }
    }

    private func mapSpeechStatus(_ status: SFSpeechRecognizerAuthorizationStatus) -> SpeechAuthorizationStatus {
        switch status {
        case .notDetermined: .notDetermined
        case .authorized: .authorized
        case .denied: .denied
        case .restricted: .restricted
        @unknown default: .restricted
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

#Preview {
    NavigationStack {
        SpeechRecognitionLabView()
    }
}
