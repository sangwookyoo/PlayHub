import Foundation
import CryptoKit

// MARK: - Platform Service Models

/// Service 계층에서 사용하는 공통 모델들
/// Device, DeviceType, Runtime 등의 Service 전용 모델 정의
/// 사용자에게 노출되는 Device 모델과 구별

// MARK: - Device Type Models

/// 공통 디바이스 타입 인터페이스
protocol ServiceDeviceType: Identifiable, Codable {
    var identifier: String { get }
    var name: String { get }
    var displayName: String { get } // 사용자 친화적 이름
}

/// iOS 시뮤레이터 디바이스 타입
struct IOSDeviceType: ServiceDeviceType, Hashable {
    let identifier: String
    let name: String
    
    var id: String { identifier }
    
    var displayName: String {
        // "com.apple.CoreSimulator.SimDeviceType.iPhone-15-Pro" -> "iPhone 15 Pro"
        return ServiceModelUtils.extractIOSDeviceModel(identifier)
    }
    
    /// 디바이스 카테고리 분류
    var category: DeviceCategory {
        let lowerName = displayName.lowercased()
        if lowerName.contains("iphone") { return .phone }
        if lowerName.contains("ipad") { return .tablet }
        if lowerName.contains("watch") { return .watch }
        if lowerName.contains("tv") { return .tv }
        return .unknown
    }
}

/// Android AVD 디바이스 타입
struct AndroidDeviceType: ServiceDeviceType {
    let identifier: String // AVD 이름
    let name: String       // AVD 이름 (동일)
    let apiLevel: String   // API 레벨
    let deviceName: String // 실제 디바이스 이름
    
    var id: String { identifier }
    
    var displayName: String {
        if deviceName.isEmpty || deviceName == name {
            return "\(name) (\(apiLevel))"
        } else {
            return "\(deviceName) - \(name) (\(apiLevel))"
        }
    }
    
    /// 디바이스 카테고리 분류
    var category: DeviceCategory {
        let lowerDevice = deviceName.lowercased()
        let lowerName = name.lowercased()
        
        if lowerDevice.contains("phone") || lowerName.contains("phone") { return .phone }
        if lowerDevice.contains("tablet") || lowerName.contains("tablet") { return .tablet }
        if lowerDevice.contains("tv") || lowerName.contains("tv") { return .tv }
        if lowerDevice.contains("wear") || lowerName.contains("wear") { return .watch }
        return .phone // Android 기본은 폰
    }
}

/// 디바이스 카테고리 분류
enum DeviceCategory: String, CaseIterable {
    case phone = "phone"
    case tablet = "tablet"
    case watch = "watch"
    case tv = "tv"
    case unknown = "unknown"
    
    var displayName: String {
        switch self {
        case .phone: return "device.category.phone".loc()
        case .tablet: return "device.category.tablet".loc()
        case .watch: return "device.category.watch".loc()
        case .tv: return "device.category.tv".loc()
        case .unknown: return "device.category.unknown".loc()
        }
    }
    
    var icon: String {
        switch self {
        case .phone: return "iphone"
        case .tablet: return "ipad"
        case .watch: return "applewatch"
        case .tv: return "tv"
        case .unknown: return "questionmark.circle"
        }
    }
}

// MARK: - Runtime Models

/// 공통 런타임 인터페이스
protocol ServiceRuntime: Identifiable, Codable {
    var identifier: String { get }
    var name: String { get }
    var version: String { get }
    var isAvailable: Bool { get }
    var displayVersion: String { get } // 사용자 친화적 버전
}

/// iOS 런타임
struct IOSRuntime: ServiceRuntime {
    let identifier: String
    let name: String
    let version: String
    let isAvailable: Bool
    
    var id: String { identifier }
    
    var displayVersion: String {
        ServiceModelUtils.extractIOSVersion(from: identifier)
    }
    
    /// 런타임 카테고리
    var platformType: PlatformType {
        let lower = identifier.lowercased()
        if lower.contains("watchos") { return .watchOS }
        if lower.contains("tvos") { return .tvOS }
        return .iOS // 기본
    }
}

/// Android 런타임 (API 레벨 기반)
struct AndroidRuntime: ServiceRuntime {
    let identifier: String // API 레벨 숫자
    let name: String       // "API 33", "API 34" 등
    let version: String    // Android 버전
    let isAvailable: Bool
    
    var id: String { identifier }
    
    var displayVersion: String {
        "\(name) (Android \(version))"
    }
    
    var platformType: PlatformType {
        return .android
    }
    
    /// API 레벨에서 AndroidRuntime 생성
    static func fromAPILevel(_ apiLevel: String) -> AndroidRuntime {
        let cleanAPI = apiLevel.replacingOccurrences(of: "API ", with: "")
        let version = ServiceModelUtils.apiLevelToAndroidVersion(cleanAPI)
        
        return AndroidRuntime(
            identifier: cleanAPI,
            name: "API \(cleanAPI)",
            version: version,
            isAvailable: true
        )
    }
}

/// 플랫폼 타입 (Platform enum 확장 전까지 임시 사용)
enum PlatformType: String, CaseIterable {
    case iOS = "iOS"
    case android = "android"
    case watchOS = "watchOS"
    case tvOS = "tvOS"
    
    var displayName: String {
        switch self {
        case .iOS: return "iOS"
        case .android: return "Android"
        case .watchOS: return "watchOS"
        case .tvOS: return "tvOS"
        }
    }
    
    var icon: String {
        switch self {
        case .iOS: return "iphone"
        case .android: return "android"
        case .watchOS: return "applewatch"
        case .tvOS: return "tv"
        }
    }
}

// MARK: - Response Models

/// iOS 시뮤레이터 목록 응답
struct SimulatorListResponse: Codable {
    let devices: [String: [Simulator]]
}

/// iOS 시뮤레이터 상세 정보
struct Simulator: Codable {
    let udid: String
    let name: String
    let state: String
    let isAvailable: Bool
    let deviceTypeIdentifier: String
    
    /// Device 모델로 변환
    func toDevice(runtimeIdentifier: String? = nil) -> Device {
        let identifier = udid.isEmpty ? "\(name)-ios" : udid
        return Device(
            id: ServiceModelUtils.stableUUID(for: identifier),
            name: name,
            type: .iOS,
            udid: udid,
            state: ServiceModelUtils.mapDeviceState(state),
            isAvailable: isAvailable,
            osVersion: runtimeIdentifier.map { ServiceModelUtils.extractIOSVersion(from: $0) },
            deviceModel: ServiceModelUtils.extractIOSDeviceModel(deviceTypeIdentifier),
            attributes: [
                "deviceTypeIdentifier": deviceTypeIdentifier,
                "runtimeIdentifier": runtimeIdentifier ?? ""
            ]
        )
    }
}

/// iOS 디바이스 타입 응답
struct IOSDeviceTypeResponse: Codable {
    let devicetypes: [IOSDeviceType]
}

/// iOS 런타임 응답
struct IOSRuntimeResponse: Codable {
    let runtimes: [IOSRuntime]
}

/// Android 실행 중 에뮬레이터 정보
struct RunningEmulator {
    let serial: String
    let avdName: String
    let state: DeviceState
    let osVersion: String
    let model: String
    
    /// Device 모델로 변환
    func toDevice() -> Device {
        let identifier = serial.isEmpty ? "\(avdName)-android-running" : serial
        return Device(
            id: ServiceModelUtils.stableUUID(for: identifier),
            name: avdName,
            type: .android,
            udid: serial,
            state: state,
            isAvailable: true,
            osVersion: osVersion,
            deviceModel: model
        )
    }
}

/// Android AVD 정보
struct AVDInfo {
    let name: String
    let apiLevel: String
    let deviceName: String
    
    /// AndroidDeviceType으로 변환
    func toDeviceType() -> AndroidDeviceType {
        return AndroidDeviceType(
            identifier: name,
            name: name,
            apiLevel: apiLevel,
            deviceName: deviceName
        )
    }
    
    /// Device 모델로 변환 (shutdown 상태로)
    func toDevice() -> Device {
        return Device(
            id: ServiceModelUtils.stableUUID(for: "\(name)-android-avd"),
            name: name,
            type: .android,
            udid: nil, // AVD는 아직 실행 전
            state: .shutdown,
            isAvailable: true,
            osVersion: ServiceModelUtils.apiLevelToAndroidVersion(apiLevel),
            deviceModel: deviceName,
            attributes: [
                "apiLevel": apiLevel,
                "deviceName": deviceName
            ]
        )
    }
}

// MARK: - Advanced Features Models

/// 상태 막대 옵션 (공통화)
struct StatusBarOptions {
    let time: String?
    let batteryLevel: Int?
    let batteryState: String?
    
    /// iOS용 기본 옵션
    static var iOSDefault: StatusBarOptions {
        StatusBarOptions(
            time: "9:41",
            batteryLevel: 100,
            batteryState: "charged"
        )
    }
    
    /// Android용 기본 옵션
    static var androidDefault: StatusBarOptions {
        StatusBarOptions(
            time: "12:00",
            batteryLevel: 100,
            batteryState: "not_charging"
        )
    }
}

/// 위치 정보 모델
struct LocationOptions {
    let latitude: Double
    let longitude: Double
    let name: String?
    
    /// 주요 도시 프리셋
    static let presets: [LocationOptions] = [
        LocationOptions(latitude: 37.5665, longitude: 126.9780, name: "서울"),
        LocationOptions(latitude: 35.6762, longitude: 139.6503, name: "도쿄"),
        LocationOptions(latitude: 40.7128, longitude: -74.0060, name: "뉴욕"),
        LocationOptions(latitude: 37.7749, longitude: -122.4194, name: "샌프란시스코"),
        LocationOptions(latitude: 51.5074, longitude: -0.1278, name: "런던"),
    ]
}

/// 녹화 옵션
struct RecordingOptions {
    let outputPath: String
    let format: VideoFormat
    let quality: VideoQuality
    
    enum VideoFormat: String, CaseIterable {
        case mp4 = "mp4"
        case mov = "mov"
        
        var displayName: String {
            switch self {
            case .mp4: return "MP4 (Universal)"
            case .mov: return "MOV (QuickTime)"
            }
        }
    }
    
    enum VideoQuality: String, CaseIterable {
        case low = "low"
        case medium = "medium"
        case high = "high"
        
        var displayName: String {
            switch self {
            case .low: return "Low (720p)"
            case .medium: return "Medium (1080p)"
            case .high: return "High (4K)"
            }
        }
    }
}



// MARK: - Service Model Utilities

/// Service 모델 관련 유틸리티 기능들
struct ServiceModelUtils {
    
    // MARK: - Identifier Utilities
    
    /// Generate a deterministic UUID from a string identifier.
    /// Ensures device identities remain stable across refreshes.
    static func stableUUID(for identifier: String) -> UUID {
        let normalized = identifier.lowercased()
        let hash = SHA256.hash(data: Data(normalized.utf8))
        let bytes = Array(hash.prefix(16))
        guard bytes.count == 16 else {
            return UUID()
        }
        let uuid = uuid_t(
            bytes[0], bytes[1], bytes[2], bytes[3],
            bytes[4], bytes[5], bytes[6], bytes[7],
            bytes[8], bytes[9], bytes[10], bytes[11],
            bytes[12], bytes[13], bytes[14], bytes[15]
        )
        return UUID(uuid: uuid)
    }
    
    // MARK: - Version Extraction
    
    /// iOS 런타임 식별자에서 버전 추출
    /// - Parameter runtime: "com.apple.CoreSimulator.SimRuntime.iOS-17-0"
    /// - Returns: "iOS 17.0"
    static func extractIOSVersion(from runtime: String) -> String {
        let cleaned = runtime
            .replacingOccurrences(of: "com.apple.CoreSimulator.SimRuntime.", with: "")
        
        // iOS-17-0 -> iOS 17.0 변환
        if cleaned.hasPrefix("iOS-") {
            let version = String(cleaned.dropFirst(4)) // "17-0"
            return formatAppleOSVersion("iOS", version)
        }
        
        // watchOS-10-0 -> watchOS 10.0
        if cleaned.hasPrefix("watchOS-") {
            let version = String(cleaned.dropFirst(8)) // "10-0"
            return formatAppleOSVersion("watchOS", version)
        }
        
        // tvOS-17-0 -> tvOS 17.0
        if cleaned.hasPrefix("tvOS-") {
            let version = String(cleaned.dropFirst(5)) // "17-0"
            return formatAppleOSVersion("tvOS", version)
        }
        
        // Fallback: 기본 정리
        return cleaned.replacingOccurrences(of: "-", with: ".")
    }
    
    /// Apple OS 버전 포맷팅 공통 로직
    private static func formatAppleOSVersion(_ osName: String, _ version: String) -> String {
        let versionComponents = version.split(separator: "-")
        
        if versionComponents.count >= 2 {
            let major = versionComponents[0]
            let minor = versionComponents[1]
            if versionComponents.count > 2 {
                let patch = versionComponents[2]
                return "\(osName) \(major).\(minor).\(patch)"
            } else {
                return "\(osName) \(major).\(minor)"
            }
        } else {
            let formatted = version.replacingOccurrences(of: "-", with: ".")
            return "\(osName) \(formatted)"
        }
    }
    
    /// API 레벨에서 Android 버전 추정
    /// - Parameter apiLevel: "33", "34" 등
    /// - Returns: "13.0", "14.0" 등
    static func apiLevelToAndroidVersion(_ apiLevel: String) -> String {
        guard let api = Int(apiLevel) else { return "Unknown" }
        
        // 주요 API 레벨 -> Android 버전 매핑
        let versionMap: [Int: String] = [
            35: "15.0",   // Android 15
            34: "14.0",   // Android 14
            33: "13.0",   // Android 13
            32: "12.1",   // Android 12L
            31: "12.0",   // Android 12
            30: "11.0",   // Android 11
            29: "10.0",   // Android 10
            28: "9.0",    // Android 9
            27: "8.1",    // Android 8.1
            26: "8.0",    // Android 8.0
            25: "7.1",    // Android 7.1
            24: "7.0",    // Android 7.0
        ]
        
        return versionMap[api] ?? "\(Double(api - 19) + 4.4)" // 추정 매핑
    }
    
    /// Android AVD 이름에서 API 레벨 추출
    /// - Parameter avdName: "Pixel_7_API_33", "Galaxy_S24_API_34" 등
    /// - Returns: "API 33", "API 34" 등
    static func extractAPIFromAVDName(_ avdName: String) -> String {
        // AVD 이름 패턴 분석
        let patterns = [
            "API_\\d+",      // API_33, API_34 등
            "api\\d+",       // api33, api34 등 (소문자)
            "Android\\d+",   // Android33, Android34 등
            "\\d+",          // 숫자만 (예: 33, 34)
        ]
        
        for pattern in patterns {
            if let range = avdName.range(of: pattern, options: .regularExpression) {
                let match = String(avdName[range])
                // 숫자 부분만 추출
                let digits = match.filter { $0.isNumber }
                if !digits.isEmpty {
                    return "API \(digits)"
                }
            }
        }
        
        // 모든 패턴 실패시 기본값
        return "Android"
    }
    
    // MARK: - State Mapping
    
    /// 문자열 상태를 DeviceState로 매핑
    /// - Parameter state: "booted", "shutdown" 등
    /// - Returns: 표준화된 DeviceState
    static func mapDeviceState(_ state: String) -> DeviceState {
        switch state.lowercased() {
        case "booted":
            return .booted
        case "shutdown":
            return .shutdown
        case "booting":
            return .booting
        case "shutting down":
            return .shutting_down
        default:
            return .unknown
        }
    }
    
    // MARK: - Device Model Extraction
    
    /// iOS 디바이스 타입 식별자에서 모델 이름 추출
    /// - Parameter deviceTypeIdentifier: "com.apple.CoreSimulator.SimDeviceType.iPhone-15-Pro"
    /// - Returns: "iPhone 15 Pro"
    static func extractIOSDeviceModel(_ deviceTypeIdentifier: String) -> String {
        return deviceTypeIdentifier
            .replacingOccurrences(of: "com.apple.CoreSimulator.SimDeviceType.", with: "")
            .replacingOccurrences(of: "-", with: " ")
    }
    
    /// Android AVD config.ini에서 디바이스 모델 정보 추출
    /// - Parameters:
    ///   - configContent: config.ini 파일 내용
    ///   - avdName: AVD 이름 (fallback용)
    /// - Returns: (apiLevel, deviceName)
    static func parseAVDConfig(configContent: String, avdName: String) -> (apiLevel: String, deviceName: String) {
        var apiLevel = "Android"
        var deviceName = avdName
        var targetAPI: String?
        
        // 설정 파일의 각 라인을 분석
        configContent.components(separatedBy: .newlines).forEach { line in
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            
            // API 레벨 추출 방법 1: image.sysdir.1 경로에서
            if trimmed.hasPrefix("image.sysdir.1=") {
                // 예: image.sysdir.1=system-images/android-33/google_apis/arm64-v8a/
                if let range = trimmed.range(of: "android-\\d+", options: .regularExpression) {
                    let extracted = String(trimmed[range])
                    targetAPI = extracted.replacingOccurrences(of: "android-", with: "")
                }
            }
            // API 레벨 추출 방법 2: target 속성에서
            else if trimmed.hasPrefix("target=") {
                // 예: target=android-33
                let targetValue = trimmed.replacingOccurrences(of: "target=", with: "")
                if targetValue.hasPrefix("android-") {
                    targetAPI = targetValue.replacingOccurrences(of: "android-", with: "")
                }
            }
            // 디바이스 이름 추출
            else if trimmed.hasPrefix("hw.device.name=") {
                deviceName = trimmed.replacingOccurrences(of: "hw.device.name=", with: "")
                    .replacingOccurrences(of: "_", with: " ")
            }
        }
        
        // API 레벨 최종 결정
        if let api = targetAPI, !api.isEmpty {
            apiLevel = "API \(api)"
        } else {
            // config.ini에서 추출 실패시 AVD 이름에서 추출
            apiLevel = extractAPIFromAVDName(avdName)
        }
        
        return (apiLevel, deviceName)
    }
}

// MARK: - Device Model Extensions

/// Device 모델 확장 (변환 편의 메서드)
extension Device {
    
    /// Simulator에서 Device로 변환
    static func from(simulator: Simulator) -> Device {
        simulator.toDevice()
    }
    
    /// RunningEmulator에서 Device로 변환
    static func from(runningEmulator: RunningEmulator) -> Device {
        runningEmulator.toDevice()
    }
    
    /// AVDInfo에서 Device로 변환
    static func from(avdInfo: AVDInfo) -> Device {
        avdInfo.toDevice()
    }
}
