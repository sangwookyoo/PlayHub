#if os(macOS)
import AppKit
#endif
import SwiftUI
import Combine

@MainActor
final class CreateDeviceViewModel: ObservableObject {
    @Published var selectedPlatform: Platform = .iOS
    @Published var deviceName = ""
    @Published var selectedDeviceType: DeviceType?
    @Published var selectedRuntime: Runtime?
    @Published var isCreating = false
    @Published var showError = false
    @Published var errorMessage = ""
    @Published var availableDeviceTypes: [DeviceType] = []
    @Published var availableRuntimes: [Runtime] = []
    
    private let iosService: IOSService
    private let deviceRepository: DeviceRepositoryProtocol
    
    init(
        iosService: IOSService = DependencyContainer.shared.resolve(type: PlatformService.self, name: "iOS")! as! IOSService,
        deviceRepository: DeviceRepositoryProtocol = DependencyContainer.shared.makeDeviceRepository()
    ) {
        self.iosService = iosService
        self.deviceRepository = deviceRepository
    }
    
    var canCreate: Bool {
        if selectedPlatform == .iOS {
            return !deviceName.isEmpty && selectedDeviceType != nil && selectedRuntime != nil
        }
        return false
    }
    
    func loadIOSOptions() async {
        do {
            let deviceTypes = try await iosService.listDeviceTypes()
            let runtimes = try await iosService.listRuntimes()
            
            self.availableDeviceTypes = deviceTypes.map { DeviceType(identifier: $0.identifier, name: $0.displayName) }
            self.availableRuntimes = runtimes.map { Runtime(identifier: $0.identifier, name: $0.displayVersion) }
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
    
    func createDevice() async -> Bool {
        guard !deviceName.isEmpty,
              let selectedDeviceType = selectedDeviceType,
              let selectedRuntime = selectedRuntime else {
            errorMessage = "Please fill in all fields"
            showError = true
            return false
        }
        
        isCreating = true
        
        do {
            _ = try await iosService.createSimulator(name: deviceName, deviceTypeId: selectedDeviceType.identifier, runtimeId: selectedRuntime.identifier)
            
            _ = try await deviceRepository.fetchDevices(forceRefresh: true)
            isCreating = false
            return true
        } catch {
            errorMessage = error.localizedDescription
            showError = true
            isCreating = false
            return false
        }
    }
    
    func openAndroidStudio() {
#if os(macOS)
        let url = URL(fileURLWithPath: "/Applications/Android Studio.app")
        NSWorkspace.shared.open(url)
#endif
    }
}

struct DeviceType: Identifiable, Hashable {
    let id = UUID()
    let identifier: String
    let name: String
    
    init(identifier: String, name: String) {
        self.identifier = identifier
        self.name = name
    }
}

struct Runtime: Identifiable, Hashable {
    let id = UUID()
    let identifier: String
    let name: String
    
    init(identifier: String, name: String) {
        self.identifier = identifier
        self.name = name
    }
}
