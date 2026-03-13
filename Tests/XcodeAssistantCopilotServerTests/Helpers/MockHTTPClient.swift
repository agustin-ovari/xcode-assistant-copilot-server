@testable import XcodeAssistantCopilotServer
import Synchronization
import Foundation

final class MockHTTPClient: HTTPClientProtocol, Sendable {
    private struct State {
        var executeResults: [Result<DataResponse, Error>] = []
        var streamResults: [Result<StreamResponse, Error>] = []
        var sentEndpoints: [any Endpoint] = []
        var executeCallCount = 0
        var streamCallCount = 0
    }

    private let mutex = Mutex(State())

    var executeResults: [Result<DataResponse, Error>] {
        get { mutex.withLock { $0.executeResults } }
        set { mutex.withLock { $0.executeResults = newValue } }
    }

    var streamResults: [Result<StreamResponse, Error>] {
        get { mutex.withLock { $0.streamResults } }
        set { mutex.withLock { $0.streamResults = newValue } }
    }

    var sentEndpoints: [any Endpoint] { mutex.withLock { $0.sentEndpoints } }
    var executeCallCount: Int { mutex.withLock { $0.executeCallCount } }
    var streamCallCount: Int { mutex.withLock { $0.streamCallCount } }

    func execute(_ endpoint: any Endpoint) async throws -> DataResponse {
        let result = mutex.withLock { state -> Result<DataResponse, Error>? in
            let i = state.executeCallCount
            state.executeCallCount += 1
            state.sentEndpoints.append(endpoint)
            return state.executeResults.indices.contains(i) ? state.executeResults[i] : nil
        }
        guard let result else {
            return DataResponse(data: Data(), statusCode: 200)
        }
        return try result.get()
    }

    func stream(_ endpoint: any Endpoint) async throws -> StreamResponse {
        let result = mutex.withLock { state -> Result<StreamResponse, Error>? in
            let i = state.streamCallCount
            state.streamCallCount += 1
            state.sentEndpoints.append(endpoint)
            return state.streamResults.indices.contains(i) ? state.streamResults[i] : nil
        }
        guard let result else {
            let emptyLines = AsyncThrowingStream<String, Error> { $0.finish() }
            return StreamResponse(statusCode: 200, content: .lines(emptyLines))
        }
        return try result.get()
    }
}
