import SwiftUI

struct CoreMLHubView: View {
    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(CoreMLLab.allCases) { lab in
                        NavigationLink(value: lab) {
                            CoreMLLabRow(lab: lab)
                        }
                    }
                } header: {
                    Text("On-Device ML")
                } footer: {
                    Text("These labs use Apple's built-in classifiers and recognizers. No custom .mlmodel file is bundled in the app.")
                }
            }
            .navigationTitle("Core ML")
            .navigationDestination(for: CoreMLLab.self) { lab in
                switch lab {
                case .vision:
                    VisionClassificationLabView()
                case .sound:
                    SoundClassificationLabView()
                case .speech:
                    SpeechRecognitionLabView()
                }
            }
        }
    }
}

#Preview {
    CoreMLHubView()
}
