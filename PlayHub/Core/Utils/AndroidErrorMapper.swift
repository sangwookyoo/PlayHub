
import Foundation

// MARK: - 안드로이드 오류 매퍼

struct AndroidErrorMapper {
    static func toAppError(_ error: Error) -> AppError {
        if let error = error as? AppError {
            return error
        }
        // 여기에 특정 안드로이드 오류 매핑 추가
        return .unknown("안드로이드 서비스 오류: \(error.localizedDescription)")
    }
}
