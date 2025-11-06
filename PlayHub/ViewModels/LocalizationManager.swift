import Foundation
import Combine

// MARK: - Language Support Types

struct Language: Identifiable, Equatable {
    let code: String
    let nativeName: String
    let englishName: String
    let flag: String

    var id: String { code }
    
    static func == (lhs: Language, rhs: Language) -> Bool {
        lhs.code == rhs.code
    }
}

struct SupportedLanguage: Identifiable, Equatable {
    let code: String
    let name: String
    let nativeName: String

    var id: String { code }
    
    static func == (lhs: SupportedLanguage, rhs: SupportedLanguage) -> Bool {
        lhs.code == rhs.code
    }
}

private struct LanguageMetadata {
    let code: String
    let nativeName: String
    let englishName: String
    let flag: String
    
    var supportedLanguage: SupportedLanguage {
        SupportedLanguage(code: code, name: englishName, nativeName: nativeName)
    }
    
    var language: Language {
        Language(code: code, nativeName: nativeName, englishName: englishName, flag: flag)
    }
}

/// Localization and multi-language support manager
/// Handles language switching and localized string management
@MainActor
final class LocalizationManager: ObservableObject {
    
    // MARK: - Singleton
    
    static let shared = LocalizationManager()
    
    // MARK: - Published Properties
    
    /// Current language code (nil for system default)
    @Published var currentLanguage: String? = nil {
        didSet {
            updateTrigger += 1 // Trigger UI updates
        }
    }
    
    /// Update trigger for SwiftUI views
    /// Increment this to force view updates when language changes
    @Published var updateTrigger: Int = 0
    
    /// The bundle for the current language
    var bundle: Bundle? {
        guard let languageCode = currentLanguage, 
              let path = Bundle.main.path(forResource: languageCode, ofType: "lproj") else {
            return nil
        }
        return Bundle(path: path)
    }
    
    /// Available languages in the app (일본어 추가)
    @Published var availableLanguages: [SupportedLanguage] = LocalizationManager.languageCatalog.map(\.supportedLanguage)
    
    /// Supported languages with additional display info (일본어 추가)
    var supportedLanguages: [Language] {
        var languages = LocalizationManager.languageCatalog.map(\.language)
        languages.insert(
            Language(code: "system", nativeName: "System Default", englishName: "System Default", flag: "🌍"),
            at: 0
        )
        return languages
    }
    
    // MARK: - Private Properties
    
    private let userDefaults = UserDefaults.standard
    private static let languageCatalog: [LanguageMetadata] = [
        LanguageMetadata(code: "en", nativeName: "English", englishName: "English", flag: "🇺🇸"),
        LanguageMetadata(code: "ko", nativeName: "한국어", englishName: "Korean", flag: "🇰🇷"),
        LanguageMetadata(code: "ja", nativeName: "日本語", englishName: "Japanese", flag: "🇯🇵"),
        LanguageMetadata(code: "zh-Hans", nativeName: "简体中文", englishName: "Chinese (Simplified)", flag: "🇨🇳"),
        LanguageMetadata(code: "zh-Hant", nativeName: "繁體中文", englishName: "Chinese (Traditional)", flag: "🇹🇼"),
        LanguageMetadata(code: "de", nativeName: "Deutsch", englishName: "German", flag: "🇩🇪"),
        LanguageMetadata(code: "fr", nativeName: "Français", englishName: "French", flag: "🇫🇷"),
        LanguageMetadata(code: "es", nativeName: "Español", englishName: "Spanish", flag: "🇪🇸")
    ]
    
    // MARK: - UserDefaults Keys
    
    private enum Keys {
        static let selectedLanguage = "app.selected.language"
    }
    
    // MARK: - Initialization
    
    private init() {
        loadSavedLanguage()
        
        #if DEBUG
        print("🌍 LocalizationManager initialized with language: \(currentLanguage ?? "system")")
        #endif
    }
    
    // MARK: - Public Methods
    
    /// Change the app language
    /// - Parameter languageCode: Language code ("en", "ko", "ja", etc.) or nil for system default
    func setLanguage(_ languageCode: String?) {
        let newLanguage = languageCode == "system" ? nil : languageCode
        
        guard newLanguage != currentLanguage else { return }
        
        currentLanguage = newLanguage
        saveLanguage()
        
        #if DEBUG
        print("🌍 Language changed to: \(newLanguage ?? "system")")
        #endif
    }
    
    /// AppLanguage enum과 호환되도록 업데이트
    func setLanguage(_ appLanguage: AppLanguage) {
        setLanguage(appLanguage.code)
    }
    
    /// Get the display name for a language code
    /// - Parameter code: Language code
    /// - Returns: Display name or the code itself if not found
    func displayName(for code: String?) -> String {
        guard let code = code else { return "System" }
        return availableLanguages.first(where: { $0.code == code })?.nativeName ?? code
    }
    
    /// Check if a language is currently selected
    /// - Parameter code: Language code to check
    /// - Returns: True if the language is currently active
    func isLanguageSelected(_ code: String?) -> Bool {
        return currentLanguage == code
    }
    
    /// Get localized string with current language context
    /// This method provides additional context that can be used by
    /// more sophisticated localization systems if needed
    /// - Parameters:
    ///   - key: Localization key
    ///   - defaultValue: Default value if key is not found
    /// - Returns: Localized string
    func localizedString(_ key: String, defaultValue: String? = nil) -> String {
        let localized = NSLocalizedString(key, comment: "")
        
        // If the localized string is the same as the key, it means no translation was found
        if localized == key && defaultValue != nil {
            return defaultValue!
        }
        
        return localized
    }
    
    /// Refresh localization (useful after language pack updates)
    func refreshLocalization() {
        updateTrigger += 1
        
        #if DEBUG
        print("🔄 Localization refreshed")
        #endif
    }
    
    // MARK: - Private Methods
    
    private func loadSavedLanguage() {
        currentLanguage = userDefaults.string(forKey: Keys.selectedLanguage)
    }
    
    private func saveLanguage() {
        if let language = currentLanguage {
            userDefaults.set(language, forKey: Keys.selectedLanguage)
        } else {
            userDefaults.removeObject(forKey: Keys.selectedLanguage)
        }
    }
    

}

// MARK: - Language Detection Utilities

extension LocalizationManager {
    
    /// Get system's preferred language code
    var systemLanguage: String? {
        return Locale.current.language.languageCode?.identifier
    }
    
    /// Get all system preferred languages
    var systemLanguages: [String] {
        return Locale.preferredLanguages
    }
    
    /// Check if right-to-left language is active
    var isRTL: Bool {
        guard let language = currentLanguage ?? systemLanguage else { return false }
        
        // Common RTL language codes
        let rtlLanguages = ["ar", "he", "fa", "ur", "ps", "sd"]
        return rtlLanguages.contains(language)
    }
}
