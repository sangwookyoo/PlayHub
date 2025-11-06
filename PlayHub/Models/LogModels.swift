import SwiftUI

// MARK: - 로그 레벨

/// 로그 레벨 정의 - 시스템 전체에서 사용하는 단일 타입
enum LogLevel: String, CaseIterable, Identifiable {
    case debug = "DEBUG"
    case info = "INFO"
    case success = "SUCCESS"
    case warning = "WARNING"
    case error = "ERROR"
    
    var id: String { rawValue }
    
    var color: Color {
        switch self {
        case .debug: return DesignSystem.Colors.textSecondary
        case .info: return DesignSystem.Colors.info
        case .success: return DesignSystem.Colors.success
        case .warning: return DesignSystem.Colors.warning
        case .error: return DesignSystem.Colors.error
        }
    }
    
    var icon: String {
        switch self {
        case .debug: return "ant.fill"
        case .info: return "info.circle.fill"
        case .success: return "checkmark.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .error: return "xmark.circle.fill"
        }
    }
    
    /// 표시용 이름 (대소문자 적절히 조정)
    var displayName: String {
        switch self {
        case .debug: return "Debug"
        case .info: return "Info"
        case .success: return "Success"
        case .warning: return "Warning"
        case .error: return "Error"
        }
    }
}

// MARK: - 로그 항목 (디바이스 로그용)

struct LogEntry: Identifiable {
    let id = UUID()
    let timestamp: Date
    let level: LogLevel
    let tag: String
    let message: String
    
    var formatted: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        return "[\(formatter.string(from: timestamp))] [\(level.rawValue)] [\(tag)] \(message)"
    }
}

// MARK: - 진단 로그 (시스템 진단용)

struct DiagnosticLog: Identifiable {
    let id = UUID()
    let timestamp: Date
    let level: LogLevel
    let message: String
    
    var formatted: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return "[\(formatter.string(from: timestamp))] \(level.rawValue): \(message)"
    }
}

// MARK: - 수정 결과 (진단 수정 결과용)

struct FixResult: Identifiable {
    let id = UUID()
    let title: String
    let success: Bool
    let message: String
    let timestamp: Date
    
    init(title: String, success: Bool, message: String) {
        self.title = title
        self.success = success
        self.message = message
        self.timestamp = Date()
    }
}