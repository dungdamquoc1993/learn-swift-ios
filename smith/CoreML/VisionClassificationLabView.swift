import PhotosUI
import SwiftUI
import Vision

struct VisionClassificationLabView: View {
    @State private var model = VisionLabModel()
    @State private var selectedItem: PhotosPickerItem?

    var body: some View {
        List {
            Section {
                PhotosPicker(selection: $selectedItem, matching: .images, photoLibrary: .shared()) {
                    Label(model.previewImage == nil ? "Choose Photo" : "Change Photo", systemImage: "photo.on.rectangle")
                }

                if let previewImage = model.previewImage {
                    previewImage
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 240)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
                }

                Button {
                    Task { await model.classifyCurrentImage() }
                } label: {
                    Label("Classify Image", systemImage: "sparkles")
                }
                .buttonStyle(.borderedProminent)
                .disabled(model.previewImage == nil || model.state == .loading)
            } header: {
                Text("Input")
            } footer: {
                Text("VNClassifyImageRequest runs Apple's built-in image classifier through the Vision framework.")
            }

            stateSection
        }
        .navigationTitle("Vision")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: selectedItem) { _, newItem in
            Task { await model.loadPhoto(from: newItem) }
        }
    }

    @ViewBuilder
    private var stateSection: some View {
        switch model.state {
        case .idle:
            Section {
                ContentUnavailableView(
                    "No classification yet",
                    systemImage: "photo",
                    description: Text("Choose a photo, then tap Classify Image.")
                )
            } header: {
                Text("Results")
            }

        case .loading:
            Section {
                HStack {
                    ProgressView()
                    Text("Analyzing image...")
                }
            } header: {
                Text("Results")
            }

        case .success(let results):
            Section {
                ForEach(Array(results.enumerated()), id: \.element.id) { index, result in
                    VStack(alignment: .leading, spacing: 8) {
                        ClassificationRow(result: result, rank: index + 1)
                        ConfidenceBar(confidence: result.confidence)
                    }
                    .padding(.vertical, 4)
                }
            } header: {
                Text("Top Classifications")
            } footer: {
                Text("Vision returns VNClassificationObservation values sorted by confidence.")
            }

        case .failed(let message):
            Section {
                Label(message, systemImage: "exclamationmark.triangle")
                    .foregroundStyle(.red)
                    .fixedSize(horizontal: false, vertical: true)
            } header: {
                Text("Results")
            }
        }
    }
}

@MainActor
@Observable
final class VisionLabModel {
    var previewImage: Image?
    var state: VisionLabState = .idle

    private var cgImage: CGImage?

    func loadPhoto(from item: PhotosPickerItem?) async {
        guard let item else { return }

        state = .idle

        guard let data = try? await item.loadTransferable(type: Data.self),
              let uiImage = UIImage(data: data),
              let cgImage = uiImage.cgImage else {
            state = .failed("Could not load the selected photo.")
            previewImage = nil
            self.cgImage = nil
            return
        }

        self.cgImage = cgImage
        previewImage = Image(uiImage: uiImage)
        await classifyCurrentImage()
    }

    func classifyCurrentImage() async {
        guard let cgImage else {
            state = .failed("Choose a photo before classifying.")
            return
        }

        state = .loading

        let request = VNClassifyImageRequest()
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])

        do {
            try handler.perform([request])
            guard let observations = request.results as? [VNClassificationObservation] else {
                state = .failed("Vision did not return classification observations.")
                return
            }

            let results = observations
                .filter { $0.confidence > 0.01 }
                .sorted { $0.confidence > $1.confidence }
                .prefix(5)
                .map { ClassificationResult(label: $0.identifier, confidence: Double($0.confidence)) }

            if results.isEmpty {
                state = .failed("No confident classifications were found for this image.")
            } else {
                state = .success(Array(results))
            }
        } catch {
            state = .failed(error.localizedDescription)
        }
    }
}

#Preview {
    NavigationStack {
        VisionClassificationLabView()
    }
}
