import Foundation
import Combine
import SwiftUI

// MARK: - LoadingState

/// 다양한 로딩 상태를 나타내는 열거형
/// 보다 세밀한 상태 관리를 위해 사용
enum LoadingState: Equatable {
    case idle
    case loading
    case loaded
    case failed(AppError)
    case refreshing
    
    /// 현재 로딩 중인지 확인
    var isLoading: Bool {
        switch self {
        case .loading, .refreshing:
            return true
        default:
            return false
        }
    }
    
    /// 현재 에러 상태 반환
    var error: AppError? {
        if case .failed(let error) = self {
            return error
        }
        return nil
    }
    
    /// 성공적으로 로드된 상태인지 확인
    var isLoaded: Bool {
        if case .loaded = self {
            return true
        }
        return false
    }
}

// MARK: - ViewModelProtocol

/// ViewModel 프로토콜 - 공통 메서드 정의
protocol ViewModelProtocol: ObservableObject {
    var loadingState: LoadingState { get set }
    var lastUpdated: Date? { get set }
    
    func reset()
    func clearError()
    func handleError(_ error: Error)
}

// MARK: - BaseViewModel

/// 모든 ViewModel의 기본 클래스
/// LoadingState 열거형을 사용한 세밀한 상태 관리 제공
@MainActor
open class BaseViewModel: ObservableObject, ViewModelProtocol {
    
    // MARK: - Published Properties
    
    @Published var loadingState: LoadingState = .idle
    @Published var lastUpdated: Date?
    
    // MARK: - Computed Properties
    
    /// 현재 로딩 중인지 확인
    var isLoading: Bool {
        loadingState.isLoading
    }
    
    /// 현재 에러 상태
    var error: AppError? {
        loadingState.error
    }
    
    /// 성공적으로 로드된 상태인지
    var isLoaded: Bool {
        loadingState.isLoaded
    }
    
    // MARK: - Private Properties
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    public init() { }
    
    deinit {
        cancellables.removeAll()
    }
    
    // MARK: - Core Methods
    
    /// 상태와 함께 작업 실행
    /// - Parameters:
    ///   - isRefresh: 새로고침 작업인지 여부
    ///   - operation: 비동기 작업
    /// - Returns: 작업 결과
    func executeWithState<T>(
        isRefresh: Bool = false,
        _ operation: () async throws -> T
    ) async -> T? {
        // 이미 로딩 중이면 중복 실행 방지 (새로고침 제외)
        guard !isLoading || isRefresh else {
            #if DEBUG
            print("⚠️ \(type(of: self)) 이미 로딩 중, 작업 건너뛰기")
            #endif
            return nil
        }
        
        loadingState = isRefresh ? .refreshing : .loading
        
        do {
            let result = try await operation()
            loadingState = .loaded
            lastUpdated = Date()
            
            #if DEBUG
            let operationType = isRefresh ? "새로고침" : "로드"
            print("✅ \(type(of: self)) \(operationType) 성공")
            #endif
            
            return result
        } catch {
            let appError = error as? AppError ?? .unknown(error.localizedDescription)
            loadingState = .failed(appError)
            
            #if DEBUG
            let operationType = isRefresh ? "새로고침" : "로드"
            print("❌ \(type(of: self)) \(operationType) 실패: \(appError)")
            #endif
            
            return nil
        }
    }
    
    /// 에러 상태 클리어 및 idle로 복귀
    func clearError() {
        if case .failed = loadingState {
            loadingState = .idle
        }
    }
    
    /// idle 상태로 초기화
    func reset() {
        loadingState = .idle
        lastUpdated = nil
        
        #if DEBUG
        print("🔄 \(type(of: self)) 상태 초기화")
        #endif
    }
    
    /// 에러 처리 및 상태 업데이트
    /// - Parameter error: 처리할 에러
    func handleError(_ error: Error) {
        let appError = error as? AppError ?? .unknown(error.localizedDescription)
        loadingState = .failed(appError)
        
        // 에러 발생 알림 (Extensions.swift에서 정의된 것 사용)
        NotificationCenter.default.post(name: .errorOccurred, object: appError)
        
        #if DEBUG
        print("❌ \(type(of: self)) 에러 처리: \(appError)")
        #endif
    }
    
    /// 성공적으로 완료된 작업 후 상태 업데이트
    func markAsLoaded() {
        loadingState = .loaded
        lastUpdated = Date()
    }
    
    /// 새로고침 시작
    func startRefresh() {
        loadingState = .refreshing
    }
    
    /// Publisher에 구독하고 자동 취소 관리
    /// - Parameters:
    ///   - publisher: 구독할 Publisher
    ///   - receiveValue: 값을 받았을 때 처리 클로저
    func subscribe<T>(
        to publisher: AnyPublisher<T, Never>,
        receiveValue: @escaping (T) -> Void
    ) {
        publisher
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: receiveValue)
            .store(in: &cancellables)
    }
}

// MARK: - Equatable Implementation for LoadingState

/// LoadingState의 Equatable 구현
/// AppError 비교를 위해 필요
extension LoadingState {
    static func == (lhs: LoadingState, rhs: LoadingState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle),
             (.loading, .loading),
             (.loaded, .loaded),
             (.refreshing, .refreshing):
            return true
        case (.failed(let lhsError), .failed(let rhsError)):
            return lhsError.localizedDescription == rhsError.localizedDescription
        default:
            return false
        }
    }
}