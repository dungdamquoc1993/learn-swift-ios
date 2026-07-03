import SwiftUI

struct MotionUnsupportedAPIsView: View {
    var body: some View {
        List {
            Section {
                ForEach(UnsupportedMotionAPI.catalog) { api in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(api.name)
                            .font(.headline)
                        Text(api.platform)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.teal)
                        Text(api.summary)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.vertical, 4)
                }
            } header: {
                Text("Not Covered In This App")
            } footer: {
                Text("These Core Motion APIs need special hardware or platforms. This iPhone lab focuses on sensors available on a typical phone.")
            }
        }
        .navigationTitle("Unsupported APIs")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        MotionUnsupportedAPIsView()
    }
}
