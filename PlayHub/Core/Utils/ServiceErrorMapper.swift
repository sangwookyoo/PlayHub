import Foundation

/// 이전 레거시 `ServiceErrorMapper` 참조와의 하위 호환성을 위한 어댑터입니다.
/// 실제 매핑과 로깅은 `ErrorMapper`에 위임합니다.
struct ServiceErrorMapper {

    /// 필요 시 에러를 로깅하고, 컨텍스트와 함께 `AppError`로 변환합니다.
    /// - Parameters:
    ///   - error: 원본 에러
    ///   - context: 선택적 컨텍스트 문자열
    /// - Returns: 매핑된 `AppError`
    static func logAndConvert(_ error: Error, context: String = "") -> AppError {
        // 진단을 위한 최소 로깅
        #if DEBUG
        if context.isEmpty {
            print("[ServiceErrorMapper] converting error: \(error)")
        } else {
            print("[ServiceErrorMapper] [\(context)] converting error: \(error)")
        }
        #endif

        if context.isEmpty {
            return .unknown("An unexpected error occurred.")
        } else {
            return .unknown("An unexpected error occurred in \(context).")
        }
    }
}
