import SwiftUI

enum StudyTab: String, CaseIterable, Identifiable {
    case dashboard
    case concepts
    case apiLab
    case practice
    case settings

    var id: String { rawValue }

    var title: String {
        switch self {
        case .dashboard: "Dashboard"
        case .concepts: "Concepts"
        case .apiLab: "API Lab"
        case .practice: "Practice"
        case .settings: "Settings"
        }
    }

    var systemImage: String {
        switch self {
        case .dashboard: "gauge.with.dots.needle.50percent"
        case .concepts: "list.bullet.rectangle"
        case .apiLab: "network"
        case .practice: "checklist"
        case .settings: "gearshape"
        }
    }
}

enum ConceptCategory: String, CaseIterable, Identifiable, Codable {
    case appStructure = "App Structure"
    case viewsAndLayout = "Views and Layout"
    case stateAndData = "State and Data Flow"
    case navigation = "Navigation"
    case collections = "Collections"
    case formsAndControls = "Forms and Controls"
    case asyncLifecycle = "Async and Lifecycle"
    case animationGesture = "Animation and Gesture"
    case drawingMedia = "Drawing and Media"
    case accessibility = "Accessibility"

    var id: String { rawValue }

    var symbol: String {
        switch self {
        case .appStructure: "app.connected.to.app.below.fill"
        case .viewsAndLayout: "square.grid.3x3"
        case .stateAndData: "arrow.triangle.branch"
        case .navigation: "point.topleft.down.curvedto.point.bottomright.up"
        case .collections: "rectangle.stack"
        case .formsAndControls: "slider.horizontal.3"
        case .asyncLifecycle: "clock.arrow.circlepath"
        case .animationGesture: "hand.tap"
        case .drawingMedia: "scribble.variable"
        case .accessibility: "figure"
        }
    }

    var color: Color {
        switch self {
        case .appStructure: .blue
        case .viewsAndLayout: .teal
        case .stateAndData: .indigo
        case .navigation: .purple
        case .collections: .green
        case .formsAndControls: .orange
        case .asyncLifecycle: .cyan
        case .animationGesture: .pink
        case .drawingMedia: .mint
        case .accessibility: .red
        }
    }
}

enum Difficulty: String, CaseIterable, Identifiable, Codable, Comparable {
    case beginner = "Beginner"
    case intermediate = "Intermediate"
    case advanced = "Advanced"

    var id: String { rawValue }

    var rank: Int {
        switch self {
        case .beginner: 0
        case .intermediate: 1
        case .advanced: 2
        }
    }

    static func < (lhs: Difficulty, rhs: Difficulty) -> Bool {
        lhs.rank < rhs.rank
    }
}

enum PracticePriority: String, CaseIterable, Identifiable, Codable, Comparable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"

    var id: String { rawValue }

    var rank: Int {
        switch self {
        case .low: 0
        case .medium: 1
        case .high: 2
        }
    }

    var tint: Color {
        switch self {
        case .low: .green
        case .medium: .orange
        case .high: .red
        }
    }

    static func < (lhs: PracticePriority, rhs: PracticePriority) -> Bool {
        lhs.rank < rhs.rank
    }
}

enum StudyTheme: String, CaseIterable, Identifiable {
    case system = "System"
    case light = "Light"
    case dark = "Dark"

    var id: String { rawValue }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }
}

enum StudyAccent: String, CaseIterable, Identifiable {
    case teal = "Teal"
    case indigo = "Indigo"
    case orange = "Orange"
    case pink = "Pink"
    case custom = "Custom"

    var id: String { rawValue }

    func color(customRed: Double, customGreen: Double, customBlue: Double) -> Color {
        switch self {
        case .teal: .teal
        case .indigo: .indigo
        case .orange: .orange
        case .pink: .pink
        case .custom: Color(red: customRed, green: customGreen, blue: customBlue)
        }
    }
}

enum ConceptSort: String, CaseIterable, Identifiable {
    case title = "Title"
    case difficulty = "Difficulty"
    case progress = "Progress"

    var id: String { rawValue }
}

enum PracticeSort: String, CaseIterable, Identifiable {
    case manual = "Manual"
    case dueDate = "Due Date"
    case priority = "Priority"
    case title = "Title"

    var id: String { rawValue }
}

enum ResourceState: Equatable {
    case idle
    case loading
    case loaded(String)
    case failed(String)
}

struct SwiftUIConcept: Identifiable, Hashable, Codable {
    let id: UUID
    var title: String
    var category: ConceptCategory
    var difficulty: Difficulty
    var summary: String
    var sampleCode: String
    var isCompleted: Bool
    var notes: String

    init(
        id: UUID = UUID(),
        title: String,
        category: ConceptCategory,
        difficulty: Difficulty,
        summary: String,
        sampleCode: String,
        isCompleted: Bool = false,
        notes: String = ""
    ) {
        self.id = id
        self.title = title
        self.category = category
        self.difficulty = difficulty
        self.summary = summary
        self.sampleCode = sampleCode
        self.isCompleted = isCompleted
        self.notes = notes
    }
}

struct PracticeTask: Identifiable, Hashable, Codable {
    let id: UUID
    var title: String
    var conceptId: UUID?
    var dueDate: Date
    var priority: PracticePriority
    var estimatedMinutes: Int
    var isDone: Bool

    init(
        id: UUID = UUID(),
        title: String,
        conceptId: UUID? = nil,
        dueDate: Date,
        priority: PracticePriority,
        estimatedMinutes: Int,
        isDone: Bool = false
    ) {
        self.id = id
        self.title = title
        self.conceptId = conceptId
        self.dueDate = dueDate
        self.priority = priority
        self.estimatedMinutes = estimatedMinutes
        self.isDone = isDone
    }
}

extension UUID {
    static let appStructureConcept = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
    static let declarativeViewsConcept = UUID(uuidString: "22222222-2222-2222-2222-222222222222")!
    static let layoutConcept = UUID(uuidString: "33333333-3333-3333-3333-333333333333")!
    static let stateConcept = UUID(uuidString: "44444444-4444-4444-4444-444444444444")!
    static let bindingConcept = UUID(uuidString: "55555555-5555-5555-5555-555555555555")!
    static let environmentConcept = UUID(uuidString: "66666666-6666-6666-6666-666666666666")!
    static let navigationConcept = UUID(uuidString: "77777777-7777-7777-7777-777777777777")!
    static let listConcept = UUID(uuidString: "88888888-8888-8888-8888-888888888888")!
    static let formConcept = UUID(uuidString: "99999999-9999-9999-9999-999999999999")!
    static let asyncConcept = UUID(uuidString: "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa")!
    static let animationConcept = UUID(uuidString: "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb")!
    static let drawingConcept = UUID(uuidString: "cccccccc-cccc-cccc-cccc-cccccccccccc")!
    static let accessibilityConcept = UUID(uuidString: "dddddddd-dddd-dddd-dddd-dddddddddddd")!
}
