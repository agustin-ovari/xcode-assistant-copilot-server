@testable import XcodeAssistantCopilotServer
import Synchronization

final class MockReasoningEffortResolver: ReasoningEffortResolverProtocol, Sendable {
    private struct State {
        var resolvedEffort: ReasoningEffort?
        var resolvedModels: [String] = []
        var recordedMaxEfforts: [(effort: ReasoningEffort, modelId: String)] = []
    }

    private let state = Mutex(State())

    var resolvedEffort: ReasoningEffort? {
        get { state.withLock { $0.resolvedEffort } }
        set { state.withLock { $0.resolvedEffort = newValue } }
    }

    var resolvedModels: [String] { state.withLock { $0.resolvedModels } }
    var recordedMaxEfforts: [(effort: ReasoningEffort, modelId: String)] { state.withLock { $0.recordedMaxEfforts } }

    func resolve(configured: ReasoningEffort, for modelId: String) async -> ReasoningEffort {
        state.withLock {
            $0.resolvedModels.append(modelId)
            return $0.resolvedEffort ?? configured
        }
    }

    func recordMaxEffort(_ effort: ReasoningEffort, for modelId: String) async {
        state.withLock { $0.recordedMaxEfforts.append((effort: effort, modelId: modelId)) }
    }
}
