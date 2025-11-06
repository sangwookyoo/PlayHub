
// Trigger clean build
import Foundation
import Combine

@MainActor
final class DeviceDetailViewModel: BaseViewModel {
    
    // MARK: - Published Properties
    
    @Published var device: Device
    
    // MARK: - Private Properties
    
    private let deviceRepository: DeviceRepositoryProtocol
    private let coordinator: AppCoordinator
    
    // MARK: - Initialization
    
    init(device: Device, deviceRepository: DeviceRepositoryProtocol, coordinator: AppCoordinator) {
        self.device = device
        self.deviceRepository = deviceRepository
        self.coordinator = coordinator
        super.init()
    }
    
    // MARK: - Public Methods
    
    func bootDevice() async {
        print("Booting device: \(device.name)")
        await executeWithState {
            try await self.deviceRepository.boot(self.device)
            await self.refreshDeviceStatus()
        }
    }
    
    func shutdownDevice() async {
        print("Shutting down device: \(device.name)")
        await executeWithState {
            try await self.deviceRepository.shutdown(self.device)
            await self.refreshDeviceStatus()
        }
    }
    
    func restartDevice() async {
        print("Restarting device: \(device.name)")
        await executeWithState {
            try await self.deviceRepository.restart(self.device)
            await self.refreshDeviceStatus()
        }
    }
    
    func deleteDevice() async {
        await executeWithState {
            try await self.deviceRepository.delete(self.device)
            coordinator.requestDeviceRefresh()
        }
    }
    
    func applyBattery(level: Int, isCharging: Bool) async throws {
        do {
            try await deviceRepository.applyBattery(device, level: level, isCharging: isCharging)
        } catch {
            throw mapError(error)
        }
    }
    
    func applyLocation(latitude: Double, longitude: Double) async throws {
        do {
            try await deviceRepository.applyLocation(device, latitude: latitude, longitude: longitude)
        } catch {
            throw mapError(error)
        }
    }
    
    func installApp(from artifactPath: String) async throws {
        do {
            let updatedDevice = try await deviceRepository.installApp(device, from: artifactPath)
            device = updatedDevice
            coordinator.requestDeviceRefresh()
        } catch {
            throw mapError(error)
        }
    }
    
    func refreshDeviceStatus() async {
        await executeWithState(isRefresh: true) {
            let status = try await self.deviceRepository.status(of: self.device)
            self.device.state = status.state
            coordinator.requestDeviceRefresh()
        }
    }
    
    private func mapError(_ error: Error) -> AppError {
        if let appError = error as? AppError {
            return appError
        }
        return .unknown(error.localizedDescription)
    }
}
