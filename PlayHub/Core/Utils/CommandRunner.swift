import Foundation

/// Unified command execution utility for PlayHub
/// Provides both synchronous and asynchronous command execution with proper error handling
struct CommandRunner {
    
    // MARK: - 명령 실행 결과
    
    struct CommandResult {
        let stdout: String
        let stderr: String
        let exitCode: Int32
        
        var isSuccess: Bool {
            exitCode == 0
        }
        
        var trimmedOutput: String {
            stdout.trimmingCharacters(in: .whitespacesAndNewlines)
        }
    }
    
    // MARK: - 에러 타입
    
    enum ExecutionError: LocalizedError {
        case nonZeroExit(code: Int32, stderr: String)
        case failedToStart(Error)
        case timedOut
        case invalidPath(String)
        
        var errorDescription: String? {
            switch self {
            case .nonZeroExit(let code, let stderr):
                return "Command failed with exit code \(code): \(stderr)"
            case .failedToStart(let error):
                return "Failed to start command: \(error.localizedDescription)"
            case .timedOut:
                return "Command execution timed out"
            case .invalidPath(let path):
                return "Invalid executable path: \(path)"
            }
        }
    }
    
    // MARK: - 동기 실행
    
    /// 동기적 명령 실행 (결과 대기)
    /// - Parameters:
    ///   - launchPath: 실행할 명령의 절대 경로
    ///   - arguments: 명령 인자 배열
    ///   - timeout: 실행 제한 시간 (초)
    ///   - workingDirectory: 작업 디렉토리 (옵션)
    /// - Returns: CommandResult 구조체
    /// - Throws: ExecutionError
    static func execute(
        _ launchPath: String,
        arguments: [String] = [],
        timeout: TimeInterval = 30,
        workingDirectory: String? = nil
    ) throws -> CommandResult {
        
        // 실행 파일 존재 확인
        guard FileManager.default.isExecutableFile(atPath: launchPath) else {
            throw ExecutionError.invalidPath(launchPath)
        }
        
        let process = Process()
        process.executableURL = URL(fileURLWithPath: launchPath)
        process.arguments = arguments
        
        // 작업 디렉토리 설정
        if let workingDirectory = workingDirectory {
            process.currentDirectoryURL = URL(fileURLWithPath: workingDirectory)
        }
        
        let outPipe = Pipe()
        let errPipe = Pipe()
        process.standardOutput = outPipe
        process.standardError = errPipe
        
        do {
            try process.run()
        } catch {
            throw ExecutionError.failedToStart(error)
        }
        
        // 타임아웃 처리
        let deadline = DispatchTime.now() + timeout
        let timeoutQueue = DispatchQueue.global()
        
        var timedOut = false
        timeoutQueue.asyncAfter(deadline: deadline) {
            if process.isRunning {
                process.terminate()
                timedOut = true
            }
        }
        
        process.waitUntilExit()
        
        if timedOut {
            throw ExecutionError.timedOut
        }
        
        let outData = outPipe.fileHandleForReading.readDataToEndOfFile()
        let errData = errPipe.fileHandleForReading.readDataToEndOfFile()
        
        let stdout = String(data: outData, encoding: .utf8) ?? ""
        let stderr = String(data: errData, encoding: .utf8) ?? ""
        
        let result = CommandResult(
            stdout: stdout,
            stderr: stderr,
            exitCode: process.terminationStatus
        )
        
        return result
    }
    
    // MARK: - 비동기 실행
    
    /// 비동기적 명령 실행 (백그라운드 프로세스 시작)
    /// - Parameters:
    ///   - launchPath: 실행할 명령의 절대 경로
    ///   - arguments: 명령 인자 배열
    ///   - detached: 프로세스를 완전히 분리할지 여부
    /// - Returns: CommandResult (시작 성공 여부만 표시)
    /// - Throws: ExecutionError
    static func spawn(
        _ launchPath: String,
        arguments: [String] = [],
        detached: Bool = true
    ) throws -> CommandResult {
        
        // 실행 파일 존재 확인
        guard FileManager.default.isExecutableFile(atPath: launchPath) else {
            throw ExecutionError.invalidPath(launchPath)
        }
        
        let process = Process()
        process.executableURL = URL(fileURLWithPath: launchPath)
        process.arguments = arguments
        
        if detached {
            // 백그라운드에서 실행 (출력 무시)
            process.standardOutput = FileHandle.nullDevice
            process.standardError = FileHandle.nullDevice
            process.standardInput = FileHandle.nullDevice
        }
        
        do {
            try process.run()
        } catch {
            throw ExecutionError.failedToStart(error)
        }
        
        // 시작 성공으로 간주
        return CommandResult(
            stdout: "",
            stderr: "",
            exitCode: 0
        )
    }
    
    // MARK: - Async/Await 버전
    
    /// async/await 버전의 명령 실행
    /// - Parameters:
    ///   - launchPath: 실행할 명령의 절대 경로
    ///   - arguments: 명령 인자 배열
    ///   - timeout: 실행 제한 시간 (초)
    /// - Returns: 표준 출력 문자열
    /// - Throws: ExecutionError
    static func executeAsync(
        _ launchPath: String,
        arguments: [String] = [],
        timeout: TimeInterval = 30
    ) async throws -> String {
        
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .background).async {
                do {
                    let result = try execute(launchPath, arguments: arguments, timeout: timeout)
                    if result.isSuccess {
                        continuation.resume(returning: result.trimmedOutput)
                    } else {
                        continuation.resume(throwing: ExecutionError.nonZeroExit(code: result.exitCode, stderr: result.stderr))
                    }
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    // MARK: - 유틸리티 메서드
    
    /// 특정 프로세스가 실행 중인지 확인
    /// - Parameter processName: 프로세스 이름 (부분 매치)
    /// - Returns: 실행 중이면 true
    static func isProcessRunning(_ processName: String) -> Bool {
        do {
            let result = try execute("/usr/bin/pgrep", arguments: ["-f", processName])
            return result.isSuccess && !result.trimmedOutput.isEmpty
        } catch {
            return false
        }
    }
    
    /// 특정 프로세스 종료
    /// - Parameter processName: 프로세스 이름 (부분 매치)
    /// - Returns: 종료 성공 여부
    static func killProcess(_ processName: String) -> Bool {
        do {
            let result = try execute("/usr/bin/pkill", arguments: ["-f", processName])
            return result.isSuccess
        } catch {
            return false
        }
    }
    
    /// 파일이나 디렉토리 존재 여부 확인
    /// - Parameter path: 확인할 경로
    /// - Returns: 존재하면 true
    static func pathExists(_ path: String) -> Bool {
        return FileManager.default.fileExists(atPath: path)
    }
    
    /// 실행 가능한 파일인지 확인
    /// - Parameter path: 확인할 경로
    /// - Returns: 실행 가능하면 true
    static func isExecutable(_ path: String) -> Bool {
        return FileManager.default.isExecutableFile(atPath: path)
    }
}