@testable import XcodeAssistantCopilotServer

final class CountingAPIService: CopilotAPIServiceProtocol, @unchecked Sendable {
    let models: [CopilotModel]
    private(set) var callCount = 0

    init(models: [CopilotModel]) {
        self.models = models
    }

    func listModels(credentials: CopilotCredentials) async throws -> [CopilotModel] {
        callCount += 1
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