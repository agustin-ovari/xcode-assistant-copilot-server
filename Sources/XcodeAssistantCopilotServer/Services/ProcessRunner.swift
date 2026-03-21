import Foundation

public struct ProcessResult: Sendable {
    public let stdout: String
    public let stderr: String
    public let exitCode: Int32

    public var succeeded: Bool { exitCode == 0 }

    public init(stdout: String, stderr: String, exitCode: Int32) {
        self.stdout = stdout
        self.stderr = stderr
        self.exitCode = exitCode
    }
}

public protocol ProcessRunnerProtocol: Sendable {
    func run(executablePath: String, arguments: [String], environment: [String: String]?) async throws -> ProcessResult
}

extension ProcessRunnerProtocol {
    public func run(executablePath: String, arguments: [String]) async throws -> ProcessResult {
        try await run(executablePath: executablePath, arguments: arguments, environment: nil)
    }
}

public enum ProcessRunnerError: Error, CustomStringConvertible {
    case executableNotFound(String)

    /// Represents a process that exited with a non-zero status code.
    ///
    /// `ProcessRunner.run` never throws this case — it always returns a `ProcessResult`
    /// regardless of the exit code. Callers that want to treat failure exit codes as
    /// errors should inspect `ProcessResult.succeeded` or `ProcessResult.exitCode`
    /// and throw this case themselves when appropriate.
    case executionFailed(exitCode: Int32, stderr: String)

    public var description: String {
        switch self {
        case .executableNotFound(let path):
            "Executable not found: \(path)"
        case .executionFailed(let exitCode, let stderr):
            "Process exited with code \(exitCode): \(stderr)"
        }
    }
}

public final class ProcessRunner: ProcessRunnerProtocol {
    public init() {}

    public func run(
        executablePath: String,
        arguments: [String],
        environment: [String: String]? = nil
    ) async throws -> ProcessResult {
        let process = Process()
        let stdoutPipe = Pipe()
        let stderrPipe = Pipe()

        process.executableURL = URL(fileURLWithPath: executablePath)
        process.arguments = arguments
        process.standardOutput = stdoutPipe
        process.standardError = stderrPipe

        if let environment {
            process.environment = environment
        }

        // Arm the readabilityHandlers before the process launches so that
        // no output is missed and the OS pipe buffer never fills up.
        let stdoutStream = stdoutPipe.fileHandleForReading.asyncDataStream()
        let stderrStream = stderrPipe.fileHandleForReading.asyncDataStream()

        return try await withTaskCancellationHandler {
            try Task.checkCancellation()

            let exitCode: Int32 = try await withCheckedThrowingContinuation { continuation in
                process.terminationHandler = { terminatedProcess in
                    continuation.resume(returning: terminatedProcess.terminationStatus)
                }
                do {
                    try process.run()
                } catch {
                    process.terminationHandler = nil
                    continuation.resume(throwing: ProcessRunnerError.executableNotFound(executablePath))
                }
            }

            try Task.checkCancellation()

            async let stdoutData = collectData(from: stdoutStream)
            async let stderrData = collectData(from: stderrStream)
            let (out, err) = await (stdoutData, stderrData)

            return ProcessResult(
                stdout: String(data: out, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "",
                stderr: String(data: err, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "",
                exitCode: exitCode
            )
        } onCancel: {
            process.terminate()
        }
    }

    private func collectData(from stream: AsyncStream<Data>) async -> Data {
        var result = Data()
        for await chunk in stream {
            result.append(chunk)
        }
        return result
    }
}