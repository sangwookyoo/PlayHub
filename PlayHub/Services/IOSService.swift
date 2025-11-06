
import Foundation

final class IOSService: PlatformService {
    var platformType: Platform { .iOS }
    
    private let settings: SettingsManager
    
    init(settingsManager: SettingsManager) {
        self.settings = settingsManager
    }
    
    func listDevices() async throws -> [Device] {
        let xcrunPath = Self.detectXcrunPath()
        
        guard CommandRunner.isExecutable(xcrunPath) else {
            throw AppError.configurationError("xcrun을 찾을 수 없습니다.")
        }
        
        do {
            let result = try await CommandRunner.executeAsync(
                xcrunPath,
                arguments: ["simctl", "list", "devices", "-j"]
            )
            
            guard let data = result.data(using: .utf8) else {
                throw AppError.formatError("simctl에서 잘못된 UTF-8 출력을 반환했습니다.")
            }
            
            let response = try JSONDecoder().decode(SimulatorListResponse.self, from: data)
            var devices: [Device] = []
            
            for (runtimeKey, simulators) in response.devices {
                for simulator in simulators {
                    devices.append(simulator.toDevice(runtimeIdentifier: runtimeKey))
                }
            }
            
            return devices.sorted { $0.name < $1.name }
            
        } catch {
            throw IOSErrorMapper.toAppError(error)
        }
    }

    func boot(device: Device) async throws {
        guard let udid = device.udid else {
            throw AppError.invalidInput("부팅하려면 기기 UDID가 필요합니다.")
        }
        try await bootSimulator(udid: udid)
    }

    func shutdown(device: Device) async throws {
        guard let udid = device.udid else {
            throw AppError.invalidInput("종료하려면 기기 UDID가 필요합니다.")
        }
        try await shutdownSimulator(udid: udid)
    }

    func delete(device: Device) async throws {
        guard let udid = device.udid else {
            throw AppError.invalidInput("삭제하려면 기기 UDID가 필요합니다.")
        }
        try await deleteSimulator(udid: udid)
    }

    func getStatus(of device: Device) async throws -> DeviceStatus {
        guard let udid = device.udid else {
            throw AppError.invalidInput("상태를 확인하려면 기기 UDID가 필요합니다.")
        }
        let state = try await getSimulatorState(udid: udid)
        return DeviceStatus(state: state, lastUpdated: Date(), additionalInfo: ["udid": udid])
    }
    
    // MARK: - 경로 감지
    
    /// `xcrun` 도구의 경로를 반환합니다.
    static func detectXcrunPath() -> String {
        return "/usr/bin/xcrun"
    }
    
    /// Xcode 커맨드 라인 도구가 설치되어 있는지 확인합니다.
    static func isXcodeToolsInstalled() -> Bool {
        return FileManager.default.fileExists(atPath: "/usr/bin/xcrun")
    }
}

// MARK: - 시뮬레이터 관리

extension IOSService {
    func applyBattery(device: Device, level: Int, isCharging: Bool) async throws {
        guard let udid = device.udid else {
            throw AppError.invalidInput("배터리 상태를 변경하려면 기기 UDID가 필요합니다.")
        }
        let clampedLevel = max(0, min(level, 100))
        let stateValue = isCharging ? "charging" : "discharging"
        let options = StatusBarOptions(time: nil, batteryLevel: clampedLevel, batteryState: stateValue)
        do {
            try await setStatusBar(udid: udid, options: options)
        } catch {
            throw IOSErrorMapper.toAppError(error)
        }
    }
    
    func applyLocation(device: Device, latitude: Double, longitude: Double) async throws {
        guard let udid = device.udid else {
            throw AppError.invalidInput("위치를 변경하려면 기기 UDID가 필요합니다.")
        }
        do {
            try await setLocation(udid: udid, latitude: latitude, longitude: longitude)
        } catch {
            throw IOSErrorMapper.toAppError(error)
        }
    }
    
    func installApp(device: Device, artifactPath: String) async throws -> Device {
        guard let udid = device.udid else {
            throw AppError.invalidInput("앱을 설치하려면 시뮬레이터 UDID가 필요합니다.")
        }
        
        let currentState = try await getSimulatorState(udid: udid)
        if currentState != .booted {
            try await bootSimulator(udid: udid)
        }
        
        try await installApp(udid: udid, appPath: artifactPath)
        return device
    }
    
    
    func bootSimulator(udid: String) async throws {
        do {
            let currentState = try await getSimulatorState(udid: udid)
            
            switch currentState {
            case .booted:
                try await openSimulatorApp()
                return
            case .booting:
                try await waitForBootCompletion(udid: udid)
                try await openSimulatorApp()
                return
            case .shutting_down:
                try await waitForShutdownCompletion(udid: udid)
            case .shutdown, .unknown:
                break
            }

            let xcrunPath = Self.detectXcrunPath()
            _ = try await CommandRunner.executeAsync(
                xcrunPath,
                arguments: ["simctl", "boot", udid]
            )
            try await waitForBootCompletion(udid: udid)
            try await openSimulatorApp()
            
        } catch {
            throw IOSErrorMapper.toAppError(error)
        }
    }
    
    func shutdownSimulator(udid: String) async throws {
        do {
            let currentState = try await getSimulatorState(udid: udid)
            
            guard currentState != .shutdown else {
                return
            }
            
            let xcrunPath = Self.detectXcrunPath()
            
            _ = try await CommandRunner.executeAsync(
                xcrunPath,
                arguments: ["simctl", "shutdown", udid]
            )
            
        } catch {
            throw IOSErrorMapper.toAppError(error)
        }
    }
    
    func getSimulatorState(udid: String) async throws -> DeviceState {
        let devices = try await listDevices()
        guard let device = devices.first(where: { $0.udid == udid }) else {
            throw AppError.deviceNotFound(udid)
        }
        return device.state
    }
    
    /// 사용 가능한 iOS 기기 타입 목록을 가져옵니다.
    func listDeviceTypes() async throws -> [IOSDeviceType] {
        let xcrunPath = Self.detectXcrunPath()
        
        do {
            let result = try await CommandRunner.executeAsync(
                xcrunPath,
                arguments: ["simctl", "list", "devicetypes", "-j"]
            )
            
            guard let data = result.data(using: .utf8) else {
                throw AppError.formatError("잘못된 UTF-8 출력입니다.")
            }
            
            let response: IOSDeviceTypeResponse = try JSONDecoder().decode(IOSDeviceTypeResponse.self, from: data)
            return response.devicetypes
            
        } catch {
            throw IOSErrorMapper.toAppError(error)
        }
    }
    
    /// 사용 가능한 iOS 런타임 목록을 가져옵니다.
    func listRuntimes() async throws -> [IOSRuntime] {
        let xcrunPath = Self.detectXcrunPath()
        
        do {
            let result = try await CommandRunner.executeAsync(
                xcrunPath,
                arguments: ["simctl", "list", "runtimes", "-j"]
            )
            
            guard let data = result.data(using: .utf8) else {
                throw AppError.formatError("잘못된 UTF-8 출력입니다.")
            }
            
            let response: IOSRuntimeResponse = try JSONDecoder().decode(IOSRuntimeResponse.self, from: data)
            return response.runtimes.filter(\.isAvailable)
            
        } catch {
            throw IOSErrorMapper.toAppError(error)
        }
    }
    
    func createSimulator(name: String, deviceTypeId: String, runtimeId: String) async throws -> String {
        let xcrunPath = Self.detectXcrunPath()
        
        do {
            let result = try await CommandRunner.executeAsync(
                xcrunPath,
                arguments: ["simctl", "create", name, deviceTypeId, runtimeId]
            )
            
            return result.trimmingCharacters(in: .whitespacesAndNewlines)
            
        } catch {
            throw IOSErrorMapper.toAppError(error)
        }
    }
    
    func deleteSimulator(udid: String) async throws {
        do {
            let currentState = try await getSimulatorState(udid: udid)
            if currentState == .booted || currentState == .booting {
                try await shutdownSimulator(udid: udid)
            }
            
            let xcrunPath = Self.detectXcrunPath()
            
            _ = try await CommandRunner.executeAsync(
                xcrunPath,
                arguments: ["simctl", "delete", udid]
            )
            
        } catch {
            throw IOSErrorMapper.toAppError(error)
        }
    }
    
    // MARK: - 앱 관리
    
    func installApp(udid: String, appPath: String) async throws {
        let xcrunPath = Self.detectXcrunPath()
        
        guard FileManager.default.fileExists(atPath: appPath) else {
            throw AppError.fileNotFound("앱 파일을 찾을 수 없습니다: \(appPath)")
        }
        
        do {
            let currentState = try await getSimulatorState(udid: udid)
            guard currentState == .booted else {
                throw AppError.deviceUnavailable("앱을 설치하려면 시뮬레이터가 부팅되어야 합니다. 현재 상태: \(currentState)")
            }
            
            _ = try await CommandRunner.executeAsync(
                xcrunPath,
                arguments: ["simctl", "install", udid, appPath]
            )
            
        } catch {
            throw IOSErrorMapper.toAppError(error)
        }
    }
    
    func uninstallApp(udid: String, bundleId: String) async throws {
        let xcrunPath = Self.detectXcrunPath()
        
        do {
            _ = try await CommandRunner.executeAsync(
                xcrunPath,
                arguments: ["simctl", "uninstall", udid, bundleId]
            )
            
        } catch {
            throw IOSErrorMapper.toAppError(error)
        }
    }
    
    func launchApp(udid: String, bundleId: String) async throws {
        let xcrunPath = Self.detectXcrunPath()
        
        do {
            _ = try await CommandRunner.executeAsync(
                xcrunPath,
                arguments: ["simctl", "launch", udid, bundleId]
            )
            
        } catch {
            throw IOSErrorMapper.toAppError(error)
        }
    }
    
    func terminateApp(udid: String, bundleId: String) async throws {
        let xcrunPath = Self.detectXcrunPath()
        
        do {
            _ = try await CommandRunner.executeAsync(
                xcrunPath,
                arguments: ["simctl", "terminate", udid, bundleId]
            )
            
        } catch {
            throw IOSErrorMapper.toAppError(error)
        }
    }
    
    func setLocation(udid: String, latitude: Double, longitude: Double) async throws {
        let xcrunPath = Self.detectXcrunPath()
        
        do {
            _ = try await CommandRunner.executeAsync(
                xcrunPath,
                arguments: ["simctl", "location", udid, "set", "\(latitude),\(longitude)"]
            )
            
        } catch {
            throw IOSErrorMapper.toAppError(error)
        }
    }
    
    func setLocation(udid: String, options: LocationOptions) async throws {
        try await setLocation(udid: udid, latitude: options.latitude, longitude: options.longitude)
    }
    
    func setStatusBar(udid: String, options: StatusBarOptions) async throws {
        let xcrunPath = Self.detectXcrunPath()
        
        var args = ["simctl", "status_bar", udid, "override"]
        
        if let time = options.time {
            args.append(contentsOf: ["--time", time])
        }
        if let level = options.batteryLevel {
            args.append(contentsOf: ["--batteryLevel", "\(level)"])
        }
        if let state = options.batteryState {
            args.append(contentsOf: ["--batteryState", state])
        }
        
        do {
            _ = try await CommandRunner.executeAsync(
                xcrunPath,
                arguments: args
            )
            
        } catch {
            throw IOSErrorMapper.toAppError(error)
        }
    }
}

// MARK: - 비공개 도우미

private extension IOSService {
    
    /// 시뮬레이터 앱을 엽니다.
    func openSimulatorApp() async throws {
        let proc = Process()
        proc.executableURL = URL(fileURLWithPath: "/usr/bin/open")
        proc.arguments = ["-a", "Simulator"]
        
        do {
            try proc.run()
            try await Task.sleep(nanoseconds: 2_000_000_000) // 2초
        } catch {
            // Simulator.app을 열지 못해도 오류를 발생시키지 않음
        }
    }
    
    /// 시뮬레이터 앱을 종료합니다.
    func terminateSimulatorApp() async {
        do {
            _ = try await CommandRunner.executeAsync(
                "/usr/bin/pkill",
                arguments: ["-f", "Simulator.app"]
            )
            try await Task.sleep(nanoseconds: 1_000_000_000) // 1초
        } catch {
            // 종료할 프로세스가 없어도 오류를 발생시키지 않음
        }
    }
    
    /// CoreSimulator 캐시를 정리하고 시뮬레이터를 재부팅합니다.
    func cleanupAndRetryBoot(udid: String) async throws {
        do {
            let homeDir = FileManager.default.homeDirectoryForCurrentUser.path
            let cacheDir = "\(homeDir)/Library/Developer/CoreSimulator/Caches"
            
            if FileManager.default.fileExists(atPath: cacheDir) {
                try FileManager.default.removeItem(atPath: cacheDir)
            }
        } catch {
            // 캐시 정리 실패는 치명적이지 않음
        }
        
        _ = try? await CommandRunner.executeAsync(
            "/usr/bin/xcrun",
            arguments: ["simctl", "shutdown", "all"]
        )
        try await Task.sleep(nanoseconds: 2_000_000_000)
        
        let xcrunPath = Self.detectXcrunPath()
        _ = try await CommandRunner.executeAsync(
            xcrunPath,
            arguments: ["simctl", "boot", udid]
        )
        
        try await waitForBootCompletion(udid: udid)
        try await openSimulatorApp()
    }
    
    /// 시뮬레이터 부팅 완료를 기다립니다.
    func waitForBootCompletion(udid: String) async throws {
        for _ in 1...20 {
            let state = try await getSimulatorState(udid: udid)
            if state == .booted {
                return
            }
            try await Task.sleep(nanoseconds: 1_000_000_000)
        }
        throw AppError.timeoutError
    }
    
    /// 시뮬레이터 종료 완료를 기다립니다.
    func waitForShutdownCompletion(udid: String) async throws {
        for _ in 1...10 {
            let state = try await getSimulatorState(udid: udid)
            if state == .shutdown {
                return
            }
            try await Task.sleep(nanoseconds: 1_000_000_000)
        }
        throw AppError.timeoutError
    }
}
