# StudySmith SwiftUI Learning Doc

Tài liệu này dùng project **StudySmith** như một bản đồ học SwiftUI. Cách học tốt nhất là mở app, mở file tương ứng, sửa một chi tiết nhỏ, chạy lại, rồi tự giải thích vì sao UI đổi theo state.

## 1. Bức Tranh Tổng Quan

StudySmith là app 4 tab:

- **Dashboard**: tổng quan tiến độ, async prompt, animation, gesture.
- **Concepts**: danh sách khái niệm SwiftUI, search/filter/sort, detail screen.
- **Practice**: CRUD task bằng form, sheet, alert, confirmation dialog.
- **Settings**: preferences bằng `@AppStorage`, theme, accent, daily goal.

Các file chính:

- `ContentView.swift`: app shell, tab navigation, app-wide state.
- `Models.swift`: model, enum, kiểu dữ liệu nền.
- `LearningStore.swift`: observable store, mutation, computed state.
- `SampleData.swift`: dữ liệu mẫu và code snippet để học.
- `SharedViews.swift`: component tái sử dụng.
- `DashboardView.swift`, `ConceptsView.swift`, `PracticeView.swift`, `SettingsView.swift`: 4 màn hình chính.

## 2. App Structure

SwiftUI app bắt đầu từ `@main App`.

Xem:

- `smithApp.swift`
- `ContentView.swift`

Khái niệm:

- `App`: entry point của app.
- `Scene`: vùng UI được hệ thống quản lý.
- `WindowGroup`: scene phổ biến cho iOS app.
- `ContentView`: root view đầu tiên.

Trong project này:

```swift
@main
struct StudySmithApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
```

Bài tập:

- Đổi tab mặc định từ Dashboard sang Concepts.
- Đổi tên tab hoặc icon trong `StudyTab`.
- Thêm một tab giả tên `Lab` rồi thử build.

## 3. Declarative UI

SwiftUI không bảo bạn "tạo label rồi update label". Bạn mô tả UI phải trông như thế nào với state hiện tại.

Xem:

- `DashboardView.swift`
- `SharedViews.swift`

Khái niệm:

- `View`
- `body`
- modifier như `.font`, `.foregroundStyle`, `.padding`
- view composition: tách UI thành view nhỏ

Ví dụ trong project:

- `StudyCard`
- `StatTile`
- `CategoryBadge`
- `ProgressRingView`

Bài tập:

- Đổi style của `StudyCard`.
- Thêm một `StatTile` mới vào Dashboard.
- Tách một phần UI trong `DashboardView` thành view riêng.

## 4. Layout

Layout là cách SwiftUI sắp xếp view theo không gian có sẵn.

Xem:

- `DashboardView.swift`
- `SharedViews.swift`

Khái niệm:

- `VStack`, `HStack`, `ZStack`
- `Grid`, `GridRow`
- `ScrollView`
- `LazyVStack`
- `Spacer`
- `ViewThatFits`
- `.frame`, `.overlay`, `.background`

Trong Dashboard, `ViewThatFits` giúp header đổi layout khi màn hình hẹp:

```swift
ViewThatFits(in: .horizontal) {
    HStack { ... }
    VStack { ... }
}
```

Bài tập:

- Thay `Grid` trong Dashboard bằng `LazyVGrid`.
- Đổi Dashboard header để progress ring nằm trên cùng khi màn hình nhỏ.
- Thêm `.safeAreaInset` cho một footer nhỏ.

## 5. State Và Data Flow

Đây là phần quan trọng nhất của SwiftUI.

Xem:

- `ContentView.swift`
- `LearningStore.swift`
- `ConceptsView.swift`
- `PracticeView.swift`
- `SharedViews.swift`

Khái niệm:

- `@State`: state do view sở hữu.
- `@Binding`: truyền quyền đọc/ghi state cho child view.
- `@Environment`: đọc dependency hoặc value từ môi trường.
- `@Observable`: class có thể làm UI tự refresh khi data đổi.
- `@Bindable`: tạo binding tới property của object observable.
- `@AppStorage`: lưu preference vào UserDefaults.
- `@SceneStorage`: lưu state theo scene.

Ví dụ trong project:

- `ContentView` sở hữu `@State private var store = LearningStore()`.
- Các màn hình đọc store bằng `@Environment(LearningStore.self)`.
- `ConceptsView` dùng `@Bindable` để bind picker/toggle vào store.
- `CompletionToggle` nhận `@Binding var isCompleted`.
- `SettingsView` dùng `@AppStorage` cho theme/accent/daily goal.
- `ContentView` dùng `@SceneStorage` để nhớ tab đang chọn.

Bài tập:

- Thêm property `showBeginnerOnly` vào `LearningStore`.
- Bind property đó với một `Toggle` trong `ConceptsView`.
- Quan sát list tự refresh mà không cần gọi hàm reload UI.

## 6. Navigation Và Presentation

SwiftUI có 2 hướng điều hướng chính:

- Push screen: `NavigationStack`, `NavigationLink`, `navigationDestination`.
- Present modal: `.sheet`, `.alert`, `.confirmationDialog`.

Xem:

- `ConceptsView.swift`
- `PracticeView.swift`
- `DashboardView.swift`

Khái niệm:

- `NavigationStack`
- `NavigationLink(value:)`
- `.navigationDestination(for:)`
- `.sheet(item:)`
- `.alert`
- `.confirmationDialog`
- toolbar actions

Trong Concepts:

```swift
NavigationLink(value: concept.id) {
    ConceptRow(concept: concept)
}
.navigationDestination(for: UUID.self) { conceptID in
    ConceptDetailView(conceptID: conceptID)
}
```

Bài tập:

- Thêm nút "Open next concept" ở Dashboard toolbar.
- Thêm alert khi user mark concept completed.
- Thêm một sheet trong Concepts để hiển thị "About this category".

## 7. Collections

Danh sách là workflow cực phổ biến trong app iOS.

Xem:

- `ConceptsView.swift`
- `PracticeView.swift`

Khái niệm:

- `List`
- `Section`
- `ForEach`
- `.searchable`
- `.onDelete`
- `.onMove`
- `.swipeActions`
- filter/sort computed data

Trong Concepts, list được group theo `ConceptCategory`, có search, sort, filter, delete, swipe complete.

Bài tập:

- Thêm sort theo category.
- Thêm filter chỉ hiện `Intermediate`.
- Đổi swipe action delete thành confirmation dialog.

## 8. Forms Và Controls

Form là nơi bạn học nhiều controls nhất trong SwiftUI.

Xem:

- `PracticeView.swift`
- `SettingsView.swift`

Khái niệm:

- `Form`
- `TextField`
- `TextEditor`
- `Toggle`
- `Picker`
- `DatePicker`
- `Stepper`
- `Slider`
- `ColorPicker`
- `FocusState`

Trong Practice editor:

- Title dùng `TextField`.
- Concept dùng `Picker`.
- Due date dùng `DatePicker`.
- Priority dùng segmented `Picker`.
- Estimated minutes dùng cả `Stepper` và `Slider`.
- Validation dùng `.alert`.

Bài tập:

- Thêm field `notes` cho `PracticeTask`.
- Thêm `TextEditor` vào `PracticeEditorView`.
- Không cho save nếu estimated minutes dưới daily goal.

## 9. Async Và Lifecycle

SwiftUI cho phép gắn async work vào lifecycle của view.

Xem:

- `DashboardView.swift`
- `LearningStore.swift`
- `ConceptsView.swift`

Khái niệm:

- `.task`
- `.refreshable`
- loading state
- error state
- retry flow

Trong Dashboard:

```swift
.task {
    await store.loadDailyPrompt()
}
.refreshable {
    await store.refreshConcepts()
}
```

`LearningStore` có `ResourceState`:

- `idle`
- `loading`
- `loaded`
- `failed`

Bài tập:

- Tăng delay trong `loadDailyPrompt`.
- Thêm nút "Simulate success".
- Đổi UI loading từ `ProgressView` sang skeleton text.

## 10. Animation Và Gesture

Animation trong SwiftUI thường là kết quả của state change.

Xem:

- `SharedViews.swift`
- `DashboardView.swift`
- `ConceptsView.swift`

Khái niệm:

- implicit animation
- `withAnimation`
- `.transition`
- `@GestureState`
- `DragGesture`
- `onTapGesture`
- `onLongPressGesture`

Ví dụ:

- `ProgressRingShape` animate khi progress đổi.
- `GesturePracticeCard` đổi state khi tap/drag/long press.
- `ConceptDetailView` transition code block khi show/hide.

Bài tập:

- Đổi animation của progress ring sang `.easeInOut`.
- Thêm scale effect khi task được mark done.
- Thêm long press vào concept row để toggle completion.

## 11. Drawing Và Media

SwiftUI có thể vẽ shape custom và load ảnh từ mạng.

Xem:

- `SharedViews.swift`

Khái niệm:

- `Shape`
- `Path`
- `stroke`
- `AsyncImage`
- SF Symbols

Trong project:

- `ProgressRingShape` tự vẽ vòng progress.
- `RemoteSwiftUIImage` dùng `AsyncImage`.
- Các button/row dùng SF Symbols qua `Image(systemName:)`.

Bài tập:

- Tự viết `TriangleShape`.
- Đổi progress ring thành thanh ngang custom.
- Thêm placeholder riêng cho `AsyncImage`.

## 12. Accessibility Và Preview

SwiftUI app tốt nên dùng được với Dynamic Type, dark mode, VoiceOver.

Xem:

- `SharedViews.swift`
- `ContentView.swift`
- `DashboardView.swift`
- `ConceptsView.swift`

Khái niệm:

- `.accessibilityLabel`
- `.accessibilityValue`
- `.accessibilityHint`
- `.accessibilityElement(children:)`
- `#Preview`
- dark mode preview
- large Dynamic Type preview

Trong project:

- `ProgressRingView` có label/value riêng.
- `GesturePracticeCard` có hint.
- `ContentView` có preview large type.
- Dashboard có preview populated/loading/empty/error.

Bài tập:

- Mở VoiceOver trong Simulator và thử đi qua Dashboard.
- Thêm accessibility hint cho nút Reset sample data.
- Tạo preview cho Concepts empty state.

## 13. Thứ Tự Học Đề Xuất

Học theo thứ tự này để không bị loạn:

1. `smithApp.swift` và `ContentView.swift`: app entry, tab shell, app-wide state.
2. `Models.swift`: dữ liệu là gì.
3. `LearningStore.swift`: data flow và mutation.
4. `SharedViews.swift`: component nhỏ.
5. `DashboardView.swift`: layout, async, animation.
6. `ConceptsView.swift`: list, search, navigation, binding.
7. `PracticeView.swift`: form, sheet, validation, CRUD.
8. `SettingsView.swift`: persistence đơn giản bằng `@AppStorage`.

## 14. Mini Project Mở Rộng

Sau khi hiểu app hiện tại, làm các bài này:

1. **Add Notes To Practice**
   Thêm `notes` vào `PracticeTask`, hiển thị trong row, edit trong form.

2. **Add Concept Difficulty Filter**
   Thêm filter theo `Difficulty` trong Concepts.

3. **Persist User Progress**
   Lưu `concepts` và `practiceTasks` bằng JSON trong Documents hoặc chuyển sang SwiftData.

4. **Add Study Calendar**
   Thêm tab hoặc section hiển thị tasks theo ngày.

5. **Add Tests**
   Test `LearningStore`: progress calculation, add/update/delete task, reset sample data.

## 15. Checklist Bạn Nên Nắm Sau Project Này

- Biết view nào sở hữu state và view nào chỉ nhận data.
- Biết khi nào dùng `@State`, `@Binding`, `@Environment`, `@AppStorage`.
- Biết tạo list có search/filter/sort/delete/swipe.
- Biết mở detail screen bằng `NavigationStack`.
- Biết mở form bằng `.sheet`.
- Biết validate input bằng `.alert`.
- Biết dùng `.task` và `.refreshable` cho async work.
- Biết tạo animation từ state change.
- Biết viết component tái sử dụng.
- Biết thêm accessibility label/hint/value.
- Biết dùng preview để xem nhiều trạng thái UI.

Nếu bạn giải thích lại được data đi từ `LearningStore` tới từng tab như thế nào, bạn đã qua phần cốt lõi nhất của SwiftUI.
