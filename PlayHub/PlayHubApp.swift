#if os(macOS)
import AppKit
#endif
import SwiftUI

@main
@MainActor
struct PlayHubApp: App {
    private let environment: AppEnvironmentProtocol
    
    @StateObject private var localizationManager: LocalizationManager
    @StateObject private var themeManager: ThemeManager
    @StateObject private var settingsManager: SettingsManager

    init(environment: AppEnvironmentProtocol) {
        self.environment = environment
        _localizationManager = StateObject(wrappedValue: environment.localization)
        _themeManager = StateObject(wrappedValue: environment.theme)
        _settingsManager = StateObject(wrappedValue: environment.settings)
#if os(macOS)
        Self.setupWindowAppearance()
#endif
    }

    init() {
        self.init(environment: AppEnvironment.shared)
    }
    
    var body: some Scene {
        WindowGroup {
            mainScene
        }
#if os(macOS)
        .windowStyle(.hiddenTitleBar)
        .windowToolbarStyle(.unified(showsTitle: false))
        .commands { configureMenuCommands() }
#endif

#if os(macOS)
        Settings {
            SettingsView()
                .environmentObject(settingsManager)
                .environmentObject(localizationManager)
                .environmentObject(themeManager)
        }
#endif
    }
    
#if os(macOS)
    private static func setupWindowAppearance() {
        NSWindow.allowsAutomaticWindowTabbing = false
        DispatchQueue.main.async {
            if let window = NSApplication.shared.windows.first {
                window.minSize = NSSize(width: Constants.Window.minWidth, height: Constants.Window.minHeight)
                window.titlebarAppearsTransparent = true
                window.titleVisibility = .hidden
            }
        }
    }
    
    private static func applyAppearance(theme: AppTheme) {
        let appearanceName: NSAppearance.Name = (theme == .dark) ? .darkAqua : .aqua
        
        if let appearance = NSAppearance(named: appearanceName) {
            NSApp.appearance = appearance
        } else {
            print("⚠️ Failed to create NSAppearance with name: \(appearanceName), using system default")
            NSApp.appearance = nil
        }
    }
    
    private func configureAppearance() {
        Self.applyAppearance(theme: themeManager.currentTheme)
    }
#endif

    @ViewBuilder
    private var mainScene: some View {
        let content = MainView(environment: environment)
            .environmentObject(localizationManager)
            .environmentObject(themeManager)
            .environmentObject(settingsManager)
#if os(macOS)
        content
            .frame(minWidth: Constants.Window.minWidth, minHeight: Constants.Window.minHeight)
            .preferredColorScheme(themeManager.currentTheme.colorScheme)
            .onAppear { configureAppearance() }
            .onChange(of: themeManager.currentTheme) { _, newTheme in
                Self.applyAppearance(theme: newTheme)
            }
#else
        content
#endif
    }
}

#if os(macOS)
private extension PlayHubApp {
    @CommandsBuilder
    func configureMenuCommands() -> some Commands {
        CommandGroup(replacing: .appInfo) {
            Button("about.app".loc()) {
                NotificationCenter.default.post(name: .showAboutRequested, object: nil)
            }
        }
        
        CommandGroup(replacing: .newItem) {
            Button("devices.create".loc()) {
                NotificationCenter.default.post(name: .createDeviceRequested, object: nil)
            }
            .keyboardShortcut("n", modifiers: .command)
        }
        
        CommandGroup(after: .pasteboard) {
            Divider()
        }
        
        CommandMenu("menu.view".loc()) {
            Button("menu.refresh".loc()) {
                NotificationCenter.default.post(name: .refreshDevicesRequested, object: nil)
            }
            .keyboardShortcut("r", modifiers: .command)
            
            Divider()
            
            Button("menu.diagnostic".loc()) {
                NotificationCenter.default.post(name: .showDiagnosticRequested, object: nil)
            }
            .keyboardShortcut("d", modifiers: [.command, .shift])
        }
        
        CommandGroup(replacing: .windowSize) {
            EmptyView()
        }
        
        CommandGroup(replacing: .help) {
            Button("menu.help".loc()) {
                NotificationCenter.default.post(name: .showHelpRequested, object: nil)
            }
            .keyboardShortcut("?", modifiers: .command)
            
            Divider()
            
            Group {
                if let url = URL(string: Constants.URLs.githubRepository) {
                    Link("menu.github".loc(), destination: url)
                } else {
                    EmptyView()
                }
            }
        }
    }
}

private extension PlayHubApp {
    enum Constants {
        enum Window {
            static let minWidth: CGFloat = 1200
            static let minHeight: CGFloat = 800
        }
        enum URLs {
            static let githubRepository = "https://github.com/sangwookyoo/PlayHub"
        }
    }
}
#endif
