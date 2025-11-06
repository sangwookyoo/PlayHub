
import Foundation
import Combine

@MainActor
final class DeviceListViewModel: BaseViewModel {
    
    // MARK: - Published Properties
    
    @Published var devices: [Device] = []
    @Published var filterType: Platform? = nil
    @Published var searchText: String = ""
    
    // MARK: - Private Properties
    
    private let deviceRepository: DeviceRepositoryProtocol
    
    // MARK: - Initialization
    
    init(deviceRepository: DeviceRepositoryProtocol) {
        self.deviceRepository = deviceRepository
        super.init()
    }
    
    // MARK: - Public Methods
    
    func refreshDevices(force: Bool = false) async {
        await executeWithState(isRefresh: force) {
            self.devices = try await self.deviceRepository.fetchDevices(forceRefresh: force)
        }
    }
    
    // MARK: - Filtering and Search
    
    var filteredDevices: [Device] {
        return devices
            .filter { matches(platform: filterType, device: $0) && matchesSearch(for: $0) }
            .sorted { $0.name < $1.name }
    }
    
    func count(for platform: Platform?) -> Int {
        devices.filter { matches(platform: platform, device: $0) && matchesSearch(for: $0) }.count
    }
    
    private func matches(platform: Platform?, device: Device) -> Bool {
        guard let platform else { return true }
        return device.type == platform
    }
    
    private func matchesSearch(for device: Device) -> Bool {
        guard !searchText.isEmpty else { return true }
        let searchLower = searchText.lowercased()
        if device.name.lowercased().contains(searchLower) {
            return true
        }
        if let udid = device.udid?.lowercased(), udid.contains(searchLower) {
            return true
        }
        return false
    }
}
