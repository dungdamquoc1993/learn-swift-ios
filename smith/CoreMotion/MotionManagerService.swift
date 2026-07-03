import CoreMotion
import Foundation

@MainActor
final class MotionManagerService {
    static let shared = MotionManagerService()

    private let motionManager = CMMotionManager()
    private let updateInterval = 1.0 / 30.0

    private var deviceMotionHandler: ((DeviceMotionSample) -> Void)?
    private var accelerometerHandler: ((Vector3Sample) -> Void)?
    private var gyroscopeHandler: ((Vector3Sample) -> Void)?
    private var magnetometerHandler: ((Vector3Sample) -> Void)?

    private init() {
        motionManager.deviceMotionUpdateInterval = updateInterval
        motionManager.accelerometerUpdateInterval = updateInterval
        motionManager.gyroUpdateInterval = updateInterval
        motionManager.magnetometerUpdateInterval = updateInterval
    }

    var isAccelerometerAvailable: Bool { motionManager.isAccelerometerAvailable }
    var isGyroAvailable: Bool { motionManager.isGyroAvailable }
    var isDeviceMotionAvailable: Bool { motionManager.isDeviceMotionAvailable }
    var isMagnetometerAvailable: Bool { motionManager.isMagnetometerAvailable }

    func startDeviceMotion(onUpdate: @escaping (DeviceMotionSample) -> Void) {
        stopAllMotionStreams()
        guard isDeviceMotionAvailable else { return }

        deviceMotionHandler = onUpdate
        motionManager.startDeviceMotionUpdates(to: .main) { [weak self] motion, _ in
            guard let self, let motion else { return }
            self.deviceMotionHandler?(DeviceMotionSample(motion))
        }
    }

    func startAccelerometer(onUpdate: @escaping (Vector3Sample) -> Void) {
        stopAllMotionStreams()
        guard isAccelerometerAvailable else { return }

        accelerometerHandler = onUpdate
        motionManager.startAccelerometerUpdates(to: .main) { [weak self] data, _ in
            guard let self, let data else { return }
            self.accelerometerHandler?(Vector3Sample(data.acceleration))
        }
    }

    func startGyroscope(onUpdate: @escaping (Vector3Sample) -> Void) {
        stopAllMotionStreams()
        guard isGyroAvailable else { return }

        gyroscopeHandler = onUpdate
        motionManager.startGyroUpdates(to: .main) { [weak self] data, _ in
            guard let self, let data else { return }
            self.gyroscopeHandler?(Vector3Sample(data.rotationRate))
        }
    }

    func startMagnetometer(onUpdate: @escaping (Vector3Sample) -> Void) {
        stopAllMotionStreams()
        guard isMagnetometerAvailable else { return }

        magnetometerHandler = onUpdate
        motionManager.startMagnetometerUpdates(to: .main) { [weak self] data, _ in
            guard let self, let data else { return }
            self.magnetometerHandler?(Vector3Sample(data.magneticField))
        }
    }

    func stopAll() {
        stopAllMotionStreams()
    }

    private func stopAllMotionStreams() {
        if motionManager.isDeviceMotionActive {
            motionManager.stopDeviceMotionUpdates()
        }
        if motionManager.isAccelerometerActive {
            motionManager.stopAccelerometerUpdates()
        }
        if motionManager.isGyroActive {
            motionManager.stopGyroUpdates()
        }
        if motionManager.isMagnetometerActive {
            motionManager.stopMagnetometerUpdates()
        }

        deviceMotionHandler = nil
        accelerometerHandler = nil
        gyroscopeHandler = nil
        magnetometerHandler = nil
    }
}
