
import Foundation

/// 디바이스 서비스 기능을 정의하는 프로토콜
/// iOS Simulator와 Android Emulator 상호작용을 추삽화
protocol DeviceServiceProtocol {
    /// 사용 가능한 모든 디바이스 목록을 조회합니다
    /// - Returns: 디바이스 배열
    /// - Throws: 디바이스 조회 실패 시 에러
    func listDevices() async throws -> [Device]
    
    /// 지정된 디바이스를 부팅합니다
    /// - Parameter device: 부팅할 디바이스
    /// - Throws: 부팅 실패 시 에러
    func boot(device: Device) async throws
    
    /// 지정된 디바이스를 종료합니다
    /// - Parameter device: 종료할 디바이스
    /// - Throws: 종료 실패 시 에러
    func shutdown(device: Device) async throws

    /// 지정된 디바이스를 재시작합니다
    /// - Parameter device: 재시작할 디바이스
    /// - Throws: 재시작 실패 시 에러
    func restart(device: Device) async throws

    /// 지정된 디바이스를 삭제합니다
    /// - Parameter device: 삭제할 디바이스
    /// - Throws: 삭제 실패 시 에러
    func delete(device: Device) async throws
    
    /// 지정된 디바이스의 현재 상태를 조회합니다
    /// - Parameter device: 상태를 확인할 디바이스
    /// - Returns: 디바이스 상태 정보
    /// - Throws: 상태 조회 실패 시 에러
    func getStatus(of device: Device) async throws -> DeviceStatus
    
    /// 배터리 상태를 시뮬레이션합니다
    func applyBattery(device: Device, level: Int, isCharging: Bool) async throws
    
    /// 위치를 시뮬레이션합니다
    func applyLocation(device: Device, latitude: Double, longitude: Double) async throws
    
    /// 앱을 설치합니다 (.app/.apk 등)
    func installApp(device: Device, artifactPath: String) async throws -> Device
}

/// 통합 디바이스 서비스 — 중복 제거로 간소화
/// PlatformService 프로토콜을 준수하는 서비스들을 사용하여 통합 인터페이스를 제공합니다
final class DeviceService: DeviceServiceProtocol {
    
    // MARK: - 의존성
    
    private let platformServices: [PlatformService]
    
    // MARK: - 초기화

    /// 초기화
    /// - Parameter platformServices: 플랫폼 서비스 배열
    init(platformServices: [PlatformService]) {
        self.platformServices = platformServices
        #if DEBUG
        print("🔧 DeviceService initialized with \(platformServices.count) platform services")
        #endif
    }

    // MARK: - DeviceServiceProtocol 구현
    
    func listDevices() async throws -> [Device] {
        var allDevices: [Device] = []
        
        try await withThrowingTaskGroup(of: [Device].self) { group in
            for service in platformServices {
                group.addTask {
                    return try await service.listDevices()
                }
            }
            
            for try await devices in group {
                allDevices.append(contentsOf: devices)
            }
        }
        
        return allDevices.sorted { $0.name < $1.name }
    }

    func boot(device: Device) async throws {
        guard let service = service(for: device.type) else {
            throw AppError.unsupportedFeature("Boot is not supported for this platform.")
        }
        try await service.boot(device: device)
    }

    func shutdown(device: Device) async throws {
        guard let service = service(for: device.type) else {
            throw AppError.unsupportedFeature("Shutdown is not supported for this platform.")
        }
        try await service.shutdown(device: device)
    }

    func restart(device: Device) async throws {
        guard let service = service(for: device.type) else {
            throw AppError.unsupportedFeature("Restart is not supported for this platform.")
        }
        try await service.restart(device: device)
    }

    func delete(device: Device) async throws {
        guard let service = service(for: device.type) else {
            throw AppError.unsupportedFeature("Delete is not supported for this platform.")
        }
        try await service.delete(device: device)
    }

    func getStatus(of device: Device) async throws -> DeviceStatus {
        guard let service = service(for: device.type) else {
            throw AppError.unsupportedFeature("Get status is not supported for this platform.")
        }
        return try await service.getStatus(of: device)
    }
    
    func applyBattery(device: Device, level: Int, isCharging: Bool) async throws {
        guard let service = service(for: device.type) else {
            throw AppError.unsupportedFeature("Battery simulation is not supported for this platform.")
        }
        try await service.applyBattery(device: device, level: level, isCharging: isCharging)
    }
    
    func applyLocation(device: Device, latitude: Double, longitude: Double) async throws {
        guard let service = service(for: device.type) else {
            throw AppError.unsupportedFeature("Location simulation is not supported for this platform.")
        }
        try await service.applyLocation(device: device, latitude: latitude, longitude: longitude)
    }
    
    func installApp(device: Device, artifactPath: String) async throws -> Device {
        guard let service = service(for: device.type) else {
            throw AppError.unsupportedFeature("App installation is not supported for this platform.")
        }
        return try await service.installApp(device: device, artifactPath: artifactPath)
    }

    private func service(for platform: Platform) -> PlatformService? {
        return platformServices.first { $0.platformType == platform }
    }
}
