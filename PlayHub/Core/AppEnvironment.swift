import Foundation

@MainActor
protocol AppEnvironmentProtocol {
    var container: DependencyContainer { get }
    var settings: SettingsManager { get }
    var localization: LocalizationManager { get }
    var theme: ThemeManager { get }
    var coordinator: AppCoordinator { get }
    
    func makeDeviceListViewModel() -> DeviceListViewModel
    func makeDeviceDetailViewModel(device: Device) -> DeviceDetailViewModel
    func makeDeviceRepository() -> DeviceRepositoryProtocol
}

@MainActor
final class AppEnvironment: AppEnvironmentProtocol {
    @MainActor static let shared = AppEnvironment(container: .shared, coordinator: AppCoordinator())
    
    let container: DependencyContainer
    let coordinator: AppCoordinator
    
    init(container: DependencyContainer, coordinator: AppCoordinator) {
        self.container = container
        self.coordinator = coordinator
    }
    
    var settings: SettingsManager {
        container.settingsManager
    }
    
    var localization: LocalizationManager {
        container.localizationManager
    }
    
    var theme: ThemeManager {
        container.themeManager
    }
    
    func makeDeviceListViewModel() -> DeviceListViewModel {
        container.makeDeviceListViewModel()
    }
    
    func makeDeviceDetailViewModel(device: Device) -> DeviceDetailViewModel {
        container.makeDeviceDetailViewModel(device: device, coordinator: coordinator)
    }
    
    func makeDeviceRepository() -> DeviceRepositoryProtocol {
        container.makeDeviceRepository()
    }
}
