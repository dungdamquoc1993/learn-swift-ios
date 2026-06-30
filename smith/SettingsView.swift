import SwiftUI

#if canImport(UIKit)
import UIKit
#endif

struct SettingsView: View {
    @Environment(LearningStore.self) private var store
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    @AppStorage("studyTheme") private var themeRawValue = StudyTheme.system.rawValue
    @AppStorage("studyAccent") private var accentRawValue = StudyAccent.teal.rawValue
    @AppStorage("customAccentRed") private var customAccentRed = 0.0
    @AppStorage("customAccentGreen") private var customAccentGreen = 0.65
    @AppStorage("customAccentBlue") private var customAccentBlue = 0.65
    @AppStorage("dailyGoalMinutes") private var dailyGoalMinutes = 45

    @State private var showsResetDialog = false

    private var selectedAccent: StudyAccent {
        StudyAccent(rawValue: accentRawValue) ?? .teal
    }

    private var accentColor: Color {
        selectedAccent.color(customRed: customAccentRed, customGreen: customAccentGreen, customBlue: customAccentBlue)
    }

    private var customAccentBinding: Binding<Color> {
        Binding(
            get: {
                Color(red: customAccentRed, green: customAccentGreen, blue: customAccentBlue)
            },
            set: { newColor in
                #if canImport(UIKit)
                var red: CGFloat = 0
                var green: CGFloat = 0
                var blue: CGFloat = 0
                var alpha: CGFloat = 0

                if UIColor(newColor).getRed(&red, green: &green, blue: &blue, alpha: &alpha) {
                    customAccentRed = Double(red)
                    customAccentGreen = Double(green)
                    customAccentBlue = Double(blue)
                }
                #endif
            }
        )
    }

    private var dailyGoalBinding: Binding<Double> {
        Binding(
            get: { Double(dailyGoalMinutes) },
            set: { dailyGoalMinutes = Int($0) }
        )
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Appearance") {
                    Picker("Theme", selection: $themeRawValue) {
                        ForEach(StudyTheme.allCases) { theme in
                            Text(theme.rawValue).tag(theme.rawValue)
                        }
                    }

                    Picker("Accent", selection: $accentRawValue) {
                        ForEach(StudyAccent.allCases) { accent in
                            Text(accent.rawValue).tag(accent.rawValue)
                        }
                    }

                    if selectedAccent == .custom {
                        ColorPicker("Custom accent", selection: customAccentBinding, supportsOpacity: false)
                    }

                    HStack {
                        Text("Accent preview")
                        Spacer()
                        Circle()
                            .fill(accentColor)
                            .frame(width: 28, height: 28)
                            .accessibilityLabel("Accent color preview")
                    }
                }

                Section("Daily Goal") {
                    Stepper("\(dailyGoalMinutes) minutes", value: $dailyGoalMinutes, in: 15...180, step: 15)

                    Slider(value: dailyGoalBinding, in: 15...180, step: 15) {
                        Text("Daily goal minutes")
                    } minimumValueLabel: {
                        Text("15")
                    } maximumValueLabel: {
                        Text("180")
                    }
                }

                Section("Environment") {
                    LabeledContent("Appearance", value: colorScheme == .dark ? "Dark" : "Light")
                    LabeledContent("Dynamic Type", value: String(describing: dynamicTypeSize))
                    LabeledContent("Concepts", value: "\(store.completedConceptCount)/\(store.totalConceptCount)")
                    LabeledContent("Open tasks", value: "\(store.openTaskCount)")
                }

                Section("Data") {
                    Button(role: .destructive) {
                        showsResetDialog = true
                    } label: {
                        Label("Reset sample data", systemImage: "arrow.counterclockwise")
                    }
                }
            }
            .navigationTitle("Settings")
            .confirmationDialog(
                "Reset StudySmith?",
                isPresented: $showsResetDialog,
                titleVisibility: .visible
            ) {
                Button("Reset", role: .destructive) {
                    store.resetSampleData()
                }

                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This restores the built-in concepts and practice tasks.")
            }
        }
    }
}

#Preview("Settings") {
    SettingsView()
        .environment(LearningStore.preview)
}
