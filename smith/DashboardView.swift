import SwiftUI

struct DashboardView: View {
    @Environment(LearningStore.self) private var store
    @AppStorage("dailyGoalMinutes") private var dailyGoalMinutes = 45

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 16) {
                    dashboardHeader
                    metricGrid
                    dailyPrompt
                    nextLesson
                    GesturePracticeCard()
                    taskPreview
                }
                .padding()
            }
            .navigationTitle("StudySmith")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task { await store.refreshConcepts() }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .accessibilityLabel("Refresh study data")
                }
            }
            .navigationDestination(for: UUID.self) { conceptID in
                ConceptDetailView(conceptID: conceptID)
            }
            .task {
                await store.loadDailyPrompt()
            }
            .refreshable {
                await store.refreshConcepts()
            }
        }
    }

    private var dashboardHeader: some View {
        StudyCard {
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .center, spacing: 24) {
                    headerCopy
                    Spacer(minLength: 24)
                    ProgressRingView(progress: store.conceptProgress, tint: .teal)
                        .frame(width: 150)
                }

                VStack(alignment: .leading, spacing: 16) {
                    headerCopy
                    ProgressRingView(progress: store.conceptProgress, tint: .teal)
                        .frame(maxWidth: 220)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            }
        }
    }

    private var headerCopy: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("SwiftUI learning path")
                .font(.title2.bold())
            Text("Finish small concepts, then turn them into practice screens.")
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            Label("\(store.completedConceptCount) of \(store.totalConceptCount) concepts complete", systemImage: "checkmark.seal")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.teal)
        }
    }

    private var metricGrid: some View {
        Grid(horizontalSpacing: 12, verticalSpacing: 12) {
            GridRow {
                StatTile(title: "Streak score", value: "\(store.currentStreak)", systemImage: "flame", tint: .orange)
                StatTile(title: "Open tasks", value: "\(store.openTaskCount)", systemImage: "tray.full", tint: .blue)
            }
            GridRow {
                StatTile(title: "Today planned", value: "\(store.todayPlannedMinutes)m", systemImage: "calendar", tint: .purple)
                StatTile(title: "Daily goal", value: "\(dailyGoalMinutes)m", systemImage: "target", tint: .green)
            }
        }
    }

    private var dailyPrompt: some View {
        StudyCard {
            VStack(alignment: .leading, spacing: 12) {
                Label("Daily prompt", systemImage: "sparkles")
                    .font(.headline)

                switch store.resourceState {
                case .idle:
                    Text("Prompt is ready to load.")
                        .foregroundStyle(.secondary)
                case .loading:
                    ProgressView("Loading prompt...")
                case .loaded(let message):
                    Text(message)
                        .font(.body)
                        .fixedSize(horizontal: false, vertical: true)
                case .failed(let message):
                    Label(message, systemImage: "exclamationmark.triangle")
                        .foregroundStyle(.red)
                        .fixedSize(horizontal: false, vertical: true)
                }

                HStack {
                    Button {
                        Task { await store.loadDailyPrompt() }
                    } label: {
                        Label("Retry", systemImage: "arrow.clockwise")
                    }
                    .buttonStyle(.bordered)

                    Button {
                        store.simulatePromptFailure()
                    } label: {
                        Label("Error", systemImage: "exclamationmark.triangle")
                    }
                    .buttonStyle(.bordered)
                    .tint(.red)
                }
            }
        }
    }

    private var nextLesson: some View {
        StudyCard {
            VStack(alignment: .leading, spacing: 12) {
                Label("Recommended next lesson", systemImage: "book.closed")
                    .font(.headline)

                if let concept = store.nextConcept {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            CategoryBadge(category: concept.category)
                            DifficultyBadge(difficulty: concept.difficulty)
                        }

                        Text(concept.title)
                            .font(.title3.bold())
                        Text(concept.summary)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)

                        HStack {
                            NavigationLink(value: concept.id) {
                                Label("Open", systemImage: "arrow.right.circle")
                            }
                            .buttonStyle(.borderedProminent)

                            Button {
                                withAnimation {
                                    store.toggleConceptCompletion(id: concept.id)
                                }
                            } label: {
                                Label("Complete", systemImage: "checkmark")
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                } else {
                    EmptyStateView(
                        title: "All concepts complete",
                        message: "Reset sample data in Settings to replay the learning path.",
                        systemImage: "checkmark.circle"
                    )
                }
            }
        }
    }

    private var taskPreview: some View {
        StudyCard {
            VStack(alignment: .leading, spacing: 12) {
                Label("Upcoming practice", systemImage: "calendar.badge.clock")
                    .font(.headline)

                let upcoming = store.practiceTasks
                    .filter { !$0.isDone }
                    .sorted { $0.dueDate < $1.dueDate }
                    .prefix(3)

                if upcoming.isEmpty {
                    EmptyStateView(
                        title: "No open tasks",
                        message: "Add a practice task when you are ready for another mini build.",
                        systemImage: "checklist.checked"
                    )
                } else {
                    ForEach(Array(upcoming)) { task in
                        HStack(spacing: 12) {
                            Image(systemName: "circle")
                                .foregroundStyle(task.priority.tint)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(task.title)
                                    .font(.subheadline.weight(.semibold))
                                Text("\(store.conceptTitle(for: task.conceptId)) -> \(task.dueDate.formatted(date: .abbreviated, time: .omitted))")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text("\(task.estimatedMinutes)m")
                                .font(.caption.weight(.semibold))
                                .monospacedDigit()
                        }
                    }
                }
            }
        }
    }
}

#Preview("Dashboard Populated") {
    DashboardView()
        .environment(LearningStore.preview)
}

#Preview("Dashboard Loading") {
    DashboardView()
        .environment(LearningStore.loadingPreview)
}

#Preview("Dashboard Empty") {
    DashboardView()
        .environment(LearningStore.emptyPreview)
}

#Preview("Dashboard Error") {
    DashboardView()
        .environment(LearningStore.errorPreview)
}
