@testable import XcodeAssistantCopilotServer
import Foundation
import Hummingbird
import HTTPTypes
import NIOCore
import Testing

private func makeModelsHandler(
    authService: AuthServiceProtocol = MockAuthService(),
    copilotAPI: CopilotAPIServiceProtocol = MockCopilotAPIService(),
    logger: LoggerProtocol = MockLogger()
) -> ModelsHandler {
    ModelsHandler(
        authService: authService,
        copilotAPI: copilotAPI,
        logger: logger
    )
}

private func makeCredentials() -> CopilotCredentials {
    CopilotCredentials(token: "mock-token", apiEndpoint: "https://api.github.com")
}

private final class CollectedBuffers: @unchecked Sendable {
    var buffers: [ByteBuffer] = []

    var collectedData: Data {
        var combined = ByteBuffer()
        for buf in buffers {
            var copy = buf
            combined.writeBuffer(&copy)
        }
        return Data(buffer: combined)
    }
}

private struct CollectingBodyWriter: ResponseBodyWriter {
    let storage: CollectedBuffers

    mutating func write(_ buffer: ByteBuffer) async throws {
        storage.buffers.append(buffer)
    }

    consuming func finish(_ trailingHeaders: HTTPFields?) async throws {}
}

private func drainResponseBody(_ response: Response) async throws -> Data {
    let storage = CollectedBuffers()
    let writer = CollectingBodyWriter(storage: storage)
    try await response.body.write(writer)
    return storage.collectedData
}

@Test func modelsRetriesOnUnauthorized() async {
    let authService = MockAuthService()
    let freshCredentials = CopilotCredentials(token: "fresh-token", apiEndpoint: "https://api.github.com")
    authService.credentialsSequence = [
        CopilotCredentials(token: "stale-token", apiEndpoint: "https://api.github.com"),
        freshCredentials
    ]

    let copilotAPI = MockCopilotAPIService()
    copilotAPI.listModelsResults = [
        .failure(CopilotAPIError.unauthorized),
        .success([CopilotModel(id: "gpt-4")])
    ]

    let logger = MockLogger()
    let handler = makeModelsHandler(
        authService: authService,
        copilotAPI: copilotAPI,
        logger: logger
    )

    let response = await handler.buildModelsResponse(credentials: makeCredentials())

    #expect(response.status == HTTPResponse.Status.ok)
    #expect(copilotAPI.listModelsCallCount == 2)
    #expect(authService.invalidateCallCount == 1)
}

@Test func modelsFailsWhenRetryAlsoReturnsUnauthorized() async {
    let authService = MockAuthService()
    let copilotAPI = MockCopilotAPIService()
    copilotAPI.listModelsResults = [
        .failure(CopilotAPIError.unauthorized),
        .failure(CopilotAPIError.unauthorized)
    ]

    let logger = MockLogger()
    let handler = makeModelsHandler(
        authService: authService,
        copilotAPI: copilotAPI,
        logger: logger
    )

    let response = await handler.buildModelsResponse(credentials: makeCredentials())

    #expect(response.status == HTTPResponse.Status.internalServerError)
    #expect(copilotAPI.listModelsCallCount == 2)
    #expect(authService.invalidateCallCount == 1)
}

@Test func modelsSucceedsWithoutRetryWhenTokenIsValid() async {
    let copilotAPI = MockCopilotAPIService()
    copilotAPI.models = [CopilotModel(id: "gpt-4", capabilities: CopilotModelCapabilities(type: "chat"))]

    let authService = MockAuthService()
    let handler = makeModelsHandler(
        authService: authService,
        copilotAPI: copilotAPI
    )

    let response = await handler.buildModelsResponse(credentials: makeCredentials())

    #expect(response.status == HTTPResponse.Status.ok)
    #expect(copilotAPI.listModelsCallCount == 1)
    #expect(authService.invalidateCallCount == 0)
}

@Test func modelsFiltersOutNonChatModels() async throws {
    let copilotAPI = MockCopilotAPIService()
    copilotAPI.models = [
        CopilotModel(id: "gpt-4o", supportedEndpoints: ["/chat/completions", "/responses"]),
        CopilotModel(id: "text-embedding-ada-002", supportedEndpoints: ["/embeddings"]),
        CopilotModel(id: "claude-sonnet-4", supportedEndpoints: ["/chat/completions"]),
    ]

    let handler = makeModelsHandler(copilotAPI: copilotAPI)
    let response = await handler.buildModelsResponse(credentials: makeCredentials())

    #expect(response.status == HTTPResponse.Status.ok)
    let data = try await drainResponseBody(response)
    let modelsResponse = try JSONDecoder().decode(ModelsResponse.self, from: data)
    #expect(modelsResponse.data.count == 2)
    #expect(modelsResponse.data[0].id == "gpt-4o")
    #expect(modelsResponse.data[1].id == "claude-sonnet-4")
}

@Test func modelsIncludesResponsesOnlyModels() async throws {
    let copilotAPI = MockCopilotAPIService()
    copilotAPI.models = [
        CopilotModel(id: "codex-model", supportedEndpoints: ["/responses"]),
        CopilotModel(id: "embedding-model", supportedEndpoints: ["/embeddings"]),
    ]

    let handler = makeModelsHandler(copilotAPI: copilotAPI)
    let response = await handler.buildModelsResponse(credentials: makeCredentials())

    #expect(response.status == HTTPResponse.Status.ok)
    let data = try await drainResponseBody(response)
    let modelsResponse = try JSONDecoder().decode(ModelsResponse.self, from: data)
    #expect(modelsResponse.data.count == 1)
    #expect(modelsResponse.data[0].id == "codex-model")
}

@Test func modelsIncludesModelsWithNoEndpointsInfo() async throws {
    let copilotAPI = MockCopilotAPIService()
    copilotAPI.models = [
        CopilotModel(id: "chat-model", capabilities: CopilotModelCapabilities(type: "chat")),
        CopilotModel(id: "embedding-model", supportedEndpoints: ["/embeddings"]),
    ]

    let handler = makeModelsHandler(copilotAPI: copilotAPI)
    let response = await handler.buildModelsResponse(credentials: makeCredentials())

    #expect(response.status == HTTPResponse.Status.ok)
    let data = try await drainResponseBody(response)
    let modelsResponse = try JSONDecoder().decode(ModelsResponse.self, from: data)
    #expect(modelsResponse.data.count == 1)
    #expect(modelsResponse.data[0].id == "chat-model")
}

@Test func modelsFiltersOutAllWhenNoneChatUsable() async throws {
    let copilotAPI = MockCopilotAPIService()
    copilotAPI.models = [
        CopilotModel(id: "embedding-1", supportedEndpoints: ["/embeddings"]),
        CopilotModel(id: "embedding-2", supportedEndpoints: ["/embeddings"]),
    ]

    let handler = makeModelsHandler(copilotAPI: copilotAPI)
    let response = await handler.buildModelsResponse(credentials: makeCredentials())

    #expect(response.status == HTTPResponse.Status.ok)
    let data = try await drainResponseBody(response)
    let modelsResponse = try JSONDecoder().decode(ModelsResponse.self, from: data)
    #expect(modelsResponse.data.isEmpty)
}

@Test func modelsFiltersOutModelsWithPickerDisabled() async throws {
    let copilotAPI = MockCopilotAPIService()
    copilotAPI.models = [
        CopilotModel(id: "visible-model", supportedEndpoints: ["/chat/completions"], modelPickerEnabled: true),
        CopilotModel(id: "hidden-model", supportedEndpoints: ["/chat/completions"], modelPickerEnabled: false),
    ]

    let handler = makeModelsHandler(copilotAPI: copilotAPI)
    let response = await handler.buildModelsResponse(credentials: makeCredentials())

    #expect(response.status == HTTPResponse.Status.ok)
    let data = try await drainResponseBody(response)
    let modelsResponse = try JSONDecoder().decode(ModelsResponse.self, from: data)
    #expect(modelsResponse.data.count == 1)
    #expect(modelsResponse.data[0].id == "visible-model")
}

@Test func modelsFiltersOutModelsWithNonEnabledPolicy() async throws {
    let copilotAPI = MockCopilotAPIService()
    copilotAPI.models = [
        CopilotModel(id: "enabled-model", supportedEndpoints: ["/chat/completions"], policy: CopilotModelPolicy(state: "enabled")),
        CopilotModel(id: "pending-model", supportedEndpoints: ["/chat/completions"], policy: CopilotModelPolicy(state: "pending")),
        CopilotModel(id: "consent-model", supportedEndpoints: ["/chat/completions"], policy: CopilotModelPolicy(state: "requires_consent")),
        CopilotModel(id: "no-policy-model", supportedEndpoints: ["/chat/completions"]),
    ]

    let handler = makeModelsHandler(copilotAPI: copilotAPI)
    let response = await handler.buildModelsResponse(credentials: makeCredentials())

    #expect(response.status == HTTPResponse.Status.ok)
    let data = try await drainResponseBody(response)
    let modelsResponse = try JSONDecoder().decode(ModelsResponse.self, from: data)
    #expect(modelsResponse.data.count == 2)
    #expect(modelsResponse.data[0].id == "enabled-model")
    #expect(modelsResponse.data[1].id == "no-policy-model")
}