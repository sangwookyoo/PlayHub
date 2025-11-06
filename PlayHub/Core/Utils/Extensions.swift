
import SwiftUI
import Foundation

// MARK: - 컬렉션 확장

extension Collection {
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

// MARK: - 문자열 확장 (로컬라이제이션)

extension String {
    /// Localize this string using NSLocalizedString
    /// - Parameter comment: Optional comment for translators
    /// - Returns: Localized string or original if no localization available
    func loc(_ comment: String = "") -> String {
        let bundle = LocalizationManager.shared.bundle ?? .main
        return NSLocalizedString(self, tableName: nil, bundle: bundle, comment: comment)
    }
    
    /// Localize this string with format arguments
    /// - Parameter args: Arguments to format into the localized string
    /// - Returns: Formatted localized string
    func locf(_ args: CVarArg...) -> String {
        let bundle = LocalizationManager.shared.bundle ?? .main
        let localizedFormat = NSLocalizedString(self, tableName: nil, bundle: bundle, comment: "")
        return String(format: localizedFormat, arguments: args)
    }
}

// MARK: - Task 확장

extension Task where Success == Never, Failure == Never {
    static func sleep(seconds: Double) async throws {
        try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
    }
}

// MARK: - 날짜 확장

extension Date {
    func timeAgo() -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: self, relativeTo: Date())
    }
}

// MARK: - 뷰 확장 (로딩 및 오류 상태)
// BaseViewModel에서 이동한 로딩 상태 관련 UI 확장

extension View {
    /// 조건부 뷰 수정자
    /// 불필요한 뷰를 생성하지 않고 조건부 수정자를 적용
    func `if`<Content: View>(
        _ condition: Bool,
        transform: (Self) -> Content
    ) -> some View {
        Group {
            if condition {
                transform(self)
            } else {
                self
            }
        }
    }
    
    /// 옵셔널 조건부 수정자
    func ifLet<T, Content: View>(
        _ optional: T?,
        transform: (Self, T) -> Content
    ) -> some View {
        Group {
            if let value = optional {
                transform(self, value)
            } else {
                self
            }
        }
    }
}

// MARK: - 알림 확장

extension Notification.Name {
    // App commands
    static let showAboutRequested = Notification.Name("showAboutRequested")
    static let showHelpRequested = Notification.Name("showHelpRequested")
    static let showDiagnosticRequested = Notification.Name("showDiagnosticRequested")
    static let createDeviceRequested = Notification.Name("createDeviceRequested")
    static let refreshDevicesRequested = Notification.Name("refreshDevicesRequested")
    
    // Error handling notifications
    static let errorOccurred = Notification.Name("errorOccurred")
    
    // Data refresh notifications
    static let dataRefreshRequested = Notification.Name("dataRefreshRequested")
}
