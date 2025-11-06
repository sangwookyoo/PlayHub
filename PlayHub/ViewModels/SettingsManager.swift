import Foundation
import Combine

/// Application settings manager
/// Handles all user preferences and system configuration
@MainActor
final class SettingsManager: ObservableObject, UserDefaultsManaging {
    
    // MARK: - UserDefaultsManaging Protocol
    
    let userDefaults = UserDefaults.standard
    
    // MARK: - Published Properties
    
    /// Current app theme setting
    @Published var selectedTheme: AppTheme = .system {
        didSet { save(selectedTheme, forKey: UserDefaultsKeys.appTheme) }
    }
    
    /// Current language setting
    @Published var selectedLanguage: AppLanguage = .system {
        didSet { save(selectedLanguage, forKey: UserDefaultsKeys.appLanguage) }
    }
    
    /// Android SDK paths
    @Published var androidSDKPath: String = "" {
        didSet { 
            saveString(androidSDKPath, forKey: UserDefaultsKeys.androidSDKPath)
            updateDerivedPaths()
        }
    }
    
    @Published var androidAVDPath: String = "" {
        didSet { saveString(androidAVDPath, forKey: UserDefaultsKeys.androidAVDPath) }
    }
    
    /// Tool paths
    @Published var adbPath: String = "/usr/local/bin/adb" {
        didSet { saveString(adbPath, forKey: UserDefaultsKeys.androidADBPath) }
    }
    
    @Published var emulatorPath: String = "" {
        didSet { saveString(emulatorPath, forKey: UserDefaultsKeys.androidEmulatorPath) }
    }
    
    /// Performance settings
    @Published var enablePerformanceLogging: Bool = false {
        didSet { saveBool(enablePerformanceLogging, forKey: UserDefaultsKeys.performanceLogging) }
    }
    
    @Published var maxLogEntries: Int = 1000 {
        didSet { saveInt(maxLogEntries, forKey: UserDefaultsKeys.performanceMaxLogEntries) }
    }
    
    /// Auto-refresh settings
    @Published var autoRefreshInterval: Double = 5.0 {
        didSet { saveDouble(autoRefreshInterval, forKey: UserDefaultsKeys.appAutoRefreshInterval) }
    }
    
    @Published var enableAutoRefresh: Bool = true {
        didSet { saveBool(enableAutoRefresh, forKey: UserDefaultsKeys.appAutoRefresh) }
    }
    
    /// User-authorised access paths (security-scoped bookmarks)
    @Published private(set) var coreSimulatorAccessPath: String = PathPermissionManager.shared.currentPath(for: .coreSimulatorRoot) ?? ""
    @Published private(set) var androidAVDAccessPath: String = PathPermissionManager.shared.currentPath(for: .androidAVD) ?? ""
    
    // MARK: - Private Properties
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init() {
        loadSettings()
        detectAndroidPaths()
        
        #if DEBUG
        print("⚙️ SettingsManager initialized")
        #endif
    }
    
    // MARK: - Settings Loading (Simplified with UserDefaultsManager)
    
    private func loadSettings() {
        // Theme (이제 ThemeManager에서만 정의된 AppTheme 사용)
        selectedTheme = load(AppTheme.self, forKey: UserDefaultsKeys.appTheme, defaultValue: .system) ?? .system
        
        // Language
        selectedLanguage = load(AppLanguage.self, forKey: UserDefaultsKeys.appLanguage, defaultValue: .system) ?? .system
        
        // Paths
        androidSDKPath = loadString(forKey: UserDefaultsKeys.androidSDKPath)
        androidAVDPath = loadString(forKey: UserDefaultsKeys.androidAVDPath)
        adbPath = loadString(forKey: UserDefaultsKeys.androidADBPath, defaultValue: "/usr/local/bin/adb")
        emulatorPath = loadString(forKey: UserDefaultsKeys.androidEmulatorPath)
        
        // Performance
        enablePerformanceLogging = loadBool(forKey: UserDefaultsKeys.performanceLogging)
        maxLogEntries = loadInt(forKey: UserDefaultsKeys.performanceMaxLogEntries, defaultValue: 1000)
        
        // Auto-refresh
        autoRefreshInterval = loadDouble(forKey: UserDefaultsKeys.appAutoRefreshInterval, defaultValue: 5.0)
        enableAutoRefresh = loadBool(forKey: UserDefaultsKeys.appAutoRefresh, defaultValue: true)
        
        coreSimulatorAccessPath = PathPermissionManager.shared.currentPath(for: .coreSimulatorRoot) ?? ""
        androidAVDAccessPath = PathPermissionManager.shared.currentPath(for: .androidAVD) ?? ""
    }
    
    // MARK: - Android Path Detection
    
    private func detectAndroidPaths() {
        // SDK path detection
        if androidSDKPath.isEmpty {
            let possibleSDKPaths = [
                "\(NSHomeDirectory())/Library/Android/sdk",
                "\(NSHomeDirectory())/Android/Sdk",
                "/usr/local/share/android-sdk",
                "/opt/android-sdk"
            ]
            
            for path in possibleSDKPaths {
                if FileManager.default.fileExists(atPath: path) {
                    androidSDKPath = path
                    break
                }
            }
        }
        
        // AVD path detection
        if androidAVDPath.isEmpty {
            let defaultAVDPath = "\(NSHomeDirectory())/.android/avd"
            if FileManager.default.fileExists(atPath: defaultAVDPath) {
                androidAVDPath = defaultAVDPath
            }
        }
        
        // Attempt to resolve adb/emulator from PATH if not configured
        if !CommandRunner.isExecutable(adbPath) {
            if let resolvedADB = locateExecutable(named: "adb") {
                adbPath = resolvedADB
                deriveSDKPath(from: resolvedADB)
            }
        }
        
        if !CommandRunner.isExecutable(emulatorPath) {
            if let resolvedEmulator = locateExecutable(named: "emulator") {
                emulatorPath = resolvedEmulator
                if androidSDKPath.isEmpty {
                    deriveSDKPath(from: resolvedEmulator)
                }
            }
        }
        
        updateDerivedPaths()
    }
    
    /// Update derived paths based on SDK path
    private func updateDerivedPaths() {
        if !androidSDKPath.isEmpty {
            // Update ADB path if not manually set
            let derivedADBPath = "\(androidSDKPath)/platform-tools/adb"
            if adbPath == "/usr/local/bin/adb" || !FileManager.default.fileExists(atPath: adbPath) {
                if FileManager.default.fileExists(atPath: derivedADBPath) {
                    adbPath = derivedADBPath
                }
            }
            
            // Update Emulator path
            let possibleEmulatorPaths = [
                "\(androidSDKPath)/emulator/emulator",
                "\(androidSDKPath)/tools/emulator"
            ]
            
            for path in possibleEmulatorPaths {
                if FileManager.default.fileExists(atPath: path) {
                    emulatorPath = path
                    break
                }
            }
        }
    }
    
    private func deriveSDKPath(from executable: String) {
        let url = URL(fileURLWithPath: executable)
        let platformTools = url.deletingLastPathComponent()
        let candidate = platformTools.deletingLastPathComponent().path
        if FileManager.default.fileExists(atPath: candidate) {
            androidSDKPath = candidate
        }
    }
    
    private func locateExecutable(named name: String) -> String? {
        do {
            let result = try CommandRunner.execute("/usr/bin/which", arguments: [name])
            let path = result.trimmedOutput
            return path.isEmpty ? nil : path
        } catch {
            return nil
        }
    }
    
    // MARK: - Path Validation
    
    /// Validate all configured paths
    /// - Returns: Dictionary with validation results
    func validatePaths() -> [String: Bool] {
        var results: [String: Bool] = [:]
        
        // Xcode (xcrun)
        results["xcode"] = CommandRunner.isExecutable("/usr/bin/xcrun")
        
        // ADB
        results["adb"] = !adbPath.isEmpty && CommandRunner.isExecutable(adbPath)
        
        // Emulator
        results["emulator"] = !emulatorPath.isEmpty && CommandRunner.isExecutable(emulatorPath)
        
        // Android SDK
        results["android_sdk"] = !androidSDKPath.isEmpty && FileManager.default.fileExists(atPath: androidSDKPath)
        
        // AVD directory
        results["avd_path"] = !androidAVDPath.isEmpty && FileManager.default.fileExists(atPath: androidAVDPath)
        
        return results
    }
    
    // MARK: - Security Scoped Access Helpers
    
    func requestCoreSimulatorAccess() {
        #if os(macOS)
        let defaultPath = ("~/Library/Developer/CoreSimulator" as NSString).expandingTildeInPath
        if let url = PathPermissionManager.shared.requestAccess(
            for: .coreSimulatorRoot,
            suggestedPath: defaultPath,
            message: "settings.paths.permission.ios.prompt".loc()
        ) {
            coreSimulatorAccessPath = url.path
        }
        #endif
    }
    
    func requestAndroidAVDAccess() {
        #if os(macOS)
        let defaultPath = ("~/.android/avd" as NSString).expandingTildeInPath
        if let url = PathPermissionManager.shared.requestAccess(
            for: .androidAVD,
            suggestedPath: defaultPath,
            message: "settings.paths.permission.android.prompt".loc()
        ) {
            androidAVDAccessPath = url.path
            if androidAVDPath.isEmpty {
                androidAVDPath = url.path
            }
        }
        #endif
    }
    
    func useCoreSimulatorURL(_ block: (URL) -> Void) {
        PathPermissionManager.shared.useURL(for: .coreSimulatorRoot, block: block)
    }
    
    func useAndroidAVDURL(_ block: (URL) -> Void) {
        PathPermissionManager.shared.useURL(for: .androidAVD, block: block)
    }
    
    // MARK: - Utility Methods (Using UserDefaultsManager)
    
    /// Reset all settings to defaults
    func resetToDefaults() {
        selectedTheme = .system
        selectedLanguage = .system
        androidSDKPath = ""
        androidAVDPath = ""
        adbPath = "/usr/local/bin/adb"
        emulatorPath = ""
        enablePerformanceLogging = false
        maxLogEntries = 1000
        autoRefreshInterval = 5.0
        enableAutoRefresh = true
        
        // Re-detect paths
        detectAndroidPaths()
        
        #if DEBUG
        print("⚙️ Settings reset to defaults")
        #endif
    }
    
    /// Export current settings using UserDefaultsManager
    func exportSettings() -> [String: Any] {
        return [
            "theme": selectedTheme.rawValue,
            "language": selectedLanguage.rawValue,
            "androidSDKPath": androidSDKPath,
            "androidAVDPath": androidAVDPath,
            "adbPath": adbPath,
            "emulatorPath": emulatorPath,
            "performanceLogging": enablePerformanceLogging,
            "maxLogEntries": maxLogEntries,
            "autoRefreshInterval": autoRefreshInterval,
            "autoRefresh": enableAutoRefresh
        ]
    }
    
    /// Import settings from dictionary using UserDefaultsManager
    func importSettings(_ settings: [String: Any]) {
        if let themeString = settings["theme"] as? String,
           let theme = AppTheme(rawValue: themeString) {
            selectedTheme = theme
        }
        
        if let langString = settings["language"] as? String,
           let language = AppLanguage(rawValue: langString) {
            selectedLanguage = language
        }
        
        if let path = settings["androidSDKPath"] as? String { androidSDKPath = path }
        if let path = settings["androidAVDPath"] as? String { androidAVDPath = path }
        if let path = settings["adbPath"] as? String { adbPath = path }
        if let path = settings["emulatorPath"] as? String { emulatorPath = path }
        if let enabled = settings["performanceLogging"] as? Bool { enablePerformanceLogging = enabled }
        if let max = settings["maxLogEntries"] as? Int { maxLogEntries = max }
        if let interval = settings["autoRefreshInterval"] as? Double { autoRefreshInterval = interval }
        if let enabled = settings["autoRefresh"] as? Bool { enableAutoRefresh = enabled }
        
        // 설정 가져온 후 즉시 동기화
        synchronize()
    }
    
    /// 설정 업데이트 바로 디스크에 반영
    func forceSave() {
        synchronize()
        
        #if DEBUG
        print("💾 Settings force saved to disk")
        #endif
    }
}

// MARK: - Supporting Enums
// AppTheme 제거 - ThemeManager에서 사용

enum AppLanguage: String, CaseIterable {
    case system = "system"
    case english = "en"
    case korean = "ko"
    case japanese = "ja"
    case chineseSimplified = "zh-Hans"
    case chineseTraditional = "zh-Hant"
    case german = "de"
    case french = "fr"
    case spanish = "es"
    
    var displayName: String {
        switch self {
        case .system: return "language.system".loc()
        case .english: return "English"
        case .korean: return "한국어"
        case .japanese: return "日本語"
        case .chineseSimplified: return "简体中文"
        case .chineseTraditional: return "繁體中文"
        case .german: return "Deutsch"
        case .french: return "Français"
        case .spanish: return "Español"
        }
    }
    
    var code: String? {
        switch self {
        case .system: return nil
        case .english: return "en"
        case .korean: return "ko"
        case .japanese: return "ja"
        case .chineseSimplified: return "zh-Hans"
        case .chineseTraditional: return "zh-Hant"
        case .german: return "de"
        case .french: return "fr"
        case .spanish: return "es"
        }
    }
    
    var flag: String {
        switch self {
        case .system: return "🌍"
        case .english: return "🇺🇸"
        case .korean: return "🇰🇷"
        case .japanese: return "🇯🇵"
        case .chineseSimplified: return "🇨🇳"
        case .chineseTraditional: return "🇹🇼"
        case .german: return "🇩🇪"
        case .french: return "🇫🇷"
        case .spanish: return "🇪🇸"
        }
    }
}
