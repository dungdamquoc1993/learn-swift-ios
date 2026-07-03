import AVFoundation
import SwiftUI

struct AudioPlaybackLabView: View {
    @State private var model = AudioPlaybackLabModel()

    var body: some View {
        List {
            Section {
                HStack {
                    Button {
                        model.togglePlayback()
                    } label: {
                        Label(model.isPlaying ? "Pause" : "Play", systemImage: model.isPlaying ? "pause.fill" : "play.fill")
                    }
                    .buttonStyle(.borderedProminent)

                    Button {
                        model.stop()
                    } label: {
                        Label("Stop", systemImage: "stop.fill")
                    }
                    .buttonStyle(.bordered)
                }

                Slider(value: $model.volume, in: 0...1) {
                    Text("Volume")
                }
                .onChange(of: model.volume) { _, value in
                    model.setVolume(value)
                }
            } header: {
                Text("Controls")
            } footer: {
                Text("AVAudioPlayer reads demo-tone.m4a from the app bundle and sends audio to the current output route.")
            }

            Section("Playback") {
                AVMetricRow(label: "Source", value: "demo-tone.m4a")
                AVMetricRow(label: "Current", value: model.currentTimeText)
                AVMetricRow(label: "Duration", value: model.durationText)
                AVMetricRow(label: "State", value: model.stateText)
            }
        }
        .navigationTitle("Audio Playback")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { model.prepare() }
        .onDisappear { model.stop() }
    }
}

@MainActor
@Observable
final class AudioPlaybackLabModel {
    var isPlaying = false
    var volume: Float = 0.8
    var currentTimeText = "0.0 s"
    var durationText = "0.0 s"
    var stateText = "Idle"

    private var player: AVAudioPlayer?
    private var timer: Timer?

    func prepare() {
        guard player == nil else { return }

        guard let url = Bundle.main.url(forResource: "demo-tone", withExtension: "m4a", subdirectory: "AVFoundation/Resources")
            ?? Bundle.main.url(forResource: "demo-tone", withExtension: "m4a") else {
            stateText = "Missing demo-tone.m4a"
            return
        }

        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default)
            try session.setActive(true)

            let player = try AVAudioPlayer(contentsOf: url)
            player.prepareToPlay()
            player.volume = volume
            self.player = player
            durationText = String(format: "%.1f s", player.duration)
            stateText = "Ready"
        } catch {
            stateText = error.localizedDescription
        }
    }

    func togglePlayback() {
        guard let player else { return }

        if player.isPlaying {
            player.pause()
            isPlaying = false
            stateText = "Paused"
            stopTimer()
        } else {
            player.play()
            isPlaying = true
            stateText = "Playing"
            startTimer()
        }
    }

    func stop() {
        player?.stop()
        player?.currentTime = 0
        isPlaying = false
        stateText = "Stopped"
        currentTimeText = "0.0 s"
        stopTimer()
    }

    func setVolume(_ value: Float) {
        volume = value
        player?.volume = value
    }

    private func startTimer() {
        stopTimer()
        timer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self, let player = self.player else { return }
                self.currentTimeText = String(format: "%.1f s", player.currentTime)
                if !player.isPlaying {
                    self.isPlaying = false
                    self.stateText = "Finished"
                    self.stopTimer()
                }
            }
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
}

#Preview {
    NavigationStack {
        AudioPlaybackLabView()
    }
}
