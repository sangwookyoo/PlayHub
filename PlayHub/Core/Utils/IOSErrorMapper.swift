
import Foundation

// MARK: - iOS 오류 매퍼

struct IOSErrorMapper {
    static func toAppError(_ error: Error) -> AppError {
        if let error = error as? AppError {
            return error
        }
        // 여기에 특정 iOS 오류 매핑 추가
        return .unknown("iOS 서비스 오류: \(error.localizedDescription)")
    }
}
