import SwiftUI

struct PracticeView: View {
    @Environment(LearningStore.self) private var store
    @State private var editorMode: PracticeEditorMode?
    @State private var pendingDelete: PracticeTask?
    @State private var showsDeleteDialog = false
    @State private var searchText = ""

    private var canMoveManually: Bool {
        store.practiceSort == .manual && store.showCompletedTasks && searchText.isEmpty
    }

    private var filteredTasks: [PracticeTask] {
        var result = store.practiceTasks

        if !store.showCompletedTasks {
            result = result.filter { !$0.isDone }
        }

        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !query.isEmpty {
            result = result.filter { task in
                task.title.localizedCaseInsensitiveContains(query)
                || store.conceptTitle(for: task.conceptId).localizedCaseInsensitiveContains(query)
            }
        }

        switch store.practiceSort {
        case .manual:
            break
        case .dueDate:
            result.sort { $0.dueDate < $1.dueDate }
        case .priority:
            result.sort {
                if $0.priority == $1.priority {
                    return $0.dueDate < $1.dueDate
                }
                return $0.priority > $1.priority
            }
        case .title:
            result.sort { $0.title < $1.title }
        }

        return result
    }

    var body: some View {
        @Bindable var store = store

        NavigationStack {
            List {
                Section {
                    Picker("Sort", selection: $store.practiceSort) {
                        ForEach(PracticeSort.allCases) { sort in
                            Text(sort.rawValue).tag(sort)
                        }
                    }

                    Toggle("Show done tasks", isOn: $store.showCompletedTasks)
                }

                if filteredTasks.isEmpty {
                    EmptyStateView(
                        title: "No practice tasks",
                        message: "Add a task to turn one SwiftUI concept into code.",
                        systemImage: "checklist"
                    )
                    .listRowBackground(Color.clear)
                } else if canMoveManually {
                    taskSection(tasks: store.practiceTasks, supportsMove: true)
                } else {
                    taskSection(tasks: filteredTasks, supportsMove: false)
                }
            }
            .navigationTitle("Practice")
            .listStyle(.insetGrouped)
            .searchable(text: $searchText, prompt: "Search tasks")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    EditButton()
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        editorMode = .add
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Add practice task")
                }
            }
            .sheet(item: $editorMode) { mode in
                PracticeEditorView(mode: mode)
            }
            .confirmationDialog(
                "Delete practice task?",
                isPresented: $showsDeleteDialog,
                titleVisibility: .visible
            ) {
                Button("Delete", role: .destructive) {
                    if let pendingDelete {
                        store.deleteTasks(with: [pendingDelete.id])
                    }
                    pendingDelete = nil
                }

                Button("Cancel", role: .cancel) {
                    pendingDelete = nil
                }
            } message: {
                Text(pendingDelete?.title ?? "This task will be removed.")
            }
        }
    }

    @ViewBuilder
    private func taskSection(tasks: [PracticeTask], supportsMove: Bool) -> some View {
        Section("Tasks") {
            if supportsMove {
                ForEach(tasks) { task in
                    taskRow(task)
                }
                    .onDelete { offsets in
                        let ids = offsets.map { tasks[$0].id }
                        store.deleteTasks(with: ids)
                    }
                    .onMove { offsets, destination in
                        store.moveTasks(from: offsets, to: destination)
                    }
            } else {
                ForEach(tasks) { task in
                    taskRow(task)
                }
                    .onDelete { offsets in
                        let ids = offsets.map { tasks[$0].id }
                        store.deleteTasks(with: ids)
                    }
            }
        }
    }

    private func taskRow(_ task: PracticeTask) -> some View {
        Button {
            editorMode = .edit(task.id)
        } label: {
            PracticeTaskRow(task: task)
        }
        .buttonStyle(.plain)
        .swipeActions(edge: .leading) {
            Button {
                withAnimation {
                    store.toggleTaskDone(id: task.id)
                }
            } label: {
                Label(task.isDone ? "Undo" : "Done", systemImage: task.isDone ? "arrow.uturn.backward" : "checkmark")
            }
            .tint(task.isDone ? .gray : .green)
        }
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) {
                pendingDelete = task
                showsDeleteDialog = true
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}

private struct PracticeTaskRow: View {
    @Environment(LearningStore.self) private var store
    let task: PracticeTask

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: task.isDone ? "checkmark.circle.fill" : "circle")
                .font(.title3)
                .foregroundStyle(task.isDone ? .green : task.priority.tint)
                .frame(width: 30, height: 30)

            VStack(alignment: .leading, spacing: 6) {
                Text(task.title)
                    .font(.headline)
                    .strikethrough(task.isDone)
                    .foregroundStyle(task.isDone ? .secondary : .primary)

                Text(store.conceptTitle(for: task.conceptId))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                HStack {
                    PriorityBadge(priority: task.priority)
                    Label(task.dueDate.formatted(date: .abbreviated, time: .omitted), systemImage: "calendar")
                    Label("\(task.estimatedMinutes)m", systemImage: "timer")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
    }
}

private enum PracticeEditorMode: Identifiable, Equatable {
    case add
    case edit(UUID)

    var id: String {
        switch self {
        case .add: "add"
        case .edit(let id): "edit-\(id.uuidString)"
        }
    }

    var title: String {
        switch self {
        case .add: "New Practice"
        case .edit: "Edit Practice"
        }
    }
}

private struct PracticeDraft {
    var id: UUID?
    var title = ""
    var conceptId: UUID?
    var dueDate = Date()
    var priority = PracticePriority.medium
    var estimatedMinutes = 45
    var isDone = false

    var isValid: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    init() {}

    init(task: PracticeTask) {
        id = task.id
        title = task.title
        conceptId = task.conceptId
        dueDate = task.dueDate
        priority = task.priority
        estimatedMinutes = task.estimatedMinutes
        isDone = task.isDone
    }

    func makeTask() -> PracticeTask {
        PracticeTask(
            id: id ?? UUID(),
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            conceptId: conceptId,
            dueDate: dueDate,
            priority: priority,
            estimatedMinutes: estimatedMinutes,
            isDone: isDone
        )
    }
}

private struct PracticeEditorView: View {
    @Environment(LearningStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    let mode: PracticeEditorMode

    @State private var draft = PracticeDraft()
    @State private var didLoadDraft = false
    @State private var showsValidationAlert = false
    @FocusState private var focusedField: Field?

    private enum Field {
        case title
    }

    private var minutesBinding: Binding<Double> {
        Binding(
            get: { Double(draft.estimatedMinutes) },
            set: { draft.estimatedMinutes = Int($0) }
        )
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Task") {
                    TextField("Build a Form screen", text: $draft.title)
                        .focused($focusedField, equals: .title)
                        .submitLabel(.done)

                    Picker("Concept", selection: $draft.conceptId) {
                        Text("General SwiftUI").tag(nil as UUID?)
                        ForEach(store.concepts) { concept in
                            Text(concept.title).tag(concept.id as UUID?)
                        }
                    }
                }

                Section("Schedule") {
                    DatePicker("Due date", selection: $draft.dueDate, displayedComponents: .date)

                    Picker("Priority", selection: $draft.priority) {
                        ForEach(PracticePriority.allCases) { priority in
                            Text(priority.rawValue).tag(priority)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section("Effort") {
                    Stepper("\(draft.estimatedMinutes) minutes", value: $draft.estimatedMinutes, in: 15...180, step: 15)

                    Slider(value: minutesBinding, in: 15...180, step: 15) {
                        Text("Estimated minutes")
                    } minimumValueLabel: {
                        Text("15")
                    } maximumValueLabel: {
                        Text("180")
                    }
                }

                Section("Status") {
                    Toggle("Already done", isOn: $draft.isDone)
                }
            }
            .navigationTitle(mode.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        save()
                    }
                }
            }
            .onAppear(perform: loadDraftIfNeeded)
            .alert("Title required", isPresented: $showsValidationAlert) {
                Button("OK", role: .cancel) {
                    focusedField = .title
                }
            } message: {
                Text("Give the practice task a short title before saving.")
            }
        }
    }

    private func loadDraftIfNeeded() {
        guard !didLoadDraft else { return }

        switch mode {
        case .add:
            draft = PracticeDraft()
            draft.conceptId = store.nextConcept?.id
        case .edit(let id):
            if let task = store.practiceTasks.first(where: { $0.id == id }) {
                draft = PracticeDraft(task: task)
            }
        }

        didLoadDraft = true
        focusedField = .title
    }

    private func save() {
        guard draft.isValid else {
            showsValidationAlert = true
            return
        }

        let task = draft.makeTask()
        switch mode {
        case .add:
            store.addTask(task)
        case .edit:
            store.updateTask(task)
        }

        dismiss()
    }
}

#Preview("Practice") {
    PracticeView()
        .environment(LearningStore.preview)
}
