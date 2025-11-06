
import Foundation

/// 각 플랫폼(iOS, Android 등)의 디바이스 서비스를 추상화하는 공통 프로토콜입니다.
/// 이 프로토콜은 새로운 플랫폼을 쉽게 추가하고, DeviceService가 플랫폼에 독립적으로 작동하도록 지원합니다.
protocol PlatformService {
    /// 이 서비스가 담당하는 플랫폼 타입입니다.
    var platformType: Platform { get }

    /// 해당 플랫폼의 모든 디바이스 목록을 비동기적으로 가져옵니다.
    /// - Returns: `Device` 객체의 배열을 반환합니다.
    /// - Throws: 디바이스 목록을 가져오는 데 실패하면 에러를 발생시킵니다.
    func listDevices() async throws -> [Device]

    /// 지정된 디바이스를 부팅합니다.
    /// - Parameter device: 부팅할 `Device` 객체입니다.
    /// - Throws: 부팅 과정에서 오류가 발생하면 에러를 발생시킵니다.
    func boot(device: Device) async throws

    /// 지정된 디바이스를 종료합니다.
    /// - Parameter device: 종료할 `Device` 객체입니다.
    /// - Throws: 종료 과정에서 오류가 발생하면 에러를 발생시킵니다.
    func shutdown(device: Device) async throws

    /// 지정된 디바이스를 재시작합니다.
    /// - Parameter device: 재시작할 `Device` 객체입니다.
    /// - Throws: 재시작 과정에서 오류가 발생하면 에러를 발생시킵니다.
    func restart(device: Device) async throws

    /// 지정된 디바이스를 삭제합니다. (지원되는 경우)
    /// - Parameter device: 삭제할 `Device` 객체입니다.
    /// - Throws: 삭제 과정에서 오류가 발생하면 에러를 발생시킵니다.
    func delete(device: Device) async throws

    /// 지정된 디바이스의 상태 정보를 가져옵니다.
    /// - Parameter device: 상태를 조회할 `Device` 객체입니다.
    /// - Returns: `DeviceStatus` 객체를 반환합니다.
    /// - Throws: 상태 조회 중 오류가 발생하면 에러를 발생시킵니다.
    func getStatus(of device: Device) async throws -> DeviceStatus
    
    /// 배터리 상태를 시뮬레이션합니다.
    func applyBattery(device: Device, level: Int, isCharging: Bool) async throws
    
    /// 위치를 시뮬레이션합니다.
    func applyLocation(device: Device, latitude: Double, longitude: Double) async throws
    
    /// 앱을 설치합니다.
    func installApp(device: Device, artifactPath: String) async throws -> Device
}

// MARK: - 기본 구현

extension PlatformService {
    /// 기본 재시작 구현: 종료 후 부팅
    func restart(device: Device) async throws {
        try await shutdown(device: device)
        // 플랫폼별로 적절한 대기 시간을 가질 수 있도록 약간의 지연을 줍니다.
        try await Task.sleep(nanoseconds: 2_000_000_000)
        try await boot(device: device)
    }

    /// 기본 삭제 구현: 대부분의 플랫폼에서 지원하지 않으므로 기본적으로 에러를 발생시킵니다.
    func delete(device: Device) async throws {
        throw AppError.unsupportedFeature("Delete is not supported on this platform.")
    }
    
    func applyBattery(device: Device, level: Int, isCharging: Bool) async throws {
        throw AppError.unsupportedFeature("Battery simulation is not supported on this platform.")
    }
    
    func applyLocation(device: Device, latitude: Double, longitude: Double) async throws {
        throw AppError.unsupportedFeature("Location simulation is not supported on this platform.")
    }
    
    func installApp(device: Device, artifactPath: String) async throws -> Device {
        throw AppError.unsupportedFeature("App installation is not supported on this platform.")
    }
}
