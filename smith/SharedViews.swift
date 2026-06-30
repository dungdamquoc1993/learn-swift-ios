import SwiftUI

struct StudyCard<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

struct ProgressRingShape: Shape {
    var progress: Double

    var animatableData: Double {
        get { progress }
        set { progress = newValue }
    }

    func path(in rect: CGRect) -> Path {
        let clampedProgress = min(max(progress, 0), 1)
        let radius = min(rect.width, rect.height) / 2
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let startAngle = Angle.degrees(-90)
        let endAngle = Angle.degrees(-90 + (360 * clampedProgress))

        var path = Path()
        path.addArc(
            center: center,
            radius: radius,
            startAngle: startAngle,
            endAngle: endAngle,
            clockwise: false
        )
        return path
    }
}

struct ProgressRingView: View {
    let progress: Double
    let tint: Color

    var body: some View {
        ZStack {
            ProgressRingShape(progress: 1)
                .stroke(.quaternary, style: StrokeStyle(lineWidth: 14, lineCap: .round))

            ProgressRingShape(progress: progress)
                .stroke(tint.gradient, style: StrokeStyle(lineWidth: 14, lineCap: .round))
                .animation(.spring(response: 0.6, dampingFraction: 0.8), value: progress)

            VStack(spacing: 2) {
                Text(progress, format: .percent.precision(.fractionLength(0)))
                    .font(.title.bold())
                    .monospacedDigit()
                Text("complete")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Course progress")
        .accessibilityValue(progress.formatted(.percent.precision(.fractionLength(0))))
    }
}

struct StatTile: View {
    let title: String
    let value: String
    let systemImage: String
    let tint: Color

    var body: some View {
        StudyCard {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: systemImage)
                    .font(.title3)
                    .foregroundStyle(tint)
                    .frame(width: 28, height: 28)

                VStack(alignment: .leading, spacing: 4) {
                    Text(value)
                        .font(.title3.bold())
                        .monospacedDigit()
                    Text(title)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .accessibilityElement(children: .combine)
    }
}

struct CategoryBadge: View {
    let category: ConceptCategory

    var body: some View {
        Label(category.rawValue, systemImage: category.symbol)
            .font(.caption.weight(.semibold))
            .foregroundStyle(category.color)
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(category.color.opacity(0.12), in: Capsule())
    }
}

struct DifficultyBadge: View {
    let difficulty: Difficulty

    var body: some View {
        Text(difficulty.rawValue)
            .font(.caption.weight(.semibold))
            .foregroundStyle(.secondary)
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(.quaternary, in: Capsule())
    }
}

struct PriorityBadge: View {
    let priority: PracticePriority

    var body: some View {
        Text(priority.rawValue)
            .font(.caption.weight(.semibold))
            .foregroundStyle(priority.tint)
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(priority.tint.opacity(0.12), in: Capsule())
    }
}

struct CompletionToggle: View {
    @Binding var isCompleted: Bool

    var body: some View {
        Toggle(isCompleted ? "Completed" : "Mark completed", isOn: $isCompleted)
            .toggleStyle(.switch)
            .accessibilityHint("Updates the concept progress used on the dashboard.")
    }
}

struct CodeBlockView: View {
    let code: String

    var body: some View {
        ScrollView(.horizontal) {
            Text(code)
                .font(.system(.caption, design: .monospaced))
                .textSelection(.enabled)
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .accessibilityLabel("Swift code sample")
    }
}

struct RemoteSwiftUIImage: View {
    var body: some View {
        AsyncImage(url: URL(string: "https://developer.apple.com/assets/elements/icons/swiftui/swiftui-96x96_2x.png")) { phase in
            switch phase {
            case .empty:
                ProgressView()
            case .success(let image):
                image
                    .resizable()
                    .scaledToFit()
            case .failure:
                Image(systemName: "swift")
                    .font(.largeTitle)
                    .foregroundStyle(.orange)
            @unknown default:
                EmptyView()
            }
        }
        .frame(width: 72, height: 72)
        .accessibilityLabel("SwiftUI icon")
    }
}

struct EmptyStateView: View {
    let title: String
    let message: String
    let systemImage: String

    var body: some View {
        ContentUnavailableView(title, systemImage: systemImage, description: Text(message))
    }
}

struct GesturePracticeCard: View {
    @State private var isPinned = false
    @GestureState private var dragOffset: CGSize = .zero

    var body: some View {
        StudyCard {
            HStack(spacing: 14) {
                Image(systemName: isPinned ? "pin.fill" : "hand.draw")
                    .font(.title2)
                    .foregroundStyle(isPinned ? .orange : .secondary)
                    .frame(width: 34, height: 34)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Gesture lab")
                        .font(.headline)
                    Text(isPinned ? "Pinned with animated state" : "Tap or drag the card")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }
        }
        .offset(x: dragOffset.width, y: dragOffset.height / 3)
        .scaleEffect(isPinned ? 1.02 : 1)
        .shadow(color: isPinned ? .orange.opacity(0.25) : .clear, radius: 10, y: 4)
        .gesture(
            DragGesture(minimumDistance: 8)
                .updating($dragOffset) { value, state, _ in
                    state = value.translation
                }
                .onEnded { value in
                    guard abs(value.translation.width) > 70 || abs(value.translation.height) > 70 else { return }
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                        isPinned.toggle()
                    }
                }
        )
        .onTapGesture {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                isPinned.toggle()
            }
        }
        .onLongPressGesture {
            withAnimation(.snappy) {
                isPinned = false
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: dragOffset)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
        .accessibilityHint("Tap, drag, or long press to change the animated state.")
    }
}
