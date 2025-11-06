import Combine
import Foundation
#if os(macOS)
import AppKit
#endif

@MainActor
final class AppCoordinator: ObservableObject {
    
    enum Sheet: Identifiable {
        case welcome
        case createDevice
        case settings
        
        var id: String {
            switch self {
            case .welcome: return "welcome"
            case .createDevice: return "createDevice"
            case .settings: return "settings"
            }
        }
    }
    
    struct RefreshRequest: Identifiable {
        let id = UUID()
        let force: Bool
    }
    
    @Published var activeSheet: Sheet?
    
    private let refreshSubject = PassthroughSubject<RefreshRequest, Never>()
    
    var refreshPublisher: AnyPublisher<RefreshRequest, Never> {
        refreshSubject.eraseToAnyPublisher()
    }
    
    func present(_ sheet: Sheet) {
        activeSheet = sheet
    }
    
    func dismissSheet() {
        activeSheet = nil
    }
    
    func showWelcome() {
        present(.welcome)
    }
    
    func showCreateDevice() {
        present(.createDevice)
    }
    
    func showSettings() {
        present(.settings)
    }
    
    func showDiagnostics() {
        present(.welcome)
    }
    
    func requestDeviceRefresh(force: Bool = true) {
        refreshSubject.send(RefreshRequest(force: force))
    }
    
    func showAboutPanel() {
#if os(macOS)
        NSApp.orderFrontStandardAboutPanel(nil)
#endif
    }
    
    func openHelpCenter() {
#if os(macOS)
        guard let url = URL(string: Constants.helpURL) else { return }
        NSWorkspace.shared.open(url)
#endif
    }
}

private extension AppCoordinator {
    enum Constants {
        static let helpURL = "https://github.com/sangwookyoo/PlayHub"
    }
}
