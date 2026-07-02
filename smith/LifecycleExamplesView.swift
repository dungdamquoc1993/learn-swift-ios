import SwiftUI

struct LifecycleExamplesView: View {
    @Environment(\.scenePhase) private var scenePhase

    @State private var counter = 0
    @State private var appearCount = 0
    @State private var changeCount = 0
    @State private var showProbe = true
    @State private var lifecycleEvents: [String] = []
    @State private var showLoadingExample = true
    @State private var taskEvents: [String] = []
    @State private var searchText = "swift"
    @State private var searchEvents: [String] = []
    @State private var sceneEvents: [String] = []

    var body: some View {
        List {
            Section {
                introCard
            }
            .listRowBackground(Color.clear)

            Section("onAppear and onChange") {
                appearChangeExample
            }

            Section("onDisappear") {
                disappearExample
            }

            Section(".task") {
                taskExample
            }

            Section(".task(id:)") {
                taskIdExample
            }

            Section("scenePhase") {
                scenePhaseExample
            }
        }
        .navigationTitle("Lifecycle hooks")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: scenePhase) { _, newPhase in
            appendSceneEvent("scenePhase -> \(newPhase)")
        }
    }

    private var introCard: some View {
        StudyCard {
            VStack(alignment: .leading, spacing: 10) {
                Label("One place for lifecycle examples", systemImage: "clock.arrow.circlepath")
                    .font(.headline)
                Text("These examples are attached as SwiftUI view modifiers. A body update recalculates the UI description; lifecycle closures run when the matching view event happens.")
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var appearChangeExample: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                StatPill(title: "Counter", value: "\(counter)", tint: .teal)
                StatPill(title: "Appear", value: "\(appearCount)", tint: .green)
                StatPill(title: "Change", value: "\(changeCount)", tint: .orange)
            }

            Button {
                counter += 1
            } label: {
                Label("Increment counter", systemImage: "plus.circle")
            }
            .buttonStyle(.borderedProminent)

            CodeBlockView(code: """
            VStack {
                Text("\\(counter)")
                Button("Increment") { counter += 1 }
            }
            .onAppear {
                appearCount += 1
            }
            .onChange(of: counter) { _, _ in
                changeCount += 1
            }
            """)
        }
        .padding(.vertical, 6)
        .onAppear {
            appearCount += 1
        }
        .onChange(of: counter) { _, _ in
            changeCount += 1
        }
    }

    private var disappearExample: some View {
        VStack(alignment: .leading, spacing: 12) {
            Toggle("Show child view", isOn: $showProbe.animation(.snappy))

            if showProbe {
                LifecycleProbeCard { event in
                    appendLifecycleEvent(event)
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }

            EventLogView(events: lifecycleEvents, emptyMessage: "Toggle the child view to create appear and disappear events.")

            CodeBlockView(code: """
            if showChild {
                ChildView()
                    .onAppear { log("Child appeared") }
                    .onDisappear { log("Child disappeared") }
            }
            """)
        }
        .padding(.vertical, 6)
    }

    private var taskExample: some View {
        VStack(alignment: .leading, spacing: 12) {
            Toggle("Show async loader", isOn: $showLoadingExample.animation(.snappy))

            if showLoadingExample {
                LifecycleTaskCard { event in
                    appendTaskEvent(event)
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }

            EventLogView(events: taskEvents, emptyMessage: "Hide the loader while it runs to see cancellation.")

            CodeBlockView(code: """
            ContentView()
                .task {
                    await loadData()
                }

            // The task starts when the view appears.
            // SwiftUI cancels it when the view disappears.
            """)
        }
        .padding(.vertical, 6)
    }

    private var taskIdExample: some View {
        VStack(alignment: .leading, spacing: 12) {
            TextField("Search text", text: $searchText)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()

            TaskIDSearchProbe(query: searchText) { event in
                appendSearchEvent(event)
            }

            EventLogView(events: searchEvents, emptyMessage: "Edit the query to trigger .task(id:) again.")

            CodeBlockView(code: """
            TextField("Search", text: $query)
                .task(id: query) {
                    results = await search(query)
                }

            // Runs on appear and whenever query changes.
            // The previous async search is cancelled automatically.
            """)
        }
        .padding(.vertical, 6)
    }

    private var scenePhaseExample: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Current phase: \(String(describing: scenePhase))", systemImage: "apps.iphone")
                .font(.headline)

            EventLogView(events: sceneEvents, emptyMessage: "Background or foreground the app to log scene changes.")

            CodeBlockView(code: """
            @Environment(\\.scenePhase) private var scenePhase

            var body: some View {
                ContentView()
                    .onChange(of: scenePhase) { _, phase in
                        saveOrPauseWork(for: phase)
                    }
            }
            """)
        }
        .padding(.vertical, 6)
    }

    private func appendLifecycleEvent(_ event: String) {
        lifecycleEvents = updatedEvents(lifecycleEvents, adding: event)
    }

    private func appendTaskEvent(_ event: String) {
        taskEvents = updatedEvents(taskEvents, adding: event)
    }

    private func appendSearchEvent(_ event: String) {
        searchEvents = updatedEvents(searchEvents, adding: event)
    }

    private func appendSceneEvent(_ event: String) {
        sceneEvents = updatedEvents(sceneEvents, adding: event)
    }

    private func updatedEvents(_ events: [String], adding event: String) -> [String] {
        let timestamp = Date.now.formatted(date: .omitted, time: .standard)
        return Array((["\(timestamp)  \(event)"] + events).prefix(5))
    }
}

private struct StatPill: View {
    let title: String
    let value: String
    let tint: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title3.bold())
                .monospacedDigit()
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .foregroundStyle(tint)
        .accessibilityElement(children: .combine)
    }
}

private struct LifecycleProbeCard: View {
    let onEvent: (String) -> Void

    var body: some View {
        Label("Child view is mounted", systemImage: "rectangle.badge.checkmark")
            .font(.subheadline.weight(.semibold))
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.green.opacity(0.12), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            .onAppear {
                onEvent("child onAppear")
            }
            .onDisappear {
                onEvent("child onDisappear")
            }
    }
}

private struct LifecycleTaskCard: View {
    let onEvent: (String) -> Void
    @State private var status = "Waiting"

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Async loader", systemImage: "arrow.down.circle")
                .font(.subheadline.weight(.semibold))
            Text(status)
                .foregroundStyle(.secondary)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.cyan.opacity(0.12), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .task {
            await runLoad()
        }
    }

    private func runLoad() async {
        status = "Loading step 1"
        onEvent(".task started")

        do {
            for step in 2...3 {
                try await Task.sleep(for: .seconds(1))
                try Task.checkCancellation()
                status = "Loading step \(step)"
                onEvent("loaded step \(step)")
            }

            status = "Finished"
            onEvent(".task finished")
        } catch is CancellationError {
            onEvent(".task cancelled")
        } catch {
            status = "Failed"
            onEvent(".task failed")
        }
    }
}

private struct TaskIDSearchProbe: View {
    let query: String
    let onEvent: (String) -> Void
    @State private var result = "Waiting for query"

    var body: some View {
        Label(result, systemImage: "magnifyingglass")
            .font(.subheadline.weight(.semibold))
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.orange.opacity(0.12), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            .task(id: query) {
                await search(query)
            }
    }

    private func search(_ rawQuery: String) async {
        let trimmedQuery = rawQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty else {
            result = "Empty query"
            onEvent("empty query")
            return
        }

        result = "Searching \"\(trimmedQuery)\""
        onEvent("search started: \(trimmedQuery)")

        do {
            try await Task.sleep(for: .milliseconds(900))
            try Task.checkCancellation()
            result = "Result for \"\(trimmedQuery)\""
            onEvent("search finished: \(trimmedQuery)")
        } catch is CancellationError {
            onEvent("search cancelled: \(trimmedQuery)")
        } catch {
            result = "Search failed"
            onEvent("search failed: \(trimmedQuery)")
        }
    }
}

private struct EventLogView: View {
    let events: [String]
    let emptyMessage: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            if events.isEmpty {
                Text(emptyMessage)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(events, id: \.self) { event in
                    Text(event)
                        .font(.caption.monospaced())
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.quaternary.opacity(0.35), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

#Preview("Lifecycle Examples") {
    NavigationStack {
        LifecycleExamplesView()
    }
}
