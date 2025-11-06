import Foundation

// MARK: - 플랫폼

enum Platform: String, Codable, CaseIterable {
    case iOS
    case android
    
    var displayName: String {
        switch self {
        case .iOS: return "platform.ios".loc()
        case .android: return "platform.android".loc()
        }
    }
    
    var iconName: String {
        switch self {
        case .iOS: return "applelogo"
        case .android: return "circle.hexagongrid.fill"
        }
    }
}

// MARK: - 디바이스 상태

enum DeviceState: String, Codable {
    case booted
    case shutdown
    case booting
    case shutting_down  // Fixed: consistent naming
    case unknown
    
    var localizedKey: String {
        switch self {
        case .booted: return "state.booted"
        case .shutdown: return "state.shutdown"
        case .booting: return "state.booting"
        case .shutting_down: return "state.shutting_down"
        case .unknown: return "state.unknown"
        }
    }
}

// MARK: - 디바이스

/// 디바이스 정보를 나타내는 모델
struct Device: Identifiable, Codable, Equatable, Hashable {
    let id: UUID
    let name: String
    let type: Platform
    let udid: String?
    var state: DeviceState
    let isAvailable: Bool
    let osVersion: String?
    let deviceModel: String?
    let attributes: [String: String]
    
    /// 새로운 Device 인스턴스를 생성합니다
    /// - Parameters:
    ///   - id: 고유 식별자
    ///   - name: 디바이스 이름
    ///   - type: 플랫폼 타입 (iOS/Android)
    ///   - udid: 디바이스 UDID (옵션)
    ///   - state: 현재 상태
    ///   - isAvailable: 사용 가능 여부
    init(
        id: UUID,
        name: String,
        type: Platform,
        udid: String? = nil,
        state: DeviceState,
        isAvailable: Bool = true,
        osVersion: String? = nil,
        deviceModel: String? = nil,
        attributes: [String: String] = [:]
    ) {
        self.id = id
        self.name = name
        self.type = type
        self.udid = udid
        self.state = state
        self.isAvailable = isAvailable
        self.osVersion = osVersion
        self.deviceModel = deviceModel
        self.attributes = attributes
    }
    
    static func == (lhs: Device, rhs: Device) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// MARK: - 디바이스 상태 정보

/// 디바이스 상태 정보를 나타내는 모델
struct DeviceStatus: Codable, Equatable {
    let state: DeviceState
    let lastUpdated: Date
    let additionalInfo: [String: String]
    
    /// 새로운 DeviceStatus 인스턴스를 생성합니다
    /// - Parameters:
    ///   - state: 디바이스 상태
    ///   - lastUpdated: 마지막 업데이트 시간
    ///   - additionalInfo: 추가 정보 딕셔너리
    init(state: DeviceState, lastUpdated: Date = Date(), additionalInfo: [String: String] = [:]) {
        self.state = state
        self.lastUpdated = lastUpdated
        self.additionalInfo = additionalInfo
    }
}

// MARK: - 디바이스 오류

enum DeviceError: LocalizedError {
    case notFound
    case alreadyRunning
    case commandFailed(String)
    case parsingFailed(String)
    case timeout
    case invalidConfiguration
    case permissionDenied
    
    var errorDescription: String? {
        switch self {
        case .notFound:
            return "device.error.notfound".loc()
        case .alreadyRunning:
            return "device.error.alreadyrunning".loc()
        case .commandFailed(let message):
            return "device.error.commandfailed".loc() + ": \(message)"
        case .parsingFailed(let message):
            return "device.error.parsingfailed".loc() + ": \(message)"
        case .timeout:
            return "device.error.timeout".loc()
        case .invalidConfiguration:
            return "device.error.invalidconfig".loc()
        case .permissionDenied:
            return "device.error.permission".loc()
        }
    }
}

// MARK: - 시스템 검사

struct SystemCheck {
    let isInstalled: Bool
    let version: String
    let path: String
    let message: String
}

// MARK: - 시스템 요구사항

struct SystemRequirements {
    let xcodeInstalled: SystemCheck
    let simctlAvailable: SystemCheck
    let androidStudioInstalled: SystemCheck
    let adbAvailable: SystemCheck
    let emulatorAvailable: SystemCheck
    let avdConfigured: SystemCheck
    
    var allRequirementsMet: Bool {
        return hasIOS && hasAndroid
    }
    
    var hasIOS: Bool {
        return xcodeInstalled.isInstalled && simctlAvailable.isInstalled
    }
    
    var hasAndroid: Bool {
        return adbAvailable.isInstalled && emulatorAvailable.isInstalled
    }
}
