import CoreMotion
import Foundation

enum MotionLab: String, CaseIterable, Identifiable, Hashable {
    case deviceMotion
    case accelerometer
    case gyroscope
    case magnetometer
    case altimeter
    case pedometer
    case motionActivity
    case unsupportedAPIs

    var id: String { rawValue }

    var title: String {
        switch self {
        case .deviceMotion: "Device Motion"
        case .accelerometer: "Accelerometer"
        case .gyroscope: "Gyroscope"
        case .magnetometer: "Magnetometer"
        case .altimeter: "Altimeter"
        case .pedometer: "Pedometer"
        case .motionActivity: "Motion Activity"
        case .unsupportedAPIs: "Unsupported APIs"
        }
    }

    var subtitle: String {
        switch self {
        case .deviceMotion: "CMDeviceMotion, CMAttitude — processed, gravity removed"
        case .accelerometer: "CMAccelerometerData — raw x/y/z including gravity"
        case .gyroscope: "CMGyroData — raw rotation rate"
        case .magnetometer: "CMMagnetometerData — magnetic field µT"
        case .altimeter: "CMAltimeter — barometric relative altitude"
        case .pedometer: "CMPedometer — step count and distance"
        case .motionActivity: "CMMotionActivityManager — walking, running, stationary"
        case .unsupportedAPIs: "Watch, headphone, and legacy APIs"
        }
    }

    var systemImage: String {
        switch self {
        case .deviceMotion: "level.fill"
        case .accelerometer: "move.3d"
        case .gyroscope: "rotate.3d"
        case .magnetometer: "location.north.line.fill"
        case .altimeter: "arrow.up.and.down"
        case .pedometer: "figure.walk"
        case .motionActivity: "figure.run"
        case .unsupportedAPIs: "info.circle"
        }
    }

    var isAvailable: Bool {
        switch self {
        case .deviceMotion:
            MotionManagerService.shared.isDeviceMotionAvailable
        case .accelerometer:
            MotionManagerService.shared.isAccelerometerAvailable
        case .gyroscope:
            MotionManagerService.shared.isGyroAvailable
        case .magnetometer:
            MotionManagerService.shared.isMagnetometerAvailable
        case .altimeter:
            CMAltimeter.isRelativeAltitudeAvailable()
        case .pedometer:
            CMPedometer.isStepCountingAvailable()
        case .motionActivity:
            CMMotionActivityManager.isActivityAvailable()
        case .unsupportedAPIs:
            true
        }
    }

    var isDemoLab: Bool {
        self != .unsupportedAPIs
    }
}

enum MotionAuthorizationStatus: Equatable {
    case notDetermined
    case authorized
    case denied
    case restricted
    case unavailable

    var title: String {
        switch self {
        case .notDetermined: "Not Determined"
        case .authorized: "Authorized"
        case .denied: "Denied"
        case .restricted: "Restricted"
        case .unavailable: "Unavailable"
        }
    }

    static func from(_ status: CMAuthorizationStatus) -> MotionAuthorizationStatus {
        switch status {
        case .notDetermined: .notDetermined
        case .authorized: .authorized
        case .denied: .denied
        case .restricted: .restricted
        @unknown default: .unavailable
        }
    }
}

struct Vector3Sample: Equatable {
    var x: Double
    var y: Double
    var z: Double

    static let zero = Vector3Sample(x: 0, y: 0, z: 0)

    init(x: Double, y: Double, z: Double) {
        self.x = x
        self.y = y
        self.z = z
    }

    init(_ vector: CMAcceleration) {
        self.x = vector.x
        self.y = vector.y
        self.z = vector.z
    }

    init(_ vector: CMRotationRate) {
        self.x = vector.x
        self.y = vector.y
        self.z = vector.z
    }

    init(_ vector: CMMagneticField) {
        self.x = vector.x
        self.y = vector.y
        self.z = vector.z
    }

    func formatted(axis: String, unit: String, precision: Int = 3) -> String {
        String(format: "%@: %.\(precision)f %@", axis, x, unit)
    }

    var xFormatted: String { String(format: "%.3f", x) }
    var yFormatted: String { String(format: "%.3f", y) }
    var zFormatted: String { String(format: "%.3f", z) }
}

struct AttitudeSample: Equatable {
    var pitch: Double
    var roll: Double
    var yaw: Double

    static let zero = AttitudeSample(pitch: 0, roll: 0, yaw: 0)

    init(pitch: Double, roll: Double, yaw: Double) {
        self.pitch = pitch
        self.roll = roll
        self.yaw = yaw
    }

    init(_ attitude: CMAttitude) {
        self.pitch = attitude.pitch
        self.roll = attitude.roll
        self.yaw = attitude.yaw
    }

    var pitchDegrees: Double { pitch * 180 / .pi }
    var rollDegrees: Double { roll * 180 / .pi }
    var yawDegrees: Double { yaw * 180 / .pi }
}

struct DeviceMotionSample: Equatable {
    var attitude: AttitudeSample
    var rotationRate: Vector3Sample
    var gravity: Vector3Sample
    var userAcceleration: Vector3Sample

    static let zero = DeviceMotionSample(
        attitude: .zero,
        rotationRate: .zero,
        gravity: .zero,
        userAcceleration: .zero
    )

    init(
        attitude: AttitudeSample,
        rotationRate: Vector3Sample,
        gravity: Vector3Sample,
        userAcceleration: Vector3Sample
    ) {
        self.attitude = attitude
        self.rotationRate = rotationRate
        self.gravity = gravity
        self.userAcceleration = userAcceleration
    }

    init(_ motion: CMDeviceMotion) {
        self.attitude = AttitudeSample(motion.attitude)
        self.rotationRate = Vector3Sample(motion.rotationRate)
        self.gravity = Vector3Sample(motion.gravity)
        self.userAcceleration = Vector3Sample(motion.userAcceleration)
    }
}

struct AltitudeSample: Equatable {
    var relativeAltitude: Double
    var pressure: Double

    init(relativeAltitude: Double, pressure: Double) {
        self.relativeAltitude = relativeAltitude
        self.pressure = pressure
    }

    init(_ data: CMAltitudeData) {
        self.relativeAltitude = data.relativeAltitude.doubleValue
        self.pressure = data.pressure.doubleValue
    }
}

struct PedometerSample: Equatable {
    var steps: Int
    var distanceMeters: Double?
    var floorsAscended: Int?
    var floorsDescended: Int?

    init(steps: Int, distanceMeters: Double?, floorsAscended: Int?, floorsDescended: Int?) {
        self.steps = steps
        self.distanceMeters = distanceMeters
        self.floorsAscended = floorsAscended
        self.floorsDescended = floorsDescended
    }

    init?(_ data: CMPedometerData) {
        self.steps = data.numberOfSteps.intValue
        self.distanceMeters = data.distance?.doubleValue
        self.floorsAscended = data.floorsAscended?.intValue
        self.floorsDescended = data.floorsDescended?.intValue
    }
}

struct ActivitySample: Equatable {
    var stationary: Bool
    var walking: Bool
    var running: Bool
    var automotive: Bool
    var cycling: Bool
    var unknown: Bool
    var confidence: CMMotionActivityConfidence

    static let idle = ActivitySample(
        stationary: false,
        walking: false,
        running: false,
        automotive: false,
        cycling: false,
        unknown: true,
        confidence: .low
    )

    init(_ activity: CMMotionActivity) {
        self.stationary = activity.stationary
        self.walking = activity.walking
        self.running = activity.running
        self.automotive = activity.automotive
        self.cycling = activity.cycling
        self.unknown = activity.unknown
        self.confidence = activity.confidence
    }

    init(
        stationary: Bool,
        walking: Bool,
        running: Bool,
        automotive: Bool,
        cycling: Bool,
        unknown: Bool,
        confidence: CMMotionActivityConfidence
    ) {
        self.stationary = stationary
        self.walking = walking
        self.running = running
        self.automotive = automotive
        self.cycling = cycling
        self.unknown = unknown
        self.confidence = confidence
    }

    var primaryLabel: String {
        if walking { return "Walking" }
        if running { return "Running" }
        if automotive { return "Automotive" }
        if cycling { return "Cycling" }
        if stationary { return "Stationary" }
        if unknown { return "Unknown" }
        return "Idle"
    }

    var confidenceLabel: String {
        switch confidence {
        case .low: "Low"
        case .medium: "Medium"
        case .high: "High"
        @unknown default: "Unknown"
        }
    }
}

struct UnsupportedMotionAPI: Identifiable {
    let id: String
    let name: String
    let platform: String
    let summary: String
}

extension UnsupportedMotionAPI {
    static let catalog: [UnsupportedMotionAPI] = [
        UnsupportedMotionAPI(
            id: "headphone",
            name: "CMHeadphoneMotionManager",
            platform: "Compatible headphones",
            summary: "Tracks head motion from supported AirPods and Beats. Requires paired hardware."
        ),
        UnsupportedMotionAPI(
            id: "submersion",
            name: "CMWaterSubmersionManager",
            platform: "Apple Watch Ultra",
            summary: "Reports water pressure, temperature, and depth during submersion."
        ),
        UnsupportedMotionAPI(
            id: "fall",
            name: "CMFallDetectionManager",
            platform: "Apple Watch",
            summary: "Detects hard falls. Requires NSFallDetectionUsageDescription and watchOS."
        ),
        UnsupportedMotionAPI(
            id: "movement-disorder",
            name: "CMMovementDisorderManager",
            platform: "Apple Watch",
            summary: "Records tremor and dyskinetic symptom data for clinical research workflows."
        ),
        UnsupportedMotionAPI(
            id: "sensor-recorder",
            name: "CMSensorRecorder",
            platform: "Legacy iOS devices",
            summary: "Records raw accelerometer batches for later playback. Largely superseded by other APIs."
        ),
    ]
}
