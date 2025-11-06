
import SwiftUI
import Combine
import UniformTypeIdentifiers

@MainActor
class DiagnosticViewModel: ObservableObject {
    @Published var systemRequirements: SystemRequirements?
    @Published var isChecking = false
    @Published var diagnosticLogs: [DiagnosticLog] = []
    @Published var fixResults: [FixResult] = []
    
    private let settingsManager = SettingsManager()
    
    func runDiagnostics() async {
        isChecking = true
        diagnosticLogs.removeAll()
        
        addLog("Starting diagnostics...", level: .info)
        
        let diagnostics = SystemDiagnostics(settingsManager: settingsManager)
        systemRequirements = await diagnostics.checkSystemRequirements()
        
        if let requirements = systemRequirements {
            if requirements.xcodeInstalled.isInstalled {
                addLog("Xcode is installed at \(requirements.xcodeInstalled.path)", level: .success)
            } else {
                addLog("Xcode is not installed.", level: .error)
            }
            
            if requirements.simctlAvailable.isInstalled {
                addLog("Simulator control (simctl) is available.", level: .success)
            } else {
                addLog("Simulator control (simctl) is not available.", level: .error)
            }
            
            if requirements.adbAvailable.isInstalled {
                addLog("Android Debug Bridge (adb) is available at \(requirements.adbAvailable.path)", level: .success)
            } else {
                addLog("Android Debug Bridge (adb) is not available.", level: .error)
            }
        }
        
        isChecking = false
    }
    
    func exportLogs() {
        let panel = NSSavePanel()
        panel.nameFieldStringValue = "diagnostics_\(Date().timeIntervalSince1970).txt"
        panel.allowedContentTypes = [.plainText]
        panel.begin { response in
            if response == .OK, let url = panel.url {
                let content = self.diagnosticLogs.map { $0.formatted }.joined(separator: "\n")
                try? content.write(to: url, atomically: true, encoding: .utf8)
            }
        }
    }
    
    func resetXcodeCache() async {
        // Implement reset Xcode cache logic here
    }
    
    func resetSimulators() async {
        // Implement reset simulators logic here
    }
    
    private func addLog(_ message: String, level: LogLevel) {
        diagnosticLogs.append(DiagnosticLog(timestamp: Date(), level: level, message: message))
    }
}
