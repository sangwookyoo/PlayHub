import Foundation
import SwiftUI
import Combine
import OSLog

// MARK: - 앱 에러 타입

enum AppError: LocalizedError, Equatable {
    case deviceNotFound(String)
    case deviceConnectionFailed(String)
    case deviceCommandFailed(String, underlying: String?)
    case deviceUnavailable(String)
    case networkError(NetworkErrorType)
    case apiError(Int, String)
    case timeoutError
    case fileNotFound(String)
    case fileAccessDenied(String)
    case diskSpaceInsufficient
    case invalidInput(String)
    case missingRequiredField(String)
    case formatError(String)
    case unauthorized
    case forbidden
    case tokenExpired
    case insufficientPermissions
    case systemResourceUnavailable
    case configurationError(String)
    case unsupportedFeature(String)
    case unknown(String)

    var errorDescription: String? {
        switch self {
        case .deviceNotFound(let deviceName):
            return "error.device.not_found".locf(deviceName)
        case .deviceConnectionFailed(let deviceName):
            return "error.device.connection_failed".locf(deviceName)
        case .deviceCommandFailed(let command, let underlying):
            let base = "error.device.command_failed".locf(command)
            if let u = underlying { return "\(base): \(u)" }
            return base
        case .deviceUnavailable(let deviceName):
            return "error.device.unavailable".locf(deviceName)
        case .networkError(let n):
            return n.localizedDescription
        case .apiError(let code, let message):
            return "error.api.general".locf(String(code), message)
        case .timeoutError:
            return "error.network.timeout".loc()
        case .fileNotFound(let name):
            return "error.file.not_found".locf(name)
        case .fileAccessDenied(let name):
            return "error.file.access_denied".locf(name)
        case .diskSpaceInsufficient:
            return "error.file.disk_space".loc()
        case .invalidInput(let field):
            return "error.validation.invalid_input".locf(field)
        case .missingRequiredField(let field):
            return "error.validation.missing_required".locf(field)
        case .formatError(let field):
            return "error.validation.format_error".locf(field)
        case .unauthorized:
            return "error.auth.unauthorized".loc()
        case .forbidden:
            return "error.auth.forbidden".loc()
        case .tokenExpired:
            return "error.auth.token_expired".loc()
        case .insufficientPermissions:
            return "error.system.insufficient_permissions".loc()
        case .systemResourceUnavailable:
            return "error.system.resource_unavailable".loc()
        case .configurationError(let details):
            return "error.system.configuration".locf(details)
        case .unsupportedFeature(let feature):
            return "error.unsupported_feature".locf(feature)
        case .unknown(let msg):
            return "error.unknown".locf(msg)
        }
    }

    var failureReason: String? {
        switch self {
        case .deviceNotFound, .deviceUnavailable: return "error.reason.device_not_available".loc()
        case .deviceConnectionFailed: return "error.reason.connection_issues".loc()
        case .networkError, .timeoutError: return "error.reason.network_issues".loc()
        case .fileAccessDenied, .insufficientPermissions: return "error.reason.permission_issues".loc()
        case .diskSpaceInsufficient: return "error.reason.storage_issues".loc()
        default: return nil
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .deviceNotFound: return "error.recovery.check_device_connection".loc()
        case .deviceConnectionFailed: return "error.recovery.restart_device".loc()
        case .networkError, .timeoutError: return "error.recovery.check_network".loc()
        case .fileAccessDenied, .insufficientPermissions: return "error.recovery.check_permissions".loc()
        case .diskSpaceInsufficient: return "error.recovery.free_disk_space".loc()
        case .tokenExpired: return "error.recovery.reauth".loc()
        default: return "error.recovery.try_again".loc()
        }
    }
}

enum NetworkErrorType: LocalizedError, Equatable {
    case noConnection, serverUnreachable, badResponse, invalidURL, requestFailed(Int)
    
    var errorDescription: String? {
        switch self {
        case .noConnection: return "error.network.no_connection".loc()
        case .serverUnreachable: return "error.network.server_unreachable".loc()
        case .badResponse: return "error.network.bad_response".loc()
        case .invalidURL: return "error.network.invalid_url".loc()
        case .requestFailed(let code): return "error.network.request_failed".locf(String(code))
        }
    }
}

enum ErrorSeverity: Int, CaseIterable {
    case low = 1, medium, high, critical
    
    var displayName: String {
        switch self {
        case .low: return "error.severity.low".loc()
        case .medium: return "error.severity.medium".loc()
        case .high: return "error.severity.high".loc()
        case .critical: return "error.severity.critical".loc()
        }
    }
    
    var color: Color {
        switch self {
        case .low: return .blue
        case .medium: return .yellow
        case .high: return .orange
        case .critical: return .red
        }
    }
}

// MARK: - 에러 컨텍스트 및 핸들러

struct ErrorContext: Identifiable, Equatable {
    let id = UUID()
    let error: AppError
    let severity: ErrorSeverity
    let timestamp: Date
    let userId: String?
    let deviceInfo: [String: String]
    let additionalInfo: [String: Any]
    
    init(error: AppError, severity: ErrorSeverity = .medium, userId: String? = nil, deviceInfo: [String: String] = [:], additionalInfo: [String: Any] = [:]) {
        self.error = error
        self.severity = severity
        self.timestamp = Date()
        self.userId = userId
        self.deviceInfo = deviceInfo
        self.additionalInfo = additionalInfo
    }
    
    static func == (lhs: ErrorContext, rhs: ErrorContext) -> Bool {
        lhs.id == rhs.id
    }
}

final class ErrorHandler: ObservableObject {
    static let shared = ErrorHandler()
    @Published var currentError: ErrorContext?
    @Published var errorHistory: [ErrorContext] = []

    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "PlayHub", category: "ErrorHandler")
    private let maxHistoryCount = 100
    
    private init() {}

    // AppError 전용 처리 메서드
    func handle(_ error: AppError, severity: ErrorSeverity = .medium, shouldDisplay: Bool = true, additionalInfo: [String: Any] = [:]) {
        let context = ErrorContext(error: error, severity: severity, additionalInfo: additionalInfo)
        logError(context)
        addToHistory(context)
        if shouldDisplay { DispatchQueue.main.async { self.currentError = context } }
        if severity == .critical { reportCriticalError(context) }
    }

    // 일반 Error를 AppError로 변환하여 처리하는 메서드
    func handleGenericError(_ error: Error, severity: ErrorSeverity = .medium, context: String = "") {
        let appError: AppError
        if let existingAppError = error as? AppError {
            appError = existingAppError
        } else {
            appError = .unknown("\(context): \(error.localizedDescription)")
        }
        // AppError 전용 메서드 호출 (재귀 방지)
        handle(appError, severity: severity)
    }

    func clearCurrentError() {
        DispatchQueue.main.async { self.currentError = nil }
    }
    
    func clearHistory() {
        DispatchQueue.main.async { self.errorHistory.removeAll() }
    }

    private func logError(_ context: ErrorContext) {
        let message = """
        Error: \(context.error.errorDescription ?? "Unknown error")
        Severity: \(context.severity.displayName)
        Timestamp: \(context.timestamp)
        Additional Info: \(context.additionalInfo)
        """
        switch context.severity {
        case .low: logger.info("\(message)")
        case .medium: logger.notice("\(message)")
        case .high: logger.error("\(message)")
        case .critical: logger.critical("\(message)")
        }
    }

    private func addToHistory(_ context: ErrorContext) {
        DispatchQueue.main.async {
            self.errorHistory.insert(context, at: 0)
            if self.errorHistory.count > self.maxHistoryCount {
                self.errorHistory.removeLast()
            }
        }
    }

    private func reportCriticalError(_ context: ErrorContext) {
        #if DEBUG
        print("CRITICAL: \(context.error)")
        #endif
    }
}

// MARK: - 복구 전략 및 알림 뷰

struct ErrorRecoveryStrategy {
    let title: String
    let action: () async -> Bool

    static func retry(_ op: @escaping () async throws -> Void) -> ErrorRecoveryStrategy {
        ErrorRecoveryStrategy(title: "error.recovery.retry".loc()) {
            do { try await op(); return true } catch { return false }
        }
    }
    
    static func refresh() -> ErrorRecoveryStrategy {
        ErrorRecoveryStrategy(title: "error.recovery.refresh".loc()) {
            AppEnvironment.shared.coordinator.requestDeviceRefresh()
            return true
        }
    }
    
    static func reconnect() -> ErrorRecoveryStrategy {
        ErrorRecoveryStrategy(title: "error.recovery.reconnect".loc()) {
            do { try await Task.sleep(nanoseconds: 1_000_000_000); return true } catch { return false }
        }
    }
}

struct ErrorAlertView: View {
    let context: ErrorContext
    let recoveryStrategies: [ErrorRecoveryStrategy]
    let onDismiss: () -> Void
    @State private var isRecovering = false

    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 12) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(context.severity.color)
                    .font(.system(size: 24))
                
                Text(context.severity.displayName)
                    .font(.headline)
                    .foregroundColor(context.severity.color)
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Group {
                    if let description = context.error.errorDescription {
                        Text(description)
                            .font(.body)
                            .foregroundColor(.primary)
                    } else {
                        EmptyView()
                    }
                }
                
                Group {
                    if let suggestion = context.error.recoverySuggestion {
                        Text(suggestion)
                            .font(.callout)
                            .foregroundColor(.secondary)
                    } else {
                        EmptyView()
                    }
                }
            }
            
            Group {
                if !recoveryStrategies.isEmpty {
                    HStack(spacing: 12) {
                        ForEach(recoveryStrategies, id: \.title) { strategy in
                            Button(action: {
                                Task {
                                    isRecovering = true
                                    let ok = await strategy.action()
                                    isRecovering = false
                                    if ok { onDismiss() }
                                }
                            }) {
                                Text(strategy.title)
                            }
                            .disabled(isRecovering)
                        }
                        
                        Button(action: onDismiss) {
                            Text("error.action.dismiss".loc())
                        }
                    }
                } else {
                    Button(action: onDismiss) {
                        Text("error.action.ok".loc())
                    }
                }
            }
        }
        .padding(20)
        .background(Color(.controlBackgroundColor))
        .cornerRadius(12)
        .shadow(radius: 8)
    }
}

// MARK: - 수식자

struct ErrorHandlingModifier: ViewModifier {
    @ObservedObject private var errorHandler = ErrorHandler.shared
    @State private var showAlert = false
    private var currentErrorID: UUID? { errorHandler.currentError?.id }

    func body(content: Content) -> some View {
        content
            .onChange(of: currentErrorID) { _, _ in
                showAlert = (errorHandler.currentError != nil)
            }
            .sheet(isPresented: $showAlert, onDismiss: { errorHandler.clearCurrentError() }) {
                Group {
                    if let context = errorHandler.currentError {
                        ErrorAlertView(
                            context: context,
                            recoveryStrategies: defaultStrategies(for: context),
                            onDismiss: { errorHandler.clearCurrentError() }
                        )
                        .frame(minWidth: 400)
                    } else {
                        EmptyView()
                    }
                }
            }
    }

    private func defaultStrategies(for context: ErrorContext) -> [ErrorRecoveryStrategy] {
        [.refresh()]
    }
}

// MARK: - 뷰 확장

extension View {
    func withErrorHandling() -> some View {
        modifier(ErrorHandlingModifier())
    }
}
