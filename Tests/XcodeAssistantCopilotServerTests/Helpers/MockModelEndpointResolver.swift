@testable import XcodeAssistantCopilotServer
import Synchronization

final class MockModelEndpointResolver: ModelEndpointResolverProtocol, Sendable {
    private struct State {
        var endpoint: ModelEndpoint = .chatCompletions
        var resolvedModels: [String] = []
    }

    private let mutex = Mutex(State())

    var endpoint: ModelEndpoint {
        get { mutex.withLock { $0.endpoint } }
        set { mutex.withLock { $0.endpoint = newValue } }
    }

    var resolvedModels: [String] { mutex.withLock { $0.resolvedModels } }

    func endpoint(for modelId: String, credentials: CopilotCredentials) async -> ModelEndpoint {
        mutex.withLock {
            $0.resolvedModels.append(modelId)
            return $0.endpoint
        }
    }
}
