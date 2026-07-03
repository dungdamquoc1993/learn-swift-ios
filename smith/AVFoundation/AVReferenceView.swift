import SwiftUI

struct AVReferenceView: View {
    var body: some View {
        List {
            Section {
                ForEach(AVReferenceTopic.catalog) { topic in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(topic.name)
                            .font(.headline)
                        Text(topic.summary)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.vertical, 4)
                }
            } header: {
                Text("Not Covered In This App")
            } footer: {
                Text("These AVFoundation areas need extra hardware, DRM, or editing pipelines beyond the current hardware labs.")
            }
        }
        .navigationTitle("Reference")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        AVReferenceView()
    }
}
