
#if os(macOS)
import AppKit
#endif
import Foundation
import SwiftUI
import Combine

// MARK: - AppTheme Definition

/// Available app themes (이제 단일 소스)
enum AppTheme: String, CaseIterable {
    case light = "light"
    case dark = "dark"
    case system = "system"
    
    var displayName: String {
        switch self {
        case .light: return "theme.light".loc()
        case .dark: return "theme.dark".loc()
        case .system: return "theme.system".loc()
        }
    }
    
    var colorScheme: ColorScheme? {
        switch self {
        case .light: return .light
        case .dark: return .dark
        case .system: return nil
        }
    }
    
    var icon: String {
        switch self {
        case .light: return "sun.max"
        case .dark: return "moon"
        case .system: return "circle.lefthalf.filled"
        }
    }
}

/// Theme and appearance management
/// Handles dark/light mode switching and visual customization
@MainActor
final class ThemeManager: ObservableObject, UserDefaultsManaging {
    
    // MARK: - Singleton
    
    static let shared = ThemeManager()
    
    // MARK: - UserDefaultsManaging Protocol
    
    let userDefaults = UserDefaults.standard
    
    // MARK: - Published Properties
    
    /// Current active theme
    @Published var currentTheme: AppTheme = .system {
        didSet {
            save(currentTheme, forKey: UserDefaultsKeys.appTheme) // 올바른 키 사용
            applyTheme()
        }
    }
    
    /// Custom accent color (if supported)
    @Published var accentColor: Color = DesignSystem.Colors.primary {
        didSet {
            saveAccentColor()
        }
    }
    
    /// Window transparency setting
    @Published var enableWindowTransparency: Bool = false {
        didSet {
            saveBool(enableWindowTransparency, forKey: UserDefaultsKeys.themeWindowTransparency)
            applyWindowEffects()
        }
    }
    
    /// Reduced motion preference
    @Published var reduceMotion: Bool = false {
        didSet {
            saveBool(reduceMotion, forKey: UserDefaultsKeys.themeReduceMotion)
        }
    }
    
    // MARK: - Computed Properties
    
    /// Current effective color scheme based on theme and system settings
    var effectiveColorScheme: ColorScheme? {
        switch currentTheme {
        case .light:
            return .light
        case .dark:
            return .dark
        case .system:
            return nil // Let system decide
        }
    }
    
    /// Whether dark mode is currently active
    var isDarkMode: Bool {
#if os(macOS)
        if currentTheme == .dark { return true }
        if currentTheme == .light { return false }
        // For system theme, check actual appearance
        guard let app = NSApp else { return false }
        return app.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
#else
        return currentTheme == .dark
#endif
    }
    
    // MARK: - Private Properties
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    private init() {
        loadSavedSettings()
        setupSystemObservers()
        
        #if DEBUG
        print("🎨 ThemeManager initialized with theme: \(currentTheme.rawValue)")
        #endif
    }
    
    // MARK: - Public Methods
    
    /// Change the app theme
    /// - Parameter theme: New theme to apply
    func setTheme(_ theme: AppTheme) {
        guard theme != currentTheme else { return }
        
        currentTheme = theme
        
        #if DEBUG
        print("🎨 Theme changed to: \(theme.displayName)")
        #endif
    }
    
    /// Toggle between light and dark themes
    func toggleTheme() {
        switch currentTheme {
        case .light:
            setTheme(.dark)
        case .dark:
            setTheme(.light)
        case .system:
            // For system theme, toggle to opposite of current appearance
            setTheme(isDarkMode ? .light : .dark)
        }
    }
    
    /// Reset theme to system default
    func resetToSystemTheme() {
        setTheme(.system)
    }
    
    /// Get theme-appropriate color
    /// - Parameter lightColor: Color for light theme
    /// - Parameter darkColor: Color for dark theme
    /// - Returns: Appropriate color for current theme
    func color(light lightColor: Color, dark darkColor: Color) -> Color {
        return isDarkMode ? darkColor : lightColor
    }
    
    /// Get animation based on motion preference
    /// - Parameter defaultAnimation: Animation to use if motion is enabled
    /// - Returns: Animation or nil if motion should be reduced
    func animation(_ defaultAnimation: Animation) -> Animation? {
        return reduceMotion ? nil : defaultAnimation
    }
    
    // MARK: - Private Methods (Using UserDefaultsManager)
    
    private func loadSavedSettings() {
        // Load theme (UserDefaultsManager 사용)
        currentTheme = load(AppTheme.self, forKey: UserDefaultsKeys.appTheme, defaultValue: .system) ?? .system
        
        // Load accent color (NSColor 직렬화 유지)
        if let colorData = userDefaults.data(forKey: UserDefaultsKeys.themeAccentColor),
           let color = try? NSKeyedUnarchiver.unarchivedObject(ofClass: NSColor.self, from: colorData) {
            accentColor = Color(color)
        }
        
        // Load other settings
        enableWindowTransparency = loadBool(forKey: UserDefaultsKeys.themeWindowTransparency)
        reduceMotion = loadBool(forKey: UserDefaultsKeys.themeReduceMotion)
        
        // Apply loaded theme
        applyTheme()
    }
    
    private func saveAccentColor() {
        let nsColor = NSColor(accentColor)
        if let colorData = try? NSKeyedArchiver.archivedData(withRootObject: nsColor, requiringSecureCoding: false) {
            userDefaults.set(colorData, forKey: UserDefaultsKeys.themeAccentColor)
        }
    }
    
    private func applyTheme() {
#if os(macOS)
        guard NSApp != nil else { return }
        let appearanceName: NSAppearance.Name
        
        switch currentTheme {
        case .light:
            appearanceName = .aqua
        case .dark:
            appearanceName = .darkAqua
        case .system:
            // Let system decide
            NSApp.appearance = nil
            return
        }
        
        if let appearance = NSAppearance(named: appearanceName) {
            NSApp.appearance = appearance
        }
#endif
    }
    
    private func applyWindowEffects() {
#if os(macOS)
        guard NSApp != nil else { return }
        DispatchQueue.main.async {
            NSApp.windows.forEach { window in
                if self.enableWindowTransparency {
                    window.isOpaque = false
                    window.backgroundColor = NSColor.clear
                } else {
                    window.isOpaque = true
                    window.backgroundColor = NSColor.windowBackgroundColor
                }
            }
        }
#endif
    }
    
    private func setupSystemObservers() {
#if os(macOS)
        // Listen for system appearance changes
        NotificationCenter.default.publisher(for: NSApplication.didChangeScreenParametersNotification)
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
#endif
    }
    
    private func checkAccessibilitySettings() {
        // Update reduce motion based on system accessibility settings
#if os(macOS)
        let systemReduceMotion = NSWorkspace.shared.accessibilityDisplayShouldReduceMotion
        if systemReduceMotion != reduceMotion {
            reduceMotion = systemReduceMotion
        }
#endif
    }
}

// MARK: - Theme Presets

extension ThemeManager {
    
    /// Predefined theme presets
    enum ThemePreset: CaseIterable {
        case `default`
        case highContrast
        case colorful
        case minimal
        
        var name: String {
            switch self {
            case .default: return "Default"
            case .highContrast: return "High Contrast"
            case .colorful: return "Colorful"
            case .minimal: return "Minimal"
            }
        }
        
        var accentColor: Color {
            switch self {
            case .default: return DesignSystem.Colors.primary
            case .highContrast: return Color.white
            case .colorful: return DesignSystem.Colors.primary
            case .minimal: return Color.gray
            }
        }
    }
    
    /// Apply a theme preset
    /// - Parameter preset: Theme preset to apply
    func applyPreset(_ preset: ThemePreset) {
        accentColor = preset.accentColor
        
        #if DEBUG
        print("🎨 Applied theme preset: \(preset.name)")
        #endif
    }
}
