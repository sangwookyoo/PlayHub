import Foundation

final class SwinjectDependencyContainer {
    static let shared = SwinjectDependencyContainer()

    private var services: [String: Any] = [:]

    private init() {
        registerServices()
        registerViewModels()
        registerManagers()
    }

    private func registerServices() {
        register(type: SettingsManager.self, instance: SettingsManager())
        register(type: PlatformService.self, name: "iOS") {
            IOSService(settingsManager: self.resolve(type: SettingsManager.self)!)
        }
        register(type: PlatformService.self, name: "Android") {
            AndroidService(settingsManager: self.resolve(type: SettingsManager.self)!)
        }
        register(type: DeviceServiceProtocol.self) {
            let iosService = self.resolve(type: PlatformService.self, name: "iOS")!
            let androidService = self.resolve(type: PlatformService.self, name: "Android")!
            return DeviceService(platformServices: [iosService, androidService])
        }
        register(type: DeviceRepositoryProtocol.self) {
            DeviceRepository(service: self.resolve(type: DeviceServiceProtocol.self)!)
        }
    }

    private func registerViewModels() {
        register(type: DeviceListViewModel.self) {
            DeviceListViewModel(deviceRepository: self.resolve(type: DeviceRepositoryProtocol.self)!)
        }
    }

    private func registerManagers() {
        register(type: LocalizationManager.self, instance: LocalizationManager.shared)
        register(type: ThemeManager.self, instance: ThemeManager.shared)
    }

    private func register<T>(type: T.Type, name: String? = nil, instance: Any) {
        let key = name.map { "\(type)-\($0)" } ?? "\(type)"
        services[key] = instance
    }

    private func register<T>(type: T.Type, name: String? = nil, factory: @escaping () -> Any) {
        let key = name.map { "\(type)-\($0)" } ?? "\(type)"
        services[key] = factory
    }
    
    private func register<T, Arg1>(type: T.Type, name: String? = nil, factory: @escaping (Arg1) -> Any) {
        let key = name.map { "\(type)-\($0)" } ?? "\(type)"
        services[key] = factory
    }

    func resolve<T>(type: T.Type, name: String? = nil) -> T? {
        let key = name.map { "\(type)-\($0)" } ?? "\(type)"
        if let service = services[key] {
            if let factory = service as? () -> Any {
                return factory() as? T
            }
            return service as? T
        }
        return nil
    }
    
    func resolve<T, Arg1>(type: T.Type, name: String? = nil, argument: Arg1) -> T? {
        let key = name.map { "\(type)-\($0)" } ?? "\(type)"
        if let service = services[key] {
            if let factory = service as? (Arg1) -> Any {
                return factory(argument) as? T
            }
        }
        return nil
    }

    func makeDeviceRepository() -> DeviceRepositoryProtocol {
        return resolve(type: DeviceRepositoryProtocol.self)!
    }

    func makeDeviceListViewModel() -> DeviceListViewModel {
        return resolve(type: DeviceListViewModel.self)!
    }

    func makeDeviceDetailViewModel(device: Device, coordinator: AppCoordinator) -> DeviceDetailViewModel {
        let repository = resolve(type: DeviceRepositoryProtocol.self)!
        return DeviceDetailViewModel(device: device, deviceRepository: repository, coordinator: coordinator)
    }

    var settingsManager: SettingsManager {
        return resolve(type: SettingsManager.self)!
    }

    var localizationManager: LocalizationManager {
        return resolve(type: LocalizationManager.self)!
    }

    var themeManager: ThemeManager {
        return resolve(type: ThemeManager.self)!
    }
}
