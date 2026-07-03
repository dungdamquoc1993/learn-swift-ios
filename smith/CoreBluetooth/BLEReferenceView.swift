import SwiftUI

struct BLEReferenceView: View {
    var body: some View {
        List {
            Section {
                ForEach(BLEReferenceTopic.catalog) { topic in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(topic.title)
                            .font(.headline)
                        Text(topic.summary)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.vertical, 4)
                }
            } header: {
                Text("How To Use This Module")
            } footer: {
                Text("StudySmith publishes a custom service UUID so you can test central and peripheral roles without extra hardware.")
            }
        }
        .navigationTitle("Reference")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        BLEReferenceView()
    }
}
