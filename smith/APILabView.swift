import SwiftUI

struct APILabView: View {
    @State private var model = APILabModel()

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Stepper(value: $model.userID, in: 1...10) {
                        LabeledContent("User ID", value: "\(model.userID)")
                    }

                    ViewThatFits(in: .horizontal) {
                        actionButtons
                        actionButtons
                            .labelStyle(.iconOnly)
                    }
                } header: {
                    Text("Input")
                } footer: {
                    Text("This calls JSONPlaceholder with a query param, decodes JSON into Swift structs, then stores the response in memory by user ID.")
                }

                stateSection

                if !model.cachedUserIDs.isEmpty {
                    Section("Memory Cache") {
                        LabeledContent("Cached users", value: model.cachedUserIDs.map(String.init).joined(separator: ", "))
                    }
                }
            }
            .navigationTitle("API Lab")
            .listStyle(.insetGrouped)
            .task {
                await model.loadPosts()
            }
        }
    }

    private var actionButtons: some View {
        HStack {
            Button {
                Task { await model.loadPosts() }
            } label: {
                Label("Load", systemImage: "arrow.down.circle")
            }
            .buttonStyle(.borderedProminent)
            .disabled(model.isLoading)

            Button {
                Task { await model.loadPosts(forceRefresh: true) }
            } label: {
                Label("Reload", systemImage: "arrow.clockwise")
            }
            .buttonStyle(.bordered)
            .disabled(model.isLoading)

            Button(role: .destructive) {
                model.clearCache()
            } label: {
                Label("Cache", systemImage: "trash")
            }
            .buttonStyle(.bordered)
            .disabled(model.isLoading || model.cachedUserIDs.isEmpty)
            .accessibilityLabel("Clear memory cache")
        }
    }

    @ViewBuilder
    private var stateSection: some View {
        switch model.state {
        case .idle:
            Section("State") {
                ContentUnavailableView(
                    "No request yet",
                    systemImage: "network",
                    description: Text("Tap Load to start the request lifecycle.")
                )
            }

        case .loading(let query, let startedAt):
            Section("State") {
                VStack(alignment: .leading, spacing: 10) {
                    ProgressView("Loading posts for user \(query.userID)...")
                    RequestMetadataView(
                        query: query,
                        source: nil,
                        date: startedAt,
                        label: "Started"
                    )
                }
                .padding(.vertical, 4)
            }

        case .success(let query, let posts, let source, let receivedAt):
            Section {
                RequestMetadataView(
                    query: query,
                    source: source,
                    date: receivedAt,
                    label: source == .cache ? "Loaded from cache" : "Received"
                )
            } header: {
                Text("State")
            }

            Section("Output") {
                ForEach(posts) { post in
                    VStack(alignment: .leading, spacing: 6) {
                        Text(post.title.capitalized)
                            .font(.headline)
                        Text(post.body)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.vertical, 4)
                }
            }

        case .failure(let query, let message, let receivedAt):
            Section("State") {
                RequestMetadataView(
                    query: query,
                    source: nil,
                    date: receivedAt,
                    label: "Failed"
                )

                Label(message, systemImage: "exclamationmark.triangle")
                    .foregroundStyle(.red)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

@MainActor
@Observable
final class APILabModel {
    var userID = 1
    var state: APICallState<[RemotePost]> = .idle

    private let client = JSONPlaceholderClient()
    private var cache: [PostsQuery: CachedAPIResponse<[RemotePost]>] = [:]
    private var activeRequestID: UUID?

    var isLoading: Bool {
        if case .loading = state { return true }
        return false
    }

    var cachedUserIDs: [Int] {
        cache.keys.map(\.userID).sorted()
    }

    func loadPosts(forceRefresh: Bool = false) async {
        let query = PostsQuery(userID: userID)

        if !forceRefresh, let cached = cache[query] {
            state = .success(query: query, output: cached.output, source: .cache, receivedAt: cached.receivedAt)
            return
        }

        let requestID = UUID()
        activeRequestID = requestID
        state = .loading(query: query, startedAt: .now)

        do {
            let posts = try await client.fetchPosts(query: query)
            guard activeRequestID == requestID, !Task.isCancelled else { return }

            let receivedAt = Date()
            cache[query] = CachedAPIResponse(output: posts, receivedAt: receivedAt)
            state = .success(query: query, output: posts, source: .network, receivedAt: receivedAt)
        } catch {
            guard activeRequestID == requestID, !Task.isCancelled else { return }
            state = .failure(query: query, message: error.localizedDescription, receivedAt: .now)
        }
    }

    func clearCache() {
        cache.removeAll()
    }
}

private struct RequestMetadataView: View {
    let query: PostsQuery
    let source: APISource?
    let date: Date
    let label: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            LabeledContent("Endpoint", value: "/posts")
            LabeledContent("Query", value: "userId=\(query.userID)")

            if let source {
                LabeledContent("Source", value: source.title)
            }

            LabeledContent(label, value: date.formatted(date: .omitted, time: .standard))
        }
        .font(.subheadline)
    }
}

enum APICallState<Output> {
    case idle
    case loading(query: PostsQuery, startedAt: Date)
    case success(query: PostsQuery, output: Output, source: APISource, receivedAt: Date)
    case failure(query: PostsQuery, message: String, receivedAt: Date)
}

enum APISource {
    case network
    case cache

    var title: String {
        switch self {
        case .network: "Network"
        case .cache: "Cache"
        }
    }
}

struct PostsQuery: Hashable {
    var userID: Int
}

struct CachedAPIResponse<Output> {
    var output: Output
    var receivedAt: Date
}

struct RemotePost: Codable, Identifiable, Hashable {
    let userId: Int
    let id: Int
    let title: String
    let body: String
}

struct JSONPlaceholderClient {
    func fetchPosts(query: PostsQuery) async throws -> [RemotePost] {
        var components = URLComponents(string: "https://jsonplaceholder.typicode.com/posts")
        components?.queryItems = [
            URLQueryItem(name: "userId", value: "\(query.userID)")
        ]

        guard let url = components?.url else {
            throw APIClientError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 12
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIClientError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw APIClientError.badStatusCode(httpResponse.statusCode)
        }

        do {
            return try JSONDecoder().decode([RemotePost].self, from: data)
        } catch {
            throw APIClientError.decodingFailed
        }
    }
}

enum APIClientError: LocalizedError {
    case invalidURL
    case invalidResponse
    case badStatusCode(Int)
    case decodingFailed

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            "The request URL could not be created."
        case .invalidResponse:
            "The server did not return a valid HTTP response."
        case .badStatusCode(let statusCode):
            "The server returned HTTP \(statusCode)."
        case .decodingFailed:
            "The response JSON did not match the Swift model."
        }
    }
}

#Preview("API Lab") {
    APILabView()
}
