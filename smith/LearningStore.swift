import SwiftUI
import Observation

@MainActor
@Observable
final class LearningStore {
    var concepts: [SwiftUIConcept]
    var practiceTasks: [PracticeTask]
    var resourceState: ResourceState
    var lastRefreshDate: Date?
    var conceptSearchText = ""
    var selectedConceptCategory: ConceptCategory?
    var conceptSort = ConceptSort.title
    var showCompletedConcepts = true
    var practiceSort = PracticeSort.manual
    var showCompletedTasks = true

    init(resourceState: ResourceState = .idle) {
        self.concepts = .sampleConcepts
        self.practiceTasks = .samplePracticeTasks
        self.resourceState = resourceState
    }

    init(
        concepts: [SwiftUIConcept],
        practiceTasks: [PracticeTask],
        resourceState: ResourceState = .idle
    ) {
        self.concepts = concepts
        self.practiceTasks = practiceTasks
        self.resourceState = resourceState
    }

    var completedConceptCount: Int {
        concepts.filter(\.isCompleted).count
    }

    var totalConceptCount: Int {
        concepts.count
    }

    var conceptProgress: Double {
        guard !concepts.isEmpty else { return 0 }
        return Double(completedConceptCount) / Double(concepts.count)
    }

    var completedTaskCount: Int {
        practiceTasks.filter(\.isDone).count
    }

    var openTaskCount: Int {
        practiceTasks.filter { !$0.isDone }.count
    }

    var todayPlannedMinutes: Int {
        let calendar = Calendar.current
        return practiceTasks
            .filter { calendar.isDateInToday($0.dueDate) }
            .map(\.estimatedMinutes)
            .reduce(0, +)
    }

    var currentStreak: Int {
        completedConceptCount + completedTaskCount
    }

    var nextConcept: SwiftUIConcept? {
        concepts
            .filter { !$0.isCompleted }
            .sorted {
                if $0.difficulty == $1.difficulty {
                    return $0.title < $1.title
                }
                return $0.difficulty < $1.difficulty
            }
            .first
    }

    func concept(with id: UUID) -> SwiftUIConcept? {
        concepts.first { $0.id == id }
    }

    func conceptTitle(for id: UUID?) -> String {
        guard let id else { return "General SwiftUI" }
        return concept(with: id)?.title ?? "Unknown concept"
    }

    func setConceptCompleted(id: UUID, isCompleted: Bool) {
        guard let index = concepts.firstIndex(where: { $0.id == id }) else { return }
        concepts[index].isCompleted = isCompleted
    }

    func toggleConceptCompletion(id: UUID) {
        guard let index = concepts.firstIndex(where: { $0.id == id }) else { return }
        concepts[index].isCompleted.toggle()
    }

    func updateNotes(conceptID: UUID, notes: String) {
        guard let index = concepts.firstIndex(where: { $0.id == conceptID }) else { return }
        concepts[index].notes = notes
    }

    func deleteConcepts(with ids: [UUID]) {
        concepts.removeAll { ids.contains($0.id) }
        practiceTasks = practiceTasks.map { task in
            var updated = task
            if let conceptId = updated.conceptId, ids.contains(conceptId) {
                updated.conceptId = nil
            }
            return updated
        }
    }

    func addTask(_ task: PracticeTask) {
        practiceTasks.insert(task, at: 0)
    }

    func updateTask(_ task: PracticeTask) {
        guard let index = practiceTasks.firstIndex(where: { $0.id == task.id }) else { return }
        practiceTasks[index] = task
    }

    func toggleTaskDone(id: UUID) {
        guard let index = practiceTasks.firstIndex(where: { $0.id == id }) else { return }
        practiceTasks[index].isDone.toggle()
    }

    func deleteTasks(with ids: [UUID]) {
        practiceTasks.removeAll { ids.contains($0.id) }
    }

    func moveTasks(from offsets: IndexSet, to destination: Int) {
        practiceTasks.move(fromOffsets: offsets, toOffset: destination)
    }

    func resetSampleData() {
        concepts = .sampleConcepts
        practiceTasks = .samplePracticeTasks
        resourceState = .idle
        lastRefreshDate = nil
        conceptSearchText = ""
        selectedConceptCategory = nil
        conceptSort = .title
        showCompletedConcepts = true
        practiceSort = .manual
        showCompletedTasks = true
    }

    func loadDailyPrompt() async {
        if case .loaded = resourceState { return }

        resourceState = .loading
        do {
            try await Task.sleep(for: .milliseconds(700))
            guard !Task.isCancelled else { return }
            resourceState = .loaded("Build one small SwiftUI screen today, then explain which state owns each value.")
        } catch {
            resourceState = .failed("The daily prompt was cancelled before it finished loading.")
        }
    }

    func refreshConcepts() async {
        resourceState = .loading
        do {
            try await Task.sleep(for: .milliseconds(650))
            guard !Task.isCancelled else { return }
            lastRefreshDate = .now
            resourceState = .loaded("Concepts refreshed. Pick one unfinished idea and turn it into a tiny view.")
        } catch {
            resourceState = .failed("Refresh was interrupted. Pull to refresh or tap retry.")
        }
    }

    func simulatePromptFailure() {
        resourceState = .failed("Demo error state: the app could not load the study prompt.")
    }
}

extension LearningStore {
    static var preview: LearningStore {
        LearningStore(resourceState: .loaded("Preview prompt loaded."))
    }

    static var emptyPreview: LearningStore {
        LearningStore(concepts: [], practiceTasks: [], resourceState: .loaded("No study data yet."))
    }

    static var loadingPreview: LearningStore {
        LearningStore(resourceState: .loading)
    }

    static var errorPreview: LearningStore {
        LearningStore(resourceState: .failed("Preview error state."))
    }
}
