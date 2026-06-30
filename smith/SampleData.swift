import Foundation

extension Array where Element == SwiftUIConcept {
    static let sampleConcepts: [SwiftUIConcept] = [
        SwiftUIConcept(
            id: .appStructureConcept,
            title: "App, Scene, WindowGroup",
            category: .appStructure,
            difficulty: .beginner,
            summary: "The app entry point declares the top-level scenes SwiftUI manages for you.",
            sampleCode: """
            @main
            struct StudySmithApp: App {
                var body: some Scene {
                    WindowGroup {
                        ContentView()
                    }
                }
            }
            """,
            isCompleted: true
        ),
        SwiftUIConcept(
            id: .declarativeViewsConcept,
            title: "View Composition",
            category: .viewsAndLayout,
            difficulty: .beginner,
            summary: "Build complex screens by composing small views and applying modifiers.",
            sampleCode: """
            struct MetricTile: View {
                let title: String
                let value: String

                var body: some View {
                    VStack(alignment: .leading) {
                        Text(value).font(.title.bold())
                        Text(title).foregroundStyle(.secondary)
                    }
                    .padding()
                }
            }
            """
        ),
        SwiftUIConcept(
            id: .layoutConcept,
            title: "Adaptive Layout",
            category: .viewsAndLayout,
            difficulty: .intermediate,
            summary: "Use stacks, grids, scroll views, and ViewThatFits to adapt to available space.",
            sampleCode: """
            ViewThatFits(in: .horizontal) {
                HStack { summary; actions }
                VStack(alignment: .leading) { summary; actions }
            }
            """
        ),
        SwiftUIConcept(
            id: .stateConcept,
            title: "@State",
            category: .stateAndData,
            difficulty: .beginner,
            summary: "Use @State for value owned privately by one view.",
            sampleCode: """
            @State private var isExpanded = false

            Button("Toggle") {
                isExpanded.toggle()
            }
            """
        ),
        SwiftUIConcept(
            id: .bindingConcept,
            title: "@Binding",
            category: .stateAndData,
            difficulty: .beginner,
            summary: "Pass a writable connection to state owned by another view.",
            sampleCode: """
            struct CompletionToggle: View {
                @Binding var isCompleted: Bool

                var body: some View {
                    Toggle("Completed", isOn: $isCompleted)
                }
            }
            """
        ),
        SwiftUIConcept(
            id: .environmentConcept,
            title: "@Environment and @Observable",
            category: .stateAndData,
            difficulty: .intermediate,
            summary: "Share observable app state through the environment so child views stay small.",
            sampleCode: """
            @Observable
            final class LearningStore {
                var concepts: [SwiftUIConcept] = []
            }

            @Environment(LearningStore.self) private var store
            """
        ),
        SwiftUIConcept(
            id: .navigationConcept,
            title: "NavigationStack and Sheets",
            category: .navigation,
            difficulty: .beginner,
            summary: "Push detail screens with NavigationStack and present focused workflows in sheets.",
            sampleCode: """
            NavigationStack {
                List(concepts) { concept in
                    NavigationLink(concept.title, value: concept.id)
                }
                .navigationDestination(for: UUID.self) { id in
                    ConceptDetailView(conceptID: id)
                }
            }
            """
        ),
        SwiftUIConcept(
            id: .listConcept,
            title: "List, ForEach, Search",
            category: .collections,
            difficulty: .beginner,
            summary: "Lists render dynamic collections and can support sections, search, delete, and swipe actions.",
            sampleCode: """
            List {
                ForEach(filteredConcepts) { concept in
                    ConceptRow(concept: concept)
                }
                .onDelete(perform: delete)
            }
            .searchable(text: $searchText)
            """
        ),
        SwiftUIConcept(
            id: .formConcept,
            title: "Form Controls",
            category: .formsAndControls,
            difficulty: .beginner,
            summary: "Form groups text fields, pickers, toggles, dates, steppers, and sliders for editing data.",
            sampleCode: """
            Form {
                TextField("Title", text: $draft.title)
                DatePicker("Due", selection: $draft.dueDate)
                Toggle("Done", isOn: $draft.isDone)
            }
            """
        ),
        SwiftUIConcept(
            id: .asyncConcept,
            title: ".task and .refreshable",
            category: .asyncLifecycle,
            difficulty: .intermediate,
            summary: "Attach async work to a view lifecycle and expose loading, error, retry, and refresh states.",
            sampleCode: """
            .task {
                await store.loadDailyPrompt()
            }
            .refreshable {
                await store.refreshConcepts()
            }
            """
        ),
        SwiftUIConcept(
            id: .animationConcept,
            title: "Animation and Gestures",
            category: .animationGesture,
            difficulty: .intermediate,
            summary: "Animate state changes and map tap, drag, or long-press gestures into interactions.",
            sampleCode: """
            card
                .offset(dragOffset)
                .gesture(
                    DragGesture()
                        .updating($dragOffset) { value, state, _ in
                            state = value.translation
                        }
                )
                .animation(.spring(), value: isPinned)
            """
        ),
        SwiftUIConcept(
            id: .drawingConcept,
            title: "Shape and AsyncImage",
            category: .drawingMedia,
            difficulty: .intermediate,
            summary: "Create custom vector drawing with Shape and load remote images with AsyncImage.",
            sampleCode: """
            struct ProgressRing: Shape {
                var progress: Double

                func path(in rect: CGRect) -> Path {
                    Path { path in
                        path.addArc(center: rect.center, radius: 48, startAngle: .degrees(-90), endAngle: .degrees(270 * progress), clockwise: false)
                    }
                }
            }
            """
        ),
        SwiftUIConcept(
            id: .accessibilityConcept,
            title: "Accessibility and Previews",
            category: .accessibility,
            difficulty: .beginner,
            summary: "Use semantic labels, hints, Dynamic Type, dark mode previews, and sample states.",
            sampleCode: """
            ProgressView(value: progress)
                .accessibilityLabel("Course progress")
                .accessibilityValue(progress.formatted(.percent))

            #Preview("Large Type") {
                ContentView()
                    .environment(\\.dynamicTypeSize, .accessibility2)
            }
            """
        )
    ]
}

extension Array where Element == PracticeTask {
    static let samplePracticeTasks: [PracticeTask] = [
        PracticeTask(
            title: "Build a dashboard card with Grid",
            conceptId: .layoutConcept,
            dueDate: Calendar.current.date(byAdding: .day, value: 0, to: .now) ?? .now,
            priority: .high,
            estimatedMinutes: 45
        ),
        PracticeTask(
            title: "Add a searchable concept list",
            conceptId: .listConcept,
            dueDate: Calendar.current.date(byAdding: .day, value: 1, to: .now) ?? .now,
            priority: .medium,
            estimatedMinutes: 35,
            isDone: true
        ),
        PracticeTask(
            title: "Create an edit form in a sheet",
            conceptId: .formConcept,
            dueDate: Calendar.current.date(byAdding: .day, value: 2, to: .now) ?? .now,
            priority: .medium,
            estimatedMinutes: 60
        ),
        PracticeTask(
            title: "Write accessibility labels for key controls",
            conceptId: .accessibilityConcept,
            dueDate: Calendar.current.date(byAdding: .day, value: 3, to: .now) ?? .now,
            priority: .low,
            estimatedMinutes: 30
        )
    ]
}
