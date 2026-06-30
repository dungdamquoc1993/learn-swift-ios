import SwiftUI

struct ConceptsView: View {
    @Environment(LearningStore.self) private var store

    private var filteredConcepts: [SwiftUIConcept] {
        var result = store.concepts

        if !store.showCompletedConcepts {
            result = result.filter { !$0.isCompleted }
        }

        if let category = store.selectedConceptCategory {
            result = result.filter { $0.category == category }
        }

        let query = store.conceptSearchText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !query.isEmpty {
            result = result.filter { concept in
                concept.title.localizedCaseInsensitiveContains(query)
                || concept.summary.localizedCaseInsensitiveContains(query)
                || concept.category.rawValue.localizedCaseInsensitiveContains(query)
            }
        }

        switch store.conceptSort {
        case .title:
            result.sort { $0.title < $1.title }
        case .difficulty:
            result.sort {
                if $0.difficulty == $1.difficulty {
                    return $0.title < $1.title
                }
                return $0.difficulty < $1.difficulty
            }
        case .progress:
            result.sort {
                if $0.isCompleted == $1.isCompleted {
                    return $0.title < $1.title
                }
                return !$0.isCompleted && $1.isCompleted
            }
        }

        return result
    }

    private var visibleCategories: [ConceptCategory] {
        ConceptCategory.allCases.filter { category in
            filteredConcepts.contains { $0.category == category }
        }
    }

    var body: some View {
        @Bindable var store = store

        NavigationStack {
            List {
                Section {
                    Picker("Category", selection: $store.selectedConceptCategory) {
                        Text("All categories").tag(nil as ConceptCategory?)
                        ForEach(ConceptCategory.allCases) { category in
                            Label(category.rawValue, systemImage: category.symbol)
                                .tag(category as ConceptCategory?)
                        }
                    }

                    Picker("Sort", selection: $store.conceptSort) {
                        ForEach(ConceptSort.allCases) { sort in
                            Text(sort.rawValue).tag(sort)
                        }
                    }

                    Toggle("Show completed", isOn: $store.showCompletedConcepts)
                }

                if filteredConcepts.isEmpty {
                    EmptyStateView(
                        title: "No concepts found",
                        message: "Change the search or filters to see more SwiftUI concepts.",
                        systemImage: "magnifyingglass"
                    )
                    .listRowBackground(Color.clear)
                }

                ForEach(visibleCategories) { category in
                    let concepts = conceptsForCategory(category)
                    Section {
                        ForEach(concepts) { concept in
                            NavigationLink(value: concept.id) {
                                ConceptRow(concept: concept)
                            }
                            .swipeActions(edge: .leading) {
                                Button {
                                    withAnimation {
                                        store.toggleConceptCompletion(id: concept.id)
                                    }
                                } label: {
                                    Label(concept.isCompleted ? "Undo" : "Done", systemImage: concept.isCompleted ? "arrow.uturn.backward" : "checkmark")
                                }
                                .tint(concept.isCompleted ? .gray : .green)
                            }
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    store.deleteConcepts(with: [concept.id])
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                        .onDelete { offsets in
                            let ids = offsets.map { concepts[$0].id }
                            store.deleteConcepts(with: ids)
                        }
                    } header: {
                        Label(category.rawValue, systemImage: category.symbol)
                    }
                }
            }
            .navigationTitle("Concepts")
            .listStyle(.insetGrouped)
            .searchable(text: $store.conceptSearchText, prompt: "Search SwiftUI")
            .refreshable {
                await store.refreshConcepts()
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    EditButton()
                }
            }
            .navigationDestination(for: UUID.self) { conceptID in
                ConceptDetailView(conceptID: conceptID)
            }
        }
    }

    private func conceptsForCategory(_ category: ConceptCategory) -> [SwiftUIConcept] {
        filteredConcepts.filter { $0.category == category }
    }
}

private struct ConceptRow: View {
    let concept: SwiftUIConcept

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: concept.isCompleted ? "checkmark.circle.fill" : concept.category.symbol)
                .font(.title3)
                .foregroundStyle(concept.isCompleted ? .green : concept.category.color)
                .frame(width: 30, height: 30)

            VStack(alignment: .leading, spacing: 6) {
                Text(concept.title)
                    .font(.headline)
                Text(concept.summary)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)

                HStack {
                    DifficultyBadge(difficulty: concept.difficulty)
                    if concept.isCompleted {
                        Label("Done", systemImage: "checkmark")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.green)
                    }
                }
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
    }
}

struct ConceptDetailView: View {
    @Environment(LearningStore.self) private var store
    @State private var showsCode = true

    let conceptID: UUID

    private var concept: SwiftUIConcept? {
        store.concept(with: conceptID)
    }

    private var completionBinding: Binding<Bool> {
        Binding(
            get: { store.concept(with: conceptID)?.isCompleted ?? false },
            set: { store.setConceptCompleted(id: conceptID, isCompleted: $0) }
        )
    }

    private var notesBinding: Binding<String> {
        Binding(
            get: { store.concept(with: conceptID)?.notes ?? "" },
            set: { store.updateNotes(conceptID: conceptID, notes: $0) }
        )
    }

    var body: some View {
        ScrollView {
            if let concept {
                VStack(alignment: .leading, spacing: 18) {
                    detailHeader(concept)

                    CompletionToggle(isCompleted: completionBinding)
                        .padding(.horizontal)

                    StudyCard {
                        VStack(alignment: .leading, spacing: 10) {
                            Label("Summary", systemImage: "text.alignleft")
                                .font(.headline)
                            Text(concept.summary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }

                    StudyCard {
                        VStack(alignment: .leading, spacing: 10) {
                            Toggle("Show sample code", isOn: $showsCode.animation(.snappy))
                            if showsCode {
                                CodeBlockView(code: concept.sampleCode)
                                    .transition(.opacity.combined(with: .move(edge: .top)))
                            }
                        }
                    }

                    StudyCard {
                        VStack(alignment: .leading, spacing: 10) {
                            Label("Your notes", systemImage: "note.text")
                                .font(.headline)
                            TextEditor(text: notesBinding)
                                .frame(minHeight: 130)
                                .padding(8)
                                .background(.background, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                                .accessibilityLabel("Concept notes")
                        }
                    }
                }
                .padding()
            } else {
                EmptyStateView(
                    title: "Concept unavailable",
                    message: "This concept may have been deleted from the sample data.",
                    systemImage: "questionmark.folder"
                )
                .padding()
            }
        }
        .navigationTitle(concept?.title ?? "Concept")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if let concept {
                    Button {
                        withAnimation {
                            store.toggleConceptCompletion(id: concept.id)
                        }
                    } label: {
                        Image(systemName: concept.isCompleted ? "checkmark.circle.fill" : "checkmark.circle")
                    }
                    .accessibilityLabel(concept.isCompleted ? "Mark concept incomplete" : "Mark concept complete")
                }
            }
        }
    }

    private func detailHeader(_ concept: SwiftUIConcept) -> some View {
        StudyCard {
            HStack(alignment: .top, spacing: 16) {
                RemoteSwiftUIImage()

                VStack(alignment: .leading, spacing: 10) {
                    CategoryBadge(category: concept.category)
                    Text(concept.title)
                        .font(.title2.bold())
                    DifficultyBadge(difficulty: concept.difficulty)
                }

                Spacer()
            }
        }
    }
}

#Preview("Concepts") {
    ConceptsView()
        .environment(LearningStore.preview)
}

#Preview("Concept Detail") {
    NavigationStack {
        ConceptDetailView(conceptID: UUID.bindingConcept)
    }
    .environment(LearningStore.preview)
}
