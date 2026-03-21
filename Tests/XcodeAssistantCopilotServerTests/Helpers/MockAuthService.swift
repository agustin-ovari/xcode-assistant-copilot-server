@testable import XcodeAssistantCopilotServer
import Synchronization

final class MockAuthService: AuthServiceProtocol, Sendable {
    private struct State {
        var token: String = "mock-github-token"
        var credentials: CopilotCredentials = CopilotCredentials(
            token: "mock-copilot-token",
            apiEndpoint: "https://api.github.com"
        )
        var credentialsSequence: [CopilotCredentials] = []
        var shouldThrow: Error?
        var invalidateCallCount: Int = 0
        var getValidCopilotTokenCallCount: Int = 0
        var mockTokenInfo: CopilotTokenInfo?
    }

    private let mutex = Mutex(State())

    var token: String {
        get { mutex.withLock { $0.token } }
        set { mutex.withLock { $0.token = newValue } }
    }

    var credentials: CopilotCredentials {
        get { mutex.withLock { $0.credentials } }
        set { mutex.withLock { $0.credentials = newValue } }
    }

    var credentialsSequence: [CopilotCredentials] {
        get { mutex.withLock { $0.credentialsSequence } }
        set { mutex.withLock { $0.credentialsSequence = newValue } }
    }

    var shouldThrow: Error? {
        get { mutex.withLock { $0.shouldThrow } }
        set { mutex.withLock { $0.shouldThrow = newValue } }
    }

    var invalidateCallCount: Int { mutex.withLock { $0.invalidateCallCount } }
    var getValidCopilotTokenCallCount: Int { mutex.withLock { $0.getValidCopilotTokenCallCount } }

    var mockTokenInfo: CopilotTokenInfo? {
        get { mutex.withLock { $0.mockTokenInfo } }
        set { mutex.withLock { $0.mockTokenInfo = newValue } }
    }

    func getGitHubToken() async throws -> String {
        if let error = mutex.withLock({ $0.shouldThrow }) { throw error }
        return mutex.withLock { $0.token }
    }

    func getValidCopilotToken() async throws -> CopilotCredentials {
        if let error = mutex.withLock({ $0.shouldThrow }) { throw error }
        return mutex.withLock {
            let index = $0.getValidCopilotTokenCallCount
            $0.getValidCopilotTokenCallCount += 1
            if index < $0.credentialsSequence.count {
                return $0.credentialsSequence[index]
            }
            return $0.credentials
        }
    }

    func invalidateCachedToken() async {
        mutex.withLock { $0.invalidateCallCount += 1 }
    }

    func cachedTokenInfo() async -> CopilotTokenInfo? {
        mutex.withLock { $0.mockTokenInfo }
    }
}
