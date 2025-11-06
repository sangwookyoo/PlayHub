import SwiftUI
#if os(macOS)
import AppKit
#endif
import Combine

struct SettingsView: View {
    @EnvironmentObject private var settingsManager: SettingsManager
    @EnvironmentObject private var localizationManager: LocalizationManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedTab: SettingsTab = .general
    @State private var validationResults: [String: Bool] = [:]
    @State private var isValidating = false
    
    var body: some View {
        // Apply consistent layout structure like CreateDeviceView
        VStack(spacing: 0) {
            enhancedHeader
            Divider()
                .background(StyleGuide.Color.outline.opacity(0.5))
            enhancedContent
        }
        .background(StyleGuide.Color.canvas)
        .frame(width: 960, height: 600) // Fixed frame to prevent resizing
    }
    
    private var enhancedHeader: some View {
        HStack(spacing: StyleGuide.Spacing.xl) {
            // Settings icon with enhanced styling matching CreateDeviceView
            AccentIconBadge(
                systemName: "gearshape.fill",
                size: 60
            )
            
            VStack(alignment: .leading, spacing: StyleGuide.Spacing.xs) {
                Text("settings.title".loc())
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(StyleGuide.Color.textPrimary)
                
                Text("settings.subtitle".loc())
                    .font(StyleGuide.Typography.callout.weight(.medium))
                    .foregroundColor(StyleGuide.Color.textSecondary)
            }
            
            Spacer()
            
            Button(action: { dismiss() }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(StyleGuide.Color.textTertiary)
            }
            .buttonStyle(.plain)
            .minHitArea()
        }
        .padding(.horizontal, StyleGuide.Spacing.xxxl)
        .padding(.vertical, StyleGuide.Spacing.xxl)
        .background(
            StyleGuide.Color.surface.opacity(0.95)
        )
    }
    
    private var enhancedContent: some View {
        HStack(spacing: StyleGuide.Spacing.xxl) {
            sidebar
            Divider()
                .background(StyleGuide.Color.outline)
                .padding(.vertical, StyleGuide.Spacing.xl)
            detailView
        }
        .padding(.horizontal, StyleGuide.Spacing.xxxl)
        .padding(.vertical, StyleGuide.Spacing.xl)
    }
    
    private var sidebar: some View {
        VStack(alignment: .leading, spacing: StyleGuide.Spacing.xl) {
            ForEach(SettingsTab.allCases) { tab in
                Button {
                    withAnimation(StyleGuide.Animation.quick) {
                        selectedTab = tab
                    }
                } label: {
                    HStack(spacing: StyleGuide.Spacing.lg) {
                        Image(systemName: tab.icon)
                            .frame(width: 24, height: 24)
                            .foregroundStyle(tab == selectedTab ? StyleGuide.Color.accent : StyleGuide.Color.textSecondary)
                        
                        VStack(alignment: .leading, spacing: StyleGuide.Spacing.xs) {
                            Text(tab.title)
                                .font(StyleGuide.Typography.callout.weight(.medium))
                                .foregroundStyle(tab == selectedTab ? StyleGuide.Color.accent : StyleGuide.Color.textPrimary)
                            Text(tab.subtitle)
                                .font(StyleGuide.Typography.caption)
                                .foregroundStyle(StyleGuide.Color.textSecondary)
                        }
                        
                        Spacer()
                        
                        Image(systemName: StyleGuide.Icon.success)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(StyleGuide.Color.accent)
                            .opacity(tab == selectedTab ? 1 : 0)
                            .frame(width: 16, height: 16)
                    }
                    .padding(.horizontal, StyleGuide.Spacing.xl)
                    .padding(.vertical, StyleGuide.Spacing.md)
                    .background(
                        RoundedRectangle(cornerRadius: StyleGuide.Radius.lg)
                            .fill(tab == selectedTab ? StyleGuide.Color.accent.opacity(StyleGuide.Opacity.subtle) : Color.clear)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: StyleGuide.Radius.lg)
                            .stroke(
                                tab == selectedTab ? StyleGuide.Color.accent.opacity(StyleGuide.Opacity.light) : Color.clear,
                                lineWidth: 1
                            )
                    )
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
                }
                .buttonStyle(StableButtonStyle())
                .minHitArea()
            }
            
            Spacer()
        }
        .frame(width: 280, alignment: .leading) // Fixed sidebar width
    }
    
    @ViewBuilder
    private var detailView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: StyleGuide.Spacing.xxl) {
                switch selectedTab {
                case .general:
                    GeneralSettingsCard()
                case .paths:
                    PathSettingsCard(validationResults: $validationResults, isValidating: $isValidating) {
                        await validatePaths()
                    }
                case .language:
                    LanguageSettingsCard()
                }
            }
            .padding(.top, StyleGuide.Spacing.xl)
            .padding(.bottom, StyleGuide.Spacing.xxxl)
            .padding(.horizontal, StyleGuide.Spacing.xxl)
        }
        .frame(width: 600) // Fixed detail view width
    }
    
    @MainActor
    private func validatePaths() async {
        guard !isValidating else { return }
        isValidating = true
        defer { isValidating = false }
        
        let results = settingsManager.validatePaths()
        withAnimation(StyleGuide.Animation.gentle) {
            validationResults = results
        }
    }
}

// MARK: - Tabs

private enum SettingsTab: String, CaseIterable, Identifiable {
    case general, paths, language
    
    var id: String { rawValue }
    
    var title: String {
        switch self {
        case .general: return "settings.tab.general".loc()
        case .paths: return "settings.tab.paths".loc()
        case .language: return "settings.tab.language".loc()
        }
    }
    
    var subtitle: String {
        switch self {
        case .general: return "settings.tab.general.subtitle".loc()
        case .paths: return "settings.tab.paths.subtitle".loc()
        case .language: return "settings.tab.language.subtitle".loc()
        }
    }
    
    var icon: String {
        switch self {
        case .general: return "info.circle"
        case .paths: return "folder"
        case .language: return "globe"
        }
    }
}

// MARK: - General Card

private struct GeneralSettingsCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: StyleGuide.Spacing.xl) {
            SettingsSectionHeader(
                title: "settings.general.title".loc(),
                subtitle: "App information and version details",
                icon: "info.circle",
                tint: StyleGuide.Color.info
            )
            
            Grid(alignment: .leading, horizontalSpacing: StyleGuide.Spacing.xl, verticalSpacing: StyleGuide.Spacing.lg) {
                GridRow {
                    SettingsInfoRow(title: "settings.general.app_name".loc(), value: "PlayHub")
                    SettingsInfoRow(title: "settings.general.version".loc(), value: Bundle.main.appVersion)
                }
                GridRow {
                    SettingsInfoRow(title: "settings.general.build".loc(), value: Bundle.main.buildNumber)
                    SettingsInfoRow(title: "settings.general.bundle".loc(), value: Bundle.main.bundleIdentifier ?? "-")
                }
            }
        }
        .cardStyle()
        .shadow(color: StyleGuide.Shadow.card.color, radius: StyleGuide.Shadow.card.radius, x: StyleGuide.Shadow.card.x, y: StyleGuide.Shadow.card.y)
    }
}

// MARK: - Path Card

private struct PathSettingsCard: View {
    @EnvironmentObject private var settingsManager: SettingsManager
    @Binding var validationResults: [String: Bool]
    @Binding var isValidating: Bool
    
    let validateAction: () async -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: StyleGuide.Spacing.xxl) {
            HStack {
                SettingsSectionHeader(
                    title: "settings.paths.title".loc(),
                    subtitle: "settings.paths.subtitle".loc(),
                    icon: "folder",
                    tint: StyleGuide.Color.warning
                )
                
                Spacer()
                
                Button {
                    Task { await validateAction() }
                } label: {
                    HStack(spacing: StyleGuide.Spacing.sm) {
                        if isValidating {
                            ProgressView()
                                .progressViewStyle(.circular)
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: StyleGuide.Icon.refresh)
                        }
                        Text("settings.paths.validate".loc())
                            .frame(minWidth: 60) // Prevent text movement
                    }
                    .frame(minWidth: 120) // Ensure stable button size
                }
                .buttonStyle(StableProminentButtonStyle())
                .controlSize(.large)
                .disabled(isValidating)
                .minHitArea()
            }
            
            VStack(alignment: .leading, spacing: StyleGuide.Spacing.xl) {
                SettingsSubsectionHeader(title: "settings.paths.ios.title".loc(), icon: StyleGuide.Icon.iOS)
                
                SettingsPathInfoRow(
                    title: "settings.paths.ios.xcode".loc(),
                    value: "/usr/bin/xcrun",
                    isValid: validationResults["xcode"]
                )
                
                SettingsSubsectionHeader(title: "settings.paths.android.title".loc(), icon: StyleGuide.Icon.android)
                
                SettingsPathEditableRow(
                    title: "settings.paths.android.sdk".loc(),
                    placeholder: "settings.paths.placeholder".loc(),
                    value: $settingsManager.androidSDKPath,
                    isValid: validationResults["android_sdk"]
                )
                
                SettingsPathEditableRow(
                    title: "settings.paths.android.avd".loc(),
                    placeholder: "settings.paths.placeholder".loc(),
                    value: $settingsManager.androidAVDPath,
                    isValid: validationResults["avd_path"]
                )
                
                SettingsPathInfoRow(
                    title: "settings.paths.android.adb".loc(),
                    value: settingsManager.adbPath,
                    isValid: validationResults["adb"]
                )
                
                SettingsPathInfoRow(
                    title: "settings.paths.android.emulator".loc(),
                    value: settingsManager.emulatorPath,
                    isValid: validationResults["emulator"]
                )
            }
        }
        .cardStyle()
        .shadow(color: StyleGuide.Shadow.card.color, radius: StyleGuide.Shadow.card.radius, x: StyleGuide.Shadow.card.x, y: StyleGuide.Shadow.card.y)
    }
}

// MARK: - Enhanced Language Card with List Format

private struct LanguageSettingsCard: View {
    @EnvironmentObject private var localizationManager: LocalizationManager
    @EnvironmentObject private var settingsManager: SettingsManager
    @State private var selectedLanguage: String
    
    init() {
        let initialLanguage = LocalizationManager.shared.currentLanguage ?? "system"
        _selectedLanguage = State(initialValue: initialLanguage)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: StyleGuide.Spacing.xxl) {
            SettingsSectionHeader(
                title: "settings.language.title".loc(),
                subtitle: "settings.language.description".loc(),
                icon: "globe",
                tint: StyleGuide.Color.success
            )
            
            // Enhanced List Format for Better i18n Support
            VStack(spacing: StyleGuide.Spacing.xs) {
                ForEach(localizationManager.supportedLanguages) { language in
                    LanguageListItem(
                        language: language,
                        isSelected: selectedLanguage == language.code
                    ) {
                        withAnimation(StyleGuide.Animation.quick) {
                            selectedLanguage = language.code
                            if let appLanguage = AppLanguage(rawValue: language.code) {
                                settingsManager.selectedLanguage = appLanguage
                                localizationManager.setLanguage(appLanguage)
                            } else {
                                localizationManager.setLanguage(language.code == "system" ? nil : language.code)
                            }
                        }
                    }
                }
            }
            .background(
                RoundedRectangle(cornerRadius: StyleGuide.Radius.lg)
                    .fill(StyleGuide.Color.surfaceSecondary.opacity(0.5))
            )
            .overlay(
                RoundedRectangle(cornerRadius: StyleGuide.Radius.lg)
                    .stroke(StyleGuide.Color.outline.opacity(0.5), lineWidth: 1)
            )
        }
        .cardStyle()
        .onReceive(localizationManager.$currentLanguage) { newValue in
            let code = newValue ?? "system"
            selectedLanguage = code
            if let appLanguage = AppLanguage(rawValue: code),
               settingsManager.selectedLanguage != appLanguage {
                settingsManager.selectedLanguage = appLanguage
            }
        }
        .onReceive(settingsManager.$selectedLanguage) { newValue in
            let code = newValue.rawValue
            if selectedLanguage != code {
                selectedLanguage = code
            }
            localizationManager.setLanguage(newValue)
        }
    }
}

// MARK: - Enhanced Language List Item with Better Hit Area

private struct LanguageListItem: View {
    let language: Language
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: StyleGuide.Spacing.md) {
                // Language flag and name
                HStack(spacing: StyleGuide.Spacing.sm) {
                    Text(language.flag)
                        .font(.system(size: 20))
                    
                    VStack(alignment: .leading, spacing: StyleGuide.Spacing.xs) {
                        Text(language.nativeName)
                            .font(StyleGuide.Typography.body.weight(.medium))
                            .foregroundStyle(StyleGuide.Color.textPrimary)
                        
                        if language.code != "system" {
                            Text(language.englishName)
                                .font(StyleGuide.Typography.caption)
                                .foregroundStyle(StyleGuide.Color.textSecondary)
                        }
                    }
                }
                
                Spacer()
                
                // Selection indicator
                ZStack {
                    Circle()
                        .stroke(
                            isSelected ? StyleGuide.Color.accent : StyleGuide.Color.outline,
                            lineWidth: 2
                        )
                        .frame(width: 20, height: 20)
                    
                    if isSelected {
                        Circle()
                            .fill(StyleGuide.Color.accent)
                            .frame(width: 12, height: 12)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading) // Full width clickable
            .contentShape(Rectangle()) // Make entire area clickable
            .padding(.horizontal, StyleGuide.Spacing.lg)
            .padding(.vertical, StyleGuide.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: StyleGuide.Radius.md)
                    .fill(isSelected ? StyleGuide.Color.accent.opacity(StyleGuide.Opacity.subtle) : Color.clear)
            )
        }
        .buttonStyle(StableButtonStyle())
        .minHitArea()
    }
}

// MARK: - Enhanced Section Headers

private struct SettingsSectionHeader: View {
    let title: String
    let subtitle: String
    let icon: String
    let tint: Color
    
    var body: some View {
        HStack(spacing: StyleGuide.Spacing.md) {
            Image(systemName: icon)
                .font(.system(size: 24, weight: .semibold))
                .foregroundStyle(tint)
                .frame(width: 32, height: 32)
                .background(
                    Circle()
                        .fill(tint.opacity(StyleGuide.Opacity.subtle))
                )
            
            VStack(alignment: .leading, spacing: StyleGuide.Spacing.xs) {
                Text(title)
                    .font(StyleGuide.Typography.title.weight(.semibold))
                    .foregroundColor(StyleGuide.Color.textPrimary)
                Text(subtitle)
                    .font(StyleGuide.Typography.callout)
                    .foregroundColor(StyleGuide.Color.textSecondary)
            }
            
            Spacer()
        }
    }
}

private struct SettingsSubsectionHeader: View {
    let title: String
    let icon: String
    
    var body: some View {
        HStack(spacing: StyleGuide.Spacing.sm) {
            Image(systemName: icon)
                .foregroundStyle(StyleGuide.Color.accent)
            Text(title)
                .foregroundStyle(StyleGuide.Color.textPrimary)
        }
        .font(StyleGuide.Typography.headline.weight(.semibold))
        .padding(.vertical, StyleGuide.Spacing.xs)
    }
}

// MARK: - Enhanced Subviews

private struct SettingsInfoRow: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: StyleGuide.Spacing.xs) {
            Text(title)
                .font(StyleGuide.Typography.caption.weight(.medium))
                .foregroundStyle(StyleGuide.Color.textSecondary)
            Text(value)
                .font(StyleGuide.Typography.body.weight(.medium))
                .foregroundStyle(StyleGuide.Color.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct SettingsPathInfoRow: View {
    let title: String
    let value: String
    let isValid: Bool?
    
    var body: some View {
        VStack(alignment: .leading, spacing: StyleGuide.Spacing.sm) {
            HStack {
                Text(title)
                    .font(StyleGuide.Typography.subheadline.weight(.medium))
                    .foregroundStyle(StyleGuide.Color.textPrimary)
                Spacer()
                if let isValid {
                    SettingsPathStatusIndicator(isValid: isValid)
                }
            }
            
            Text(value.isEmpty ? "–" : value)
                .font(StyleGuide.Typography.callout)
                .foregroundStyle(value.isEmpty ? StyleGuide.Color.textSecondary : StyleGuide.Color.textPrimary)
                .textSelection(.enabled)
                .padding(.horizontal, StyleGuide.Spacing.md)
                .padding(.vertical, StyleGuide.Spacing.sm)
                .background(
                    RoundedRectangle(cornerRadius: StyleGuide.Radius.md)
                        .fill(StyleGuide.Color.surfaceSecondary.opacity(0.5))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: StyleGuide.Radius.md)
                        .stroke(StyleGuide.Color.outline.opacity(0.3), lineWidth: 1)
                )
        }
    }
}

private struct SettingsPathEditableRow: View {
    let title: String
    let placeholder: String
    @Binding var value: String
    let isValid: Bool?
    
    var body: some View {
        VStack(alignment: .leading, spacing: StyleGuide.Spacing.sm) {
            HStack {
                Text(title)
                    .font(StyleGuide.Typography.subheadline.weight(.medium))
                    .foregroundStyle(StyleGuide.Color.textPrimary)
                Spacer()
                if let isValid {
                    SettingsPathStatusIndicator(isValid: isValid)
                }
            }
            
            HStack(spacing: StyleGuide.Spacing.sm) {
                TextField(placeholder, text: $value)
                    .textFieldStyle(.roundedBorder)
                    .font(StyleGuide.Typography.callout)
                
                Button {
                    browsePath { selectedPath in
                        value = selectedPath
                    }
                } label: {
                    HStack(spacing: StyleGuide.Spacing.xs) {
                        Image(systemName: StyleGuide.Icon.browse)
                        Text("browse".loc())
                            .frame(minWidth: 40) // Prevent text movement
                    }
                }
                .buttonStyle(StableBorderedButtonStyle())
                .minHitArea()
            }
            
            // Show current expanded path
            if !value.isEmpty {
                Text("settings.paths.current".locf(NSString(string: value).expandingTildeInPath))
                    .font(StyleGuide.Typography.caption)
                    .foregroundStyle(StyleGuide.Color.textSecondary)
                    .textSelection(.enabled)
            }
        }
    }
}

private struct SettingsPathStatusIndicator: View {
    let isValid: Bool
    
    var body: some View {
        HStack(spacing: StyleGuide.Spacing.xs) {
            Image(systemName: isValid ? StyleGuide.Icon.success : StyleGuide.Icon.warning)
            Text(isValid ? "settings.paths.valid".loc() : "settings.paths.invalid".loc())
        }
        .font(StyleGuide.Typography.caption.weight(.medium))
        .foregroundStyle(isValid ? StyleGuide.Color.success : StyleGuide.Color.warning)
        .padding(.horizontal, StyleGuide.Spacing.sm)
        .padding(.vertical, StyleGuide.Spacing.xs)
        .background(
            RoundedRectangle(cornerRadius: StyleGuide.Radius.sm)
                .fill((isValid ? StyleGuide.Color.successBackground : StyleGuide.Color.warningBackground))
        )
    }
}

// MARK: - Browse Functionality

#if os(macOS)
private func browsePath(completion: @escaping (String) -> Void) {
    let panel = NSOpenPanel()
    panel.canChooseFiles = false
    panel.canChooseDirectories = true
    panel.allowsMultipleSelection = false
    panel.canCreateDirectories = true
    panel.title = "Select Directory"
    panel.prompt = "Choose"
    
    if panel.runModal() == .OK {
        if let url = panel.url {
            completion(url.path)
        }
    }
}
#else
private func browsePath(completion: @escaping (String) -> Void) {
    // Fallback for non-macOS platforms (though this app is macOS-only)
    print("Browse functionality is only available on macOS")
}
#endif

// MARK: - Bundle Helpers

private extension Bundle {
    var appVersion: String {
        infoDictionary?["CFBundleShortVersionString"] as? String ?? "–"
    }
    
    var buildNumber: String {
        infoDictionary?["CFBundleVersion"] as? String ?? "–"
    }
}

#if DEBUG && canImport(SwiftUI) && !os(macOS)
#Preview {
    SettingsView()
        .environmentObject(SettingsManager())
        .environmentObject(LocalizationManager.shared)
}
#endif
