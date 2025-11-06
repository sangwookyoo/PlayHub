import Foundation

/// Lightweight adapter to replace legacy ServiceCommandHelper usages.
/// Delegates to the modern CommandRunner implementation.
struct ServiceCommandHelper {

    /// Execute a command synchronously and return CommandRunner.CommandResult
    /// - Parameters:
    ///   - path: executable path
    ///   - arguments: arguments array
    ///   - context: optional logging context (not used for execution)
    /// - Throws: CommandRunner.ExecutionError
    /// - Returns: CommandRunner.CommandResult
    static func executeCommand(_ path: String, arguments: [String] = [], context: String? = nil) throws -> CommandRunner.CommandResult {
        return try CommandRunner.execute(path, arguments: arguments)
    }

    /// Spawn a background command (non-blocking)
    static func spawnCommand(_ path: String, arguments: [String] = [], detached: Bool = true) throws -> CommandRunner.CommandResult {
        return try CommandRunner.spawn(path, arguments: arguments, detached: detached)
    }

    /// Async/await execution convenience
    static func executeCommandAsync(_ path: String, arguments: [String] = [], timeout: TimeInterval = 30) async throws -> String {
        return try await CommandRunner.executeAsync(path, arguments: arguments, timeout: timeout)
    }

    /// Check executable exists
    static func isExecutable(at path: String) -> Bool {
        return CommandRunner.isExecutable(path)
    }
}
