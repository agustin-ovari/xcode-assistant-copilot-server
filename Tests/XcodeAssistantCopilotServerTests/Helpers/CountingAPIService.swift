@testable import XcodeAssistantCopilotServer
import Synchronization

final class CountingAPIService: CopilotAPIServiceProtocol, Sendable {
    private struct State {
        var callCount = 0
    }

    private let state = Mutex(State())
    let models: [CopilotModel]

    var callCount: Int { state.withLock { $0.callCount } }

    init(models: [CopilotModel]) {
        self.models = models
    }

    func listModels(credentials: CopilotCredentials) async throws -> [CopilotModel] {
        state.withLock { $0.callCount += 1 }
        return models
    }

    func streamChatCompletions(
        request: CopilotChatRequest,
        credentials: CopilotCredentials
    ) async throws -> AsyncThrowingStream<SSEEvent, Error> {
        fatalError("Not used")
    }

    func streamResponses(
        request: ResponsesAPIRequest,
        credentials: CopilotCredentials
    ) async throws -> AsyncThrowingStream<SSEEvent, Error> {
        fatalError("Not used")
    }
}
