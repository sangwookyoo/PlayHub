
import Foundation

final class AndroidService: PlatformService {
    var platformType: Platform { .android }
    
    private let settings: SettingsManager
    
    init(settingsManager: SettingsManager) {
        self.settings = settingsManager
    }
    
    func listDevices() async throws -> [Device] {
        guard isADBWorking() else {
            throw AppError.configurationError("ADB가 작동하지 않습니다: \(settings.adbPath)")
        }
        
        guard isEmulatorWorking() else {
            throw AppError.configurationError("에뮬레이터가 작동하지 않습니다: \(settings.emulatorPath)")
        }
        
        do {
            async let running = fetchRunningDevices()
            async let avds = fetchAvailableAVDs()
            
            let (runningList, avdList) = try await (running, avds)
            let runningNames = Set(runningList.map { $0.name })
            
            var result: [Device] = runningList
            result += avdList.filter { !runningNames.contains($0.name) }
            
            return result.sorted { $0.name < $1.name }
            
        } catch {
            throw AndroidErrorMapper.toAppError(error)
        }
    }

    func boot(device: Device) async throws {
        try await bootEmulator(avdName: device.name)
    }

    func shutdown(device: Device) async throws {
        guard let serial = device.udid else {
            throw AppError.invalidInput("종료하려면 기기 시리얼이 필요합니다.")
        }
        try await shutdownEmulator(serial: serial)
    }

    func delete(device: Device) async throws {
        try deleteEmulator(avdName: device.name)
    }

    func getStatus(of device: Device) async throws -> DeviceStatus {
        let devices = try await listDevices()
        if let currentDevice = devices.first(where: { $0.id == device.id }) {
            return DeviceStatus(state: currentDevice.state, lastUpdated: Date(), additionalInfo: ["udid": currentDevice.udid ?? ""])
        }
        return DeviceStatus(state: .unknown, lastUpdated: Date(), additionalInfo: [:])
    }
    
    func installApp(device: Device, artifactPath: String) async throws -> Device {
        guard FileManager.default.fileExists(atPath: artifactPath) else {
            throw AppError.fileNotFound("APK를 찾을 수 없습니다: \(artifactPath)")
        }
        
        let serial = try await ensureSerial(for: device)
        try await waitForDeviceReady(serial: serial)
        
        do {
            _ = try await CommandRunner.executeAsync(
                settings.adbPath,
                arguments: ["-s", serial, "install", "-r", artifactPath]
            )
            
            let runningDevices = try await fetchRunningDevices()
            if let updated = runningDevices.first(where: { $0.udid == serial }) {
                return updated
            }
            
            return Device(
                id: device.id,
                name: device.name,
                type: .android,
                udid: serial,
                state: .booted,
                isAvailable: true,
                osVersion: device.osVersion,
                deviceModel: device.deviceModel,
                attributes: device.attributes
            )
        } catch {
            throw AndroidErrorMapper.toAppError(error)
        }
    }
    
        // MARK: - 경로 확인
    
        
    
        /// ADB가 작동하는지 확인합니다.
    
        private func isADBWorking() -> Bool {
    
            guard !settings.adbPath.isEmpty else { return false }
    
            return CommandRunner.isExecutable(settings.adbPath)
    
        }
    
        
    
        /// 에뮬레이터가 작동하는지 확인합니다.
    
        private func isEmulatorWorking() -> Bool {
    
            guard !settings.emulatorPath.isEmpty else { return false }
    
            return CommandRunner.isExecutable(settings.emulatorPath)
    
        }
    
    }
    
    
    
    // MARK: - 에뮬레이터 관리
    
    
    
    extension AndroidService {
    
        
    
        /// Android 에뮬레이터를 부팅합니다.
    
        func bootEmulator(avdName: String) async throws {
    
            guard isEmulatorWorking() else {
    
                throw AppError.configurationError("에뮬레이터를 사용할 수 없습니다: \(settings.emulatorPath)")
    
            }
    
            
    
            do {
    
                let name = avdName.hasPrefix("avd:") ? String(avdName.dropFirst(4)) : avdName
    
                
    
                let runningDevices = try await fetchRunningDevices()
    
                if runningDevices.contains(where: { $0.name == name }) {
    
                    return
    
                }
    
                
    
                let availableAVDs = try await fetchAvailableAVDs()
    
                guard availableAVDs.contains(where: { $0.name == name }) else {
    
                    throw AppError.deviceNotFound("AVD를 찾을 수 없습니다: \(name)")
    
                }
    
                
    
                let process = Process()
    
                process.executableURL = URL(fileURLWithPath: settings.emulatorPath)
    
                process.arguments = [
    
                    "-avd", name,
    
                    "-no-snapshot-load",
    
                    "-no-audio",
    
                    "-gpu", "auto",
    
                    "-skin", "1080x1920"
    
                ]
    
                
    
                process.standardOutput = FileHandle.nullDevice
    
                process.standardError = FileHandle.nullDevice
    
                
    
                try process.run()
    
                
    
                try await waitForEmulatorBoot(avdName: name)
    
                
    
            } catch {
    
                throw AndroidErrorMapper.toAppError(error)
    
            }
    
        }
    
        
    
        /// 지정된 시리얼의 에뮬레이터를 종료합니다.
    
        func shutdownEmulator(serial: String) async throws {
    
            guard !serial.hasPrefix("avd:") else { return }
    
            guard isADBWorking() else {
    
                throw AppError.configurationError("ADB를 사용할 수 없습니다: \(settings.adbPath)")
    
            }
    
            
    
            do {
    
                _ = try await CommandRunner.executeAsync(
    
                    settings.adbPath,
    
                    arguments: ["-s", serial, "emu", "kill"]
    
                )
    
                
    
                for _ in 1...15 {
    
                    try await Task.sleep(nanoseconds: 1_000_000_000)
    
                    let list = try await fetchRunningDevices()
    
                    if !list.contains(where: { $0.udid == serial }) {
    
                        return
    
                    }
    
                }
    
                
    
            } catch {
    
                throw AndroidErrorMapper.toAppError(error)
    
            }
    
        }
    
        
    
        /// 지정된 AVD 이름의 에뮬레이터를 삭제합니다.
    
        func deleteEmulator(avdName: String) throws {
    
            let name = avdName.hasPrefix("avd:") ? String(avdName.dropFirst(4)) : avdName
    
            let avdBase = settings.androidAVDPath
    
            
    
            let pathsToDelete = [
    
                "\(avdBase)/\(name).avd",
    
                "\(avdBase)/\(name).ini"
    
            ]
    
            
    
            do {
    
                for path in pathsToDelete {
    
                    if FileManager.default.fileExists(atPath: path) {
    
                        try FileManager.default.removeItem(atPath: path)
    
                    }
    
                }
    
            } catch {
    
                throw AndroidErrorMapper.toAppError(error)
    
            }
    
        }
    
        
    
        /// 에뮬레이터 부팅 완료를 기다립니다.
    
        private func waitForEmulatorBoot(avdName: String) async throws {
    
            for _ in 1...60 {
    
                try await Task.sleep(nanoseconds: 1_000_000_000)
    
                
    
                do {
    
                    let runningDevices = try await fetchRunningDevices()
    
                    if runningDevices.contains(where: { $0.name == avdName }) {
    
                        return
    
                    }
    
                } catch {
    
                    // ADB 명령이 실패할 수 있음
    
                }
    
            }
    
            
    
            throw AppError.timeoutError
    
        }
    
    }
    
    
    
    // MARK: - 비공개 도우미
    
    
    
    private extension AndroidService {
    
        
    
        /// 실행 중인 안드로이드 디바이스 목록을 가져옵니다.
    
        func fetchRunningDevices() async throws -> [Device] {
    
            do {
    
                let result = try await CommandRunner.executeAsync(
    
                    settings.adbPath,
    
                    arguments: ["devices", "-l"]
    
                )
    
                
    
                return result.components(separatedBy: .newlines)
    
                    .compactMap { line -> Device? in
    
                        let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
    
                        guard trimmed.contains("emulator-") && trimmed.contains("device") else { return nil }
    
                        
    
                        let parts = trimmed.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
    
                        guard parts.count >= 2 else { return nil }
    
                        
    
                        let serial = parts[0]
    
                        var avdName = "Unknown"
    
                        
    
                        if let devicePart = parts.first(where: { $0.hasPrefix("device:") }) {
    
                            avdName = String(devicePart.dropFirst(7))
    
                        } else {
    
                            if serial.hasPrefix("emulator-") {
    
                                avdName = "Emulator \(String(serial.dropFirst(9)))"
    
                            }
    
                        }
    
                        
    
                        let identifier = serial.isEmpty ? "\(avdName)-android-running" : serial
                        return Device(
                            id: ServiceModelUtils.stableUUID(for: identifier),
                            name: avdName,
                            type: .android,
                            udid: serial,
                            state: .booted,
                            isAvailable: true
                        )
    
                    }
    
            } catch {
    
                throw AndroidErrorMapper.toAppError(error)
    
            }
    
        }
    
        
    
        /// 사용 가능한 AVD 목록을 가져옵니다.
    
        func fetchAvailableAVDs() async throws -> [Device] {
    
            do {
    
                let result = try await CommandRunner.executeAsync(
    
                    settings.emulatorPath,
    
                    arguments: ["-list-avds"]
    
                )
    
                
    
                let avdNames = result.components(separatedBy: .newlines)
    
                    .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
    
                    .filter { !$0.isEmpty }
    
                
    
                return avdNames.map { name in
    
                    Device(
                        id: ServiceModelUtils.stableUUID(for: "\(name)-android-avd"),
                        name: name,
                        type: .android,
                        udid: nil,
                        state: .shutdown,
                        isAvailable: true
                    )
    
                }
    
                
    
            } catch {
    
                throw AndroidErrorMapper.toAppError(error)
    
            }
    
        }

        func ensureSerial(for device: Device) async throws -> String {
            if let serial = device.udid, !serial.isEmpty {
                return serial
            }
            
            try await bootEmulator(avdName: device.name)
            
            let runningDevices = try await fetchRunningDevices()
            if let serial = runningDevices.first(where: { $0.name == device.name })?.udid {
                return serial
            }
            
            throw AppError.deviceUnavailable("에뮬레이터 시리얼을 확인할 수 없습니다. 에뮬레이터가 정상적으로 실행 중인지 확인하세요.")
        }

        func waitForDeviceReady(serial: String) async throws {
            guard isADBWorking() else {
                throw AppError.configurationError("ADB를 사용할 수 없습니다: \(settings.adbPath)")
            }

            for _ in 0..<60 {
                do {
                    let output = try await CommandRunner.executeAsync(
                        settings.adbPath,
                        arguments: ["-s", serial, "shell", "getprop", "sys.boot_completed"]
                    )

                    if output.trimmingCharacters(in: .whitespacesAndNewlines) == "1" {
                        return
                    }
                } catch {
                    // Ignore transient errors while booting
                }

                try await Task.sleep(nanoseconds: 1_000_000_000)
            }

            throw AppError.timeoutError
        }
    
    }
