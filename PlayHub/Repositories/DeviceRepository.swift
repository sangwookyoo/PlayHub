
import Foundation

/// DeviceRepository에서 제공하는 기능을 정의하는 프로토콜
protocol DeviceRepositoryProtocol {
    /// 디바이스 목록을 조회합니다
    /// - Parameter forceRefresh: 캐시를 무시하고 강제로 새로고침할지 여부
    /// - Returns: 디바이스 배열
    /// - Throws: 디바이스 조회 실패 시 에러
    func fetchDevices(forceRefresh: Bool) async throws -> [Device]
    
    /// 지정된 디바이스를 부팅합니다
    /// - Parameter device: 부팅할 디바이스
    /// - Throws: 부팅 실패 시 에러
    func boot(_ device: Device) async throws
    
    /// 지정된 디바이스를 종료합니다
    /// - Parameter device: 종료할 디바이스
    /// - Throws: 종료 실패 시 에러
    func shutdown(_ device: Device) async throws

    /// 지정된 디바이스를 재시작합니다
    /// - Parameter device: 재시작할 디바이스
    /// - Throws: 재시작 실패 시 에러
    func restart(_ device: Device) async throws
    
    /// 지정된 디바이스를 삭제합니다 (Android AVD만)
    /// - Parameter device: 삭제할 디바이스
    /// - Throws: 삭제 실패 시 에러
    func delete(_ device: Device) async throws
    
    /// 지정된 디바이스의 현재 상태를 조회합니다
    /// - Parameter device: 상태를 확인할 디바이스
    /// - Returns: 디바이스 상태 정보
    /// - Throws: 상태 조회 실패 시 에러
    func status(of device: Device) async throws -> DeviceStatus

    /// 배터리 상태를 시뮬레이션합니다
    func applyBattery(_ device: Device, level: Int, isCharging: Bool) async throws
    
    /// 위치를 시뮬레이션합니다
    func applyLocation(_ device: Device, latitude: Double, longitude: Double) async throws
    
    /// 앱을 설치합니다 (.app 또는 .apk)
    func installApp(_ device: Device, from artifactPath: String) async throws -> Device
}

/// DeviceService를 사용하여 디바이스 데이터를 관리하는 리포지토리 구현체
final class DeviceRepository: DeviceRepositoryProtocol {
    
    // MARK: - Private Properties
    
    private let deviceService: DeviceServiceProtocol
    
    private var cachedDevices: [Device] = []
    private var lastCacheUpdate: Date?
    private let cacheValidityInterval: TimeInterval = 5.0
    
    // MARK: - Initialization
    
    init(service: DeviceServiceProtocol) {
        self.deviceService = service
    }
    
    // MARK: - DeviceRepositoryProtocol Implementation
    
    func fetchDevices(forceRefresh: Bool = false) async throws -> [Device] {
        if !forceRefresh && isCacheValid() {
            #if DEBUG
            print("📦 Using cached devices (\(cachedDevices.count) devices)")
            #endif
            return cachedDevices
        }
        
        #if DEBUG
        print("🔍 Fetching devices from service...")
        #endif
        
        let allDevices = try await deviceService.listDevices()
        
        cachedDevices = allDevices
        lastCacheUpdate = Date()
        
        #if DEBUG
        print("✅ Device fetch complete: \(allDevices.count) total")
        #endif
        
        return allDevices
    }
    
    func boot(_ device: Device) async throws {
        try await deviceService.boot(device: device)
        invalidateCache()
    }
    
    func shutdown(_ device: Device) async throws {
        try await deviceService.shutdown(device: device)
        invalidateCache()
    }

    func restart(_ device: Device) async throws {
        try await deviceService.restart(device: device)
        invalidateCache()
    }
    
    func delete(_ device: Device) async throws {
        try await deviceService.delete(device: device)
        invalidateCache()
    }
    
    func status(of device: Device) async throws -> DeviceStatus {
        return try await deviceService.getStatus(of: device)
    }
    
    func applyBattery(_ device: Device, level: Int, isCharging: Bool) async throws {
        try await deviceService.applyBattery(device: device, level: level, isCharging: isCharging)
    }
    
    func applyLocation(_ device: Device, latitude: Double, longitude: Double) async throws {
        try await deviceService.applyLocation(device: device, latitude: latitude, longitude: longitude)
    }
    
    func installApp(_ device: Device, from artifactPath: String) async throws -> Device {
        let updatedDevice = try await deviceService.installApp(device: device, artifactPath: artifactPath)
        
        if let index = cachedDevices.firstIndex(where: { $0.id == updatedDevice.id }) {
            cachedDevices[index] = updatedDevice
        } else {
            cachedDevices.append(updatedDevice)
        }
        lastCacheUpdate = Date()
        
        return updatedDevice
    }
    
    // MARK: - Private Methods
    
    private func isCacheValid() -> Bool {
        guard let lastUpdate = lastCacheUpdate else { return false }
        return Date().timeIntervalSince(lastUpdate) < cacheValidityInterval
    }
    
    private func invalidateCache() {
        lastCacheUpdate = nil
        
        #if DEBUG
        print("🗑️ Device cache invalidated")
        #endif
    }
}
