import Foundation

class SystemDiagnostics {
    private let settingsManager: SettingsManager
    
    init(settingsManager: SettingsManager) {
        self.settingsManager = settingsManager
    }
    
    func checkSystemRequirements() async -> SystemRequirements {
        async let xcode = checkXcode()
        async let simctl = checkSimctl()
        async let androidStudio = checkAndroidStudio()
        async let adb = checkADB()
        async let emulator = checkEmulator()
        async let avd = checkAVD()
        
        return await SystemRequirements(
            xcodeInstalled: xcode,
            simctlAvailable: simctl,
            androidStudioInstalled: androidStudio,
            adbAvailable: adb,
            emulatorAvailable: emulator,
            avdConfigured: avd
        )
    }
    
    // MARK: - iOS Checks
    
    private func checkXcode() async -> SystemCheck {
        do {
            let result = try CommandRunner.execute("/usr/bin/xcode-select", arguments: ["-p"])
            guard result.isSuccess else {
                throw DeviceError.commandFailed(result.stderr)
            }
            
            let path = result.stdout.trimmingCharacters(in: .whitespacesAndNewlines)
            
            if FileManager.default.fileExists(atPath: path) {
                // Xcode 버전 확인
                let versionResult = try? CommandRunner.execute("/usr/bin/xcodebuild", arguments: ["-version"])
                let version = versionResult?.stdout.components(separatedBy: "\n").first ?? "Unknown"
                
                return SystemCheck(
                    isInstalled: true,
                    version: version,
                    path: path,
                    message: "system.check.xcode.installed".loc()
                )
            }
        } catch {
            print("❌ Xcode check error: \(error)")
        }
        
        return SystemCheck(
            isInstalled: false,
            version: "N/A",
            path: "",
            message: "system.check.xcode.not_installed".loc()
        )
    }
    
    private func checkSimctl() async -> SystemCheck {
        do {
            let result = try CommandRunner.execute("/usr/bin/xcrun", arguments: ["simctl", "list"])
            if result.isSuccess {
                return SystemCheck(
                    isInstalled: true,
                    version: "Available",
                    path: "/usr/bin/xcrun",
                    message: "system.check.simctl.available".loc()
                )
            }
        } catch {
            print("❌ simctl check error: \(error)")
        }
        
        return SystemCheck(
            isInstalled: false,
            version: "N/A",
            path: "",
            message: "system.check.simctl.not_available".loc()
        )
    }
    
    // MARK: - Android Checks
    
    private func checkAndroidStudio() async -> SystemCheck {
        let androidStudioPath = "/Applications/Android Studio.app"
        
        if FileManager.default.fileExists(atPath: androidStudioPath) {
            return SystemCheck(
                isInstalled: true,
                version: "Installed",
                path: androidStudioPath,
                message: "system.check.android_studio.installed".loc()
            )
        }
        
        return SystemCheck(
            isInstalled: false,
            version: "N/A",
            path: "",
            message: "system.check.android_studio.not_installed".loc()
        )
    }
    
    private func checkADB() async -> SystemCheck {
        let adbPath = settingsManager.adbPath
        
        guard !adbPath.isEmpty else {
            return SystemCheck(
                isInstalled: false,
                version: "N/A",
                path: "",
                message: "system.check.adb.not_configured".loc()
            )
        }
        
        if FileManager.default.fileExists(atPath: adbPath) {
            do {
                let result = try CommandRunner.execute(adbPath, arguments: ["--version"])
                if result.isSuccess {
                    let version = result.stdout.components(separatedBy: "\n").first ?? "Unknown"
                    
                    return SystemCheck(
                        isInstalled: true,
                        version: version,
                        path: adbPath,
                        message: "system.check.adb.available".loc()
                    )
                }
            } catch {
                print("❌ ADB check error: \(error)")
            }
        }
        
        return SystemCheck(
            isInstalled: false,
            version: "N/A",
            path: adbPath,
            message: "system.check.adb.not_found".loc()
        )
    }
    
    private func checkEmulator() async -> SystemCheck {
        let emulatorPath = settingsManager.emulatorPath
        
        guard !emulatorPath.isEmpty else {
            return SystemCheck(
                isInstalled: false,
                version: "N/A",
                path: "",
                message: "system.check.emulator.not_configured".loc()
            )
        }
        
        if FileManager.default.fileExists(atPath: emulatorPath) {
            do {
                let result = try CommandRunner.execute(emulatorPath, arguments: ["-version"])
                if result.isSuccess {
                    let version = result.stdout.components(separatedBy: "\n").first ?? "Unknown"
                    
                    return SystemCheck(
                        isInstalled: true,
                        version: version,
                        path: emulatorPath,
                        message: "system.check.emulator.available".loc()
                    )
                }
            } catch {
                print("❌ Emulator check error: \(error)")
            }
        }
        
        return SystemCheck(
            isInstalled: false,
            version: "N/A",
            path: emulatorPath,
            message: "system.check.emulator.not_found".loc()
        )
    }
    
    private func checkAVD() async -> SystemCheck {
        let avdPath = settingsManager.androidAVDPath
        
        guard !avdPath.isEmpty else {
            return SystemCheck(
                isInstalled: false,
                version: "N/A",
                path: "",
                message: "system.check.avd.not_configured".loc()
            )
        }
        
        if FileManager.default.fileExists(atPath: avdPath) {
            do {
                let contents = try FileManager.default.contentsOfDirectory(atPath: avdPath)
                let avdCount = contents.filter { $0.hasSuffix(".avd") }.count
                
                if avdCount > 0 {
                    return SystemCheck(
                        isInstalled: true,
                        version: "\(avdCount) AVDs",
                        path: avdPath,
                        message: "system.check.avd.available".loc()
                    )
                }
            } catch {
                print("❌ AVD check error: \(error)")
            }
        }
        
        return SystemCheck(
            isInstalled: false,
            version: "N/A",
            path: avdPath,
            message: "system.check.avd.not_available".loc()
        )
    }
}
