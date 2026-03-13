@testable import XcodeAssistantCopilotServer
import Synchronization

final class MockAgentStreamWriter: AgentStreamWriterProtocol, Sendable {
    private struct State {
        var roleDeltaWritten = false
        var progressTexts: [String] = []
        var finalContent: String?
        var finalToolCalls: [ToolCall]?
        var finalHadToolUse: Bool?
        var finishCalled = false
    }

    private let state = Mutex(State())

    var roleDeltaWritten: Bool { state.withLock { $0.roleDeltaWritten } }
    var progressTexts: [String] { state.withLock { $0.progressTexts } }
    var finalContent: String? { state.withLock { $0.finalContent } }
    var finalToolCalls: [ToolCall]? { state.withLock { $0.finalToolCalls } }
    var finalHadToolUse: Bool? { state.withLock { $0.finalHadToolUse } }
    var finishCalled: Bool { state.withLock { $0.finishCalled } }
    var allProgressText: String { state.withLock { $0.progressTexts.joined() } }

    func writeRoleDelta() {
        state.withLock { $0.roleDeltaWritten = true }
    }

    func writeProgressText(_ text: String) {
        state.withLock { $0.progressTexts.append(text) }
    }

    func writeFinalContent(_ text: String, toolCalls: [ToolCall]?, hadToolUse: Bool) {
        state.withLock {
            $0.finalContent = text
            $0.finalToolCalls = toolCalls
            $0.finalHadToolUse = hadToolUse
        }
    }

    func finish() {
        state.withLock { $0.finishCalled = true }
    }
}
