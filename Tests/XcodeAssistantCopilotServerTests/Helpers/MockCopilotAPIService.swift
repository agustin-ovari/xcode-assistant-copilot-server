@testable import XcodeAssistantCopilotServer
import Synchronization
import Foundation

final class MockCopilotAPIService: CopilotAPIServiceProtocol, Sendable {
    private struct State {
        var models: [CopilotModel] = []
        var listModelsResults: [Result<[CopilotModel], Error>] = []
        var streamChatCompletionsResults: [Result<AsyncThrowingStream<SSEEvent, Error>, Error>] = []
        var streamResponsesResults: [Result<AsyncThrowingStream<SSEEvent, Error>, Error>] = []
        var listModelsCallCount = 0
        var streamChatCompletionsCallCount = 0
        var streamResponsesCallCount = 0
        var capturedChatRequests: [CopilotChatRequest] = []
        var capturedListModelsCredentials: [CopilotCredentials] = []
    }

    private let mutex = Mutex(State())

    var models: [CopilotModel] {
        get { mutex.withLock { $0.models } }
        set { mutex.withLock { $0.models = newValue } }
    }

    var listModelsResults: [Result<[CopilotModel], Error>] {
        get { mutex.withLock { $0.listModelsResults } }
        set { mutex.withLock { $0.listModelsResults = newValue } }
    }

    var streamChatCompletionsResults: [Result<AsyncThrowingStream<SSEEvent, Error>, Error>] {
        get { mutex.withLock { $0.streamChatCompletionsResults } }
        set { mutex.withLock { $0.streamChatCompletionsResults = newValue } }
    }

    var streamResponsesResults: [Result<AsyncThrowingStream<SSEEvent, Error>, Error>] {
        get { mutex.withLock { $0.streamResponsesResults } }
        set { mutex.withLock { $0.streamResponsesResults = newValue } }
    }

    var listModelsCallCount: Int { mutex.withLock { $0.listModelsCallCount } }
    var streamChatCompletionsCallCount: Int { mutex.withLock { $0.streamChatCompletionsCallCount } }
    var streamResponsesCallCount: Int { mutex.withLock { $0.streamResponsesCallCount } }
    var capturedChatRequests: [CopilotChatRequest] { mutex.withLock { $0.capturedChatRequests } }
    var capturedListModelsCredentials: [CopilotCredentials] { mutex.withLock { $0.capturedListModelsCredentials } }

    func listModels(credentials: CopilotCredentials) async throws -> [CopilotModel] {
        let (result, fallback) = mutex.withLock { state -> (Result<[CopilotModel], Error>?, [CopilotModel]) in
            let i = state.listModelsCallCount
            state.listModelsCallCount += 1
            state.capturedListModelsCredentials.append(credentials)
            return (state.listModelsResults.indices.contains(i) ? state.listModelsResults[i] : nil, state.models)
        }
        if let result {
            return try result.get()
        }
        return fallback
    }

    func streamChatCompletions(
        request: CopilotChatRequest,
        credentials: CopilotCredentials
    ) async throws -> AsyncThrowingStream<SSEEvent, Error> {
        let result = mutex.withLock { state -> Result<AsyncThrowingStream<SSEEvent, Error>, Error>? in
            let i = state.streamChatCompletionsCallCount
            state.streamChatCompletionsCallCount += 1
            state.capturedChatRequests.append(request)
            return state.streamChatCompletionsResults.indices.contains(i) ? state.streamChatCompletionsResults[i] : nil
        }
        guard let result else {
            return AsyncThrowingStream { $0.finish() }
        }
        return try result.get()
    }

    func streamResponses(
        request: ResponsesAPIRequest,
        credentials: CopilotCredentials
    ) async throws -> AsyncThrowingStream<SSEEvent, Error> {
        let result = mutex.withLock { state -> Result<AsyncThrowingStream<SSEEvent, Error>, Error>? in
            let i = state.streamResponsesCallCount
            state.streamResponsesCallCount += 1
            return state.streamResponsesResults.indices.contains(i) ? state.streamResponsesResults[i] : nil
        }
        guard let result else {
            return AsyncThrowingStream { $0.finish() }
        }
        return try result.get()
    }
}

extension MockCopilotAPIService {
    static func makeToolCallStream(toolCalls: [ToolCall], content: String = "") -> AsyncThrowingStream<SSEEvent, Error> {
        AsyncThrowingStream { continuation in
            let encoder = JSONEncoder()

            let indexedToolCalls = toolCalls.enumerated().map { index, tc in
                ToolCall(
                    index: index,
                    id: tc.id,
                    type: tc.type,
                    function: tc.function
                )
            }

            let delta = ChunkDelta(
                role: .assistant,
                content: content.isEmpty ? nil : content,
                toolCalls: indexedToolCalls
            )
            let chunk = ChatCompletionChunk(
                id: "test-completion",
                model: "test-model",
                choices: [ChunkChoice(delta: delta)]
            )
            if let data = try? encoder.encode(chunk),
               let json = String(data: data, encoding: .utf8) {
                continuation.yield(SSEEvent(data: json))
            }

            let finishChunk = ChatCompletionChunk(
                id: "test-completion",
                model: "test-model",
                choices: [ChunkChoice(delta: ChunkDelta(), finishReason: "tool_calls")]
            )
            if let data = try? encoder.encode(finishChunk),
               let json = String(data: data, encoding: .utf8) {
                continuation.yield(SSEEvent(data: json))
            }

            continuation.yield(SSEEvent(data: "[DONE]"))
            continuation.finish()
        }
    }

    static func makeContentStream(content: String) -> AsyncThrowingStream<SSEEvent, Error> {
        AsyncThrowingStream { continuation in
            let encoder = JSONEncoder()

            let delta = ChunkDelta(role: .assistant, content: content)
            let chunk = ChatCompletionChunk(
                id: "test-completion",
                model: "test-model",
                choices: [ChunkChoice(delta: delta)]
            )
            if let data = try? encoder.encode(chunk),
               let json = String(data: data, encoding: .utf8) {
                continuation.yield(SSEEvent(data: json))
            }

            let stopChunk = ChatCompletionChunk(
                id: "test-completion",
                model: "test-model",
                choices: [ChunkChoice(delta: ChunkDelta(), finishReason: "stop")]
            )
            if let data = try? encoder.encode(stopChunk),
               let json = String(data: data, encoding: .utf8) {
                continuation.yield(SSEEvent(data: json))
            }

            continuation.yield(SSEEvent(data: "[DONE]"))
            continuation.finish()
        }
    }
}
