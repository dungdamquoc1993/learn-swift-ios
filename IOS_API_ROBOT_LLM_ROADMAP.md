# iOS API Roadmap Cho Robot Và Local LLM

Tài liệu này nối tiếp phần SwiftUI/UI/state/lifecycle. Mục tiêu không phải học architecture cho đẹp, mà là hiểu **iOS app có thể làm việc với thế giới bên ngoài và chính thiết bị như thế nào**.

Với background web/backend, phần external API chỉ cần học đủ cách Swift làm. Phần quan trọng hơn là internal iOS API: storage, permission, networking cục bộ, Bluetooth, background task, audio, camera, sensor, và local inference.

## 0. Cách Nghĩ Tổng Quan

Trong app iOS, chữ "API" có thể hiểu thành 3 nhóm:

- **External API**: backend, REST, GraphQL, OpenAI API, server của robot, cloud service.
- **iOS Internal API**: framework của Apple để nói chuyện với hệ điều hành và phần cứng như file system, location, camera, Bluetooth, notification, audio, sensor.
- **App API nội bộ**: interface do mình tự thiết kế giữa các phần trong app, ví dụ `ModelStore`, `RobotClient`, `ChatEngine`.

Ở giai đoạn này không cần quá nặng service layer. Chỉ cần nhớ flow cơ bản:

```text
SwiftUI View
  -> user action / lifecycle event
  -> async work
  -> update state
  -> UI render lại
```

Async work đó có thể là gọi backend, tải file, xin quyền iOS, gửi lệnh tới robot, hoặc chạy model local.

## Phase 1: Swift Client Basics Và File Download

Mục tiêu: hiểu Swift/iOS làm external API và file download như thế nào.

Đây là phase ngắn, vì các concept client/backend đã quen rồi. Cái cần học là cách Swift biểu diễn chúng.

### Cần Nắm

- `URLSession` để gọi HTTP.
- `async/await` để xử lý async flow.
- `Codable` để decode/encode JSON.
- GET/POST, headers, auth token.
- Loading/success/error state trong SwiftUI.
- Download file lớn bằng `URLSessionDownloadTask` hoặc API tương đương.
- Progress, retry, resume download.
- Validate file sau khi tải: size, checksum, version.

### Vì Sao Phase Này Quan Trọng

Local LLM dưới 1GB vẫn là file lớn với mobile app. Nút "Download model" không chỉ là gọi API lấy JSON, mà là một workflow:

```text
Tap Download
  -> request metadata
  -> check disk space
  -> start download
  -> show progress
  -> support pause/retry/resume
  -> verify checksum
  -> move file vào storage ổn định
  -> mark model ready
```

### Kết Quả Mong Muốn

Sau phase này, app nên làm được:

- Gọi một public API đơn giản.
- Decode JSON vào Swift model.
- Tải một file giả lập lớn.
- Hiển thị progress.
- Lưu trạng thái model: `notDownloaded`, `downloading`, `ready`, `failed`.

## Phase 2: iOS Internal API Và Device Capability

Mục tiêu: hiểu iOS cho app quyền làm gì trên thiết bị, giới hạn ở đâu, và permission/lifecycle ảnh hưởng như thế nào.

Đây là phần quan trọng nhất nếu muốn đi về robot.

### Storage

Các vùng lưu trữ cần phân biệt:

- `Documents`: file user có thể coi là tài liệu của app.
- `Application Support`: dữ liệu nội bộ quan trọng của app, hợp với model local.
- `Caches`: dữ liệu có thể bị iOS xóa khi thiếu dung lượng.
- `tmp`: file tạm, không đảm bảo tồn tại lâu.
- `UserDefaults`: preference nhỏ, không dành cho file lớn.
- Keychain: token/secret nhỏ, cần bảo mật.

Với model LLM khoảng dưới 1GB, hướng hợp lý thường là:

```text
Application Support
  /Models
    /model-name
      model.gguf hoặc model.mlmodelc
      metadata.json
```

Không nên để model quan trọng trong `Caches`, vì iOS có thể dọn.

### Permission

iOS không cho app tự do đụng mọi thứ. Nhiều capability cần xin quyền:

- Local network.
- Bluetooth.
- Microphone.
- Camera.
- Photos.
- Location.
- Speech recognition.
- Notifications.

Mỗi permission thường có 3 phần:

```text
Info.plist description
  -> request permission runtime
  -> handle authorized / denied / restricted
```

### Networking Cục Bộ

Cho robot, external API không chỉ là internet. Có thể là robot trong cùng mạng LAN.

Cần biết:

- Gọi HTTP tới IP robot trong LAN.
- WebSocket để stream trạng thái/lệnh.
- TCP/UDP nếu protocol custom.
- Bonjour để discover device trong mạng cục bộ.
- Local Network permission.
- Network framework nếu cần kiểm soát sâu hơn `URLSession`.

### Bluetooth Và Robot Communication

Nếu robot dùng BLE:

- Scan device.
- Connect/disconnect.
- Discover services/characteristics.
- Read/write characteristic.
- Subscribe notify/indicate để nhận stream data.
- Reconnect logic.
- Background mode nếu cần giữ kết nối trong một số trường hợp.

Điểm cần nhớ: BLE không giống HTTP. Nó giống một protocol nhỏ, mình phải tự thiết kế command/state format rất rõ.

### Audio, Camera, Sensor

Cho robot/LLM assistant, các capability dễ cần tới:

- `AVFoundation`: microphone, audio playback, camera capture.
- Speech/Text-to-Speech: nhập/xuất bằng giọng nói.
- `Vision`: xử lý ảnh/camera frame.
- `CoreMotion`: accelerometer, gyroscope, magnetometer, device motion, altimeter, pedometer, motion activity.
- Location nếu robot cần context vị trí.

#### Core Motion Lab (đã implement trong app)

App hiện tập trung vào [Core Motion](https://developer.apple.com/documentation/CoreMotion) trước:

| Lab | API | Ghi chú |
|-----|-----|---------|
| Device Motion | `CMDeviceMotion`, `CMAttitude` | Spirit level, processed gravity/user acceleration |
| Accelerometer | `CMAccelerometerData` | Raw values, includes gravity |
| Gyroscope | `CMGyroData` | Rotation rate |
| Magnetometer | `CMMagnetometerData` | Magnetic field µT |
| Altimeter | `CMAltimeter` | Barometric relative altitude |
| Pedometer | `CMPedometer` | Steps, distance — cần `NSMotionUsageDescription` |
| Motion Activity | `CMMotionActivityManager` | walking/running/stationary — cùng motion permission |
| Unsupported APIs | reference only | Headphone motion, Watch Ultra submersion, fall detection, movement disorder, `CMSensorRecorder` |

Pattern chung: `MotionManagerService` start/stop trong `.onAppear` / `.onDisappear`, UI đọc `@Observable` model.

Code nằm trong `smith/CoreMotion/` (tạm comment khỏi `ContentView` khi học tiếp).

#### Core ML Lab — Vision + Sound + Speech (đã implement)

App hiện học [Core ML](https://developer.apple.com/documentation/CoreML) qua 3 lab dùng **built-in model của Apple**, không bundle `.mlmodel` tùy chỉnh:

| Lab | Framework | API | Input |
|-----|-----------|-----|-------|
| Vision | Vision | `VNClassifyImageRequest` | PhotosPicker |
| Sound | SoundAnalysis | `SNClassifySoundRequest` | Microphone |
| Speech | Speech | `SFSpeechRecognizer` | Microphone |

Permission cần thêm:

- `NSMicrophoneUsageDescription` — Sound + Speech
- `NSSpeechRecognitionUsageDescription` — Speech

Chưa cover ở giai đoạn này: NLP/tabular/custom model/LLM chat.

Code nằm trong `smith/CoreML/`, entry point `CoreMLHubView`.

#### AVFoundation Lab — Hardware Demos (đã implement)

App học [AVFoundation](https://developer.apple.com/documentation/AVFoundation) qua mic, loa, và camera:

| Lab | API | Hardware |
|-----|-----|----------|
| Audio Session | `AVAudioSession` | Speaker route, mic sharing |
| Audio Playback | `AVAudioPlayer` | Speaker / headphones |
| Audio Recording | `AVAudioRecorder` | Microphone |
| Camera Preview | `AVCaptureSession` | Camera |
| Photo Capture | `AVCapturePhotoOutput` | Camera shutter |
| Video Recording | `AVCaptureMovieFileOutput` + `AVPlayer` | Camera + mic |
| Reference | read-only | AirPlay, depth, editing, DRM |

Permission:

- `NSCameraUsageDescription` — camera labs
- `NSMicrophoneUsageDescription` — recording + video (đã có từ Core ML)

CoreML Sound/Speech đã dùng `AVAudioEngine`; AVFoundation labs cover record/play/capture file đầy đủ hơn.

Code nằm trong `smith/AVFoundation/`, entry point `AVFoundationHubView`.

#### Core Bluetooth Lab (đã implement)

App học [Core Bluetooth](https://developer.apple.com/documentation/CoreBluetooth) qua central + peripheral simulator:

| Lab | API | Vai trò |
|-----|-----|---------|
| Central | `CBCentralManager`, `CBPeripheralDelegate` | Scan, connect, discover GATT, read/write/notify |
| Peripheral Simulator | `CBPeripheralManager` | Advertise custom StudySmith service |
| Reference | read-only | Roles, GATT, testing with Mac mini |

Permission: `NSBluetoothAlwaysUsageDescription`.

Test flow: chạy Peripheral trên iPhone, Central trên iPhone thứ hai hoặc nRF Connect trên Mac mini.

Code nằm trong `smith/CoreBluetooth/`, entry point `CoreBluetoothHubView`.

### Lifecycle Và Background

iOS rất nghiêm với background:

- App foreground thì làm được nhiều nhất.
- App background bị giới hạn thời gian chạy.
- Long-running task không được tự do như server.
- Background download có support riêng.
- BLE có background mode nhưng vẫn có giới hạn.
- Inference local nên giả định chủ yếu chạy khi app active.

### Kết Quả Mong Muốn

Sau phase này, app nên có các mini lab:

- Lưu/xóa/check file trong Application Support.
- Xin permission notification hoặc microphone.
- Gọi một endpoint trong LAN hoặc mock robot server.
- Demo WebSocket hoặc BLE nếu có thiết bị.
- Hiểu lúc app vào background thì task nào còn chạy, task nào nên pause.

## Phase 3: Robot Control Và Local LLM Runtime

Mục tiêu: ghép các capability lại thành hướng sản phẩm thật: app tải model, chạy chat local, rồi dùng kết quả để điều khiển robot.

Phase này không còn là học API lẻ nữa, mà là thiết kế runtime nhỏ trong app.

### Local Model Lifecycle

Model local nên có lifecycle rõ:

```text
notInstalled
  -> downloading
  -> verifying
  -> installed
  -> loading
  -> ready
  -> running
  -> unloading
  -> updateAvailable
  -> failed
```

Các việc cần quản lý:

- Version model.
- Disk usage.
- Checksum.
- Delete model.
- Update model.
- Load/unload để giảm RAM.
- Handle memory pressure.
- Handle thermal/battery.

### Runtime LLM

Tùy format model, có vài hướng:

- Core ML nếu model convert được và phù hợp Apple stack.
- Runtime kiểu `llama.cpp` nếu dùng GGUF hoặc model local phổ biến.
- Metal/MPS/custom runtime nếu cần tối ưu sâu.

Điểm cần học ở app level:

- Chạy inference ngoài main thread.
- Stream token về UI.
- Cancel generation.
- Giữ chat history vừa đủ, tránh phình RAM.
- Không block UI khi model đang nghĩ.
- Hiển thị trạng thái rõ: loading model, generating, stopped, error.

### Robot Command Layer

LLM không nên được phép bắn lệnh raw lung tung thẳng tới robot. Nên có một lớp command an toàn:

```text
User prompt
  -> LLM reasoning / intent
  -> validated command
  -> robot client
  -> robot response / telemetry
  -> UI update
```

Ví dụ command nên là structured:

```json
{
  "action": "move_forward",
  "durationMs": 800,
  "speed": 0.3
}
```

Không nên để model tự sinh string tùy ý kiểu `"go fast somewhere"` rồi gửi thẳng xuống robot.

### Safety Và Control

Robot cần safety layer, kể cả app chỉ là prototype:

- Command whitelist.
- Limit speed/duration.
- Emergency stop.
- Require confirmation cho hành động nguy hiểm.
- Timeout nếu mất kết nối.
- Telemetry heartbeat.
- Manual override.
- Log command để debug.

### Kết Quả Mong Muốn

Sau phase này, app nên làm được:

- Download/install/delete local model.
- Mở chat local với model.
- Stream response token lên UI.
- Parse response thành command có schema.
- Gửi command tới robot mock hoặc robot thật.
- Nhận trạng thái robot và render lại UI.
- Có nút emergency stop/manual control.

## Roadmap 3 Phase Gọn

```text
Phase 1: Swift client basics
  External API, JSON, async/await, download file, progress, retry.

Phase 2: iOS capability map
  Storage, permission, local network, BLE, audio/camera/sensor, lifecycle/background.

Phase 3: Robot + local LLM
  Model management, inference runtime, command schema, robot client, safety layer.
```

## Thứ Tự Học Đề Xuất Trong Project Này

1. **Core Motion Lab** (trong `CoreMotion/`): device motion, accel, gyro, magnetometer, altimeter, pedometer, motion activity.
2. **Core ML Lab** (trong `CoreML/`): Vision image classification, ambient sound classification, speech-to-text.
3. **AVFoundation Lab** (trong `AVFoundation/`): audio session, playback, recording, camera preview, photo, video.
4. **Core Bluetooth Lab** (đang active trong `CoreBluetooth/`): BLE central scanner + peripheral simulator.
5. Thêm màn hình `Storage Lab`: download file giả, lưu vào Application Support, xóa file.
6. Thêm màn hình `API Lab`: gọi API public, decode JSON, show loading/error.
7. Thêm màn hình `Permissions Lab`: notification/microphone/local network.
8. Thêm màn hình `Robot Lab`: mock robot client qua HTTP/WebSocket.
9. Thêm màn hình `Model Lab`: model state machine, download/install/delete.
10. Cuối cùng mới ghép `Chat + Robot Control`.

## Nguyên Tắc Giữ Cho Project Không Bị Cồng Kềnh

- Ban đầu viết trực tiếp, dễ đọc, ít abstraction.
- Khi một logic dùng lại 2-3 nơi thì mới tách service/helper.
- UI chỉ cần biết state: loading, ready, failed, progress.
- Logic quan trọng nên có state machine rõ.
- File lớn phải có metadata/version/checksum.
- Robot command phải structured và có safety gate.

## Mental Model Cuối Cùng

App iOS trong dự án robot/local LLM không chỉ là client gọi backend.

Nó là:

```text
UI controller
  + device capability gateway
  + local storage manager
  + local inference node
  + robot command console
```

Học external API là để biết app nói chuyện với server như thế nào. Học internal iOS API là để biết app có thể tận dụng thiết bị tới đâu. Với hướng robot, phần internal iOS API mới là phần mở khóa khả năng thật sự.
