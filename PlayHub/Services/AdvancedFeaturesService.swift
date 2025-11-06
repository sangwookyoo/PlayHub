import Foundation

class AdvancedFeaturesService {
    private let settingsManager: SettingsManager
    private let xcrunPath = "/usr/bin/xcrun"
    
    init(settingsManager: SettingsManager) {
        self.settingsManager = settingsManager
    }
    
    // MARK: - 배터리 시뮬레이션 (iOS 전용)
    
    func setBatteryLevel(udid: String, level: Int) async throws {
        let result = try CommandRunner.execute(xcrunPath, arguments: [
            "simctl", "status_bar", udid, "override",
            "--batteryLevel", "\(level)"
        ])
        guard result.isSuccess else {
            throw AppError.deviceCommandFailed("setBatteryLevel", underlying: result.stderr)
        }
    }
    
    func setBatteryState(udid: String, state: BatteryState) async throws {
        let stateString: String
        switch state {
        case .charging: stateString = "charging"
        case .discharging: stateString = "discharging"
        case .full: stateString = "charged"
        default: stateString = "discharging"
        }
        
        let result = try CommandRunner.execute(xcrunPath, arguments: [
            "simctl", "status_bar", udid, "override",
            "--batteryState", stateString
        ])
        guard result.isSuccess else {
            throw AppError.deviceCommandFailed("setBatteryState", underlying: result.stderr)
        }
    }
    
    func clearBatteryOverride(udid: String) async throws {
        let result = try CommandRunner.execute(xcrunPath, arguments: [
            "simctl", "status_bar", udid, "clear"
        ])
        guard result.isSuccess else {
            throw AppError.deviceCommandFailed("clearBatteryOverride", underlying: result.stderr)
        }
    }
    
    // MARK: - 화면 녹화 (iOS 전용)
    
    func startRecording(udid: String, outputPath: String) async throws {
    // 예) xcrun simctl io [udid] recordVideo [output.mp4]
        let result = try CommandRunner.execute(xcrunPath, arguments: [
            "simctl", "io", udid, "recordVideo", outputPath
        ])
        guard result.isSuccess else {
            throw AppError.deviceCommandFailed("startRecording", underlying: result.stderr)
        }
    }
    
    // MARK: - 푸시 알림 전송 (iOS 전용)
    
    func sendPushNotification(udid: String, bundleID: String, payload: PushPayload) async throws {
        // 임시 파일로 payload 저장
        let tempDir = FileManager.default.temporaryDirectory
        let payloadFile = tempDir.appendingPathComponent("push_\(UUID().uuidString).json")
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let data = try encoder.encode(payload)
        try data.write(to: payloadFile)
        
        defer {
            try? FileManager.default.removeItem(at: payloadFile)
        }
        
        let result = try CommandRunner.execute(xcrunPath, arguments: [
            "simctl", "push", udid, bundleID, payloadFile.path
        ])
        guard result.isSuccess else {
            throw AppError.deviceCommandFailed("sendPushNotification", underlying: result.stderr)
        }
    }
    
    // MARK: - 위치 시뮬레이션 (iOS 전용)
    
    func setLocation(udid: String, latitude: Double, longitude: Double) async throws {
        let result = try CommandRunner.execute(xcrunPath, arguments: [
            "simctl", "location", udid, "set",
            "\(latitude)", "\(longitude)"
        ])
        guard result.isSuccess else {
            throw AppError.deviceCommandFailed("setLocation", underlying: result.stderr)
        }
    }
    
    func clearLocation(udid: String) async throws {
        let result = try CommandRunner.execute(xcrunPath, arguments: [
            "simctl", "location", udid, "clear"
        ])
        guard result.isSuccess else {
            throw AppError.deviceCommandFailed("clearLocation", underlying: result.stderr)
        }
    }
}

// MARK: - 모델

enum BatteryState: String, Codable {
    case charging
    case discharging
    case full
    case unknown
}

struct PushPayload: Codable {
    let aps: APSPayload
    
    struct APSPayload: Codable {
        let alert: AlertPayload
        let badge: Int?
        let sound: String?
        
        struct AlertPayload: Codable {
            let title: String
            let body: String
            let subtitle: String?
        }
    }
}
