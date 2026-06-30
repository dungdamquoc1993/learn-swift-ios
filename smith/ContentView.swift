import SwiftUI

struct ContentView: View {
    @State private var store = LearningStore()
    @SceneStorage("selectedStudyTab") private var selectedTab = StudyTab.dashboard.rawValue

    @AppStorage("studyTheme") private var themeRawValue = StudyTheme.system.rawValue
    @AppStorage("studyAccent") private var accentRawValue = StudyAccent.teal.rawValue
    @AppStorage("customAccentRed") private var customAccentRed = 0.0
    @AppStorage("customAccentGreen") private var customAccentGreen = 0.65
    @AppStorage("customAccentBlue") private var customAccentBlue = 0.65

    private var theme: StudyTheme {
        StudyTheme(rawValue: themeRawValue) ?? .system
    }

    private var accent: Color {
        (StudyAccent(rawValue: accentRawValue) ?? .teal)
            .color(customRed: customAccentRed, customGreen: customAccentGreen, customBlue: customAccentBlue)
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            DashboardView()
                .tabItem {
                    Label(StudyTab.dashboard.title, systemImage: StudyTab.dashboard.systemImage)
                }
                .tag(StudyTab.dashboard.rawValue)

            ConceptsView()
                .tabItem {
                    Label(StudyTab.concepts.title, systemImage: StudyTab.concepts.systemImage)
                }
                .tag(StudyTab.concepts.rawValue)

            PracticeView()
                .tabItem {
                    Label(StudyTab.practice.title, systemImage: StudyTab.practice.systemImage)
                }
                .tag(StudyTab.practice.rawValue)

            SettingsView()
                .tabItem {
                    Label(StudyTab.settings.title, systemImage: StudyTab.settings.systemImage)
                }
                .tag(StudyTab.settings.rawValue)
        }
        .environment(store)
        .tint(accent)
        .preferredColorScheme(theme.colorScheme)
    }
}

#Preview("Populated") {
    ContentView()
}

#Preview("Dark Large Type") {
    ContentView()
        .preferredColorScheme(.dark)
        .environment(\.dynamicTypeSize, .accessibility2)
}
