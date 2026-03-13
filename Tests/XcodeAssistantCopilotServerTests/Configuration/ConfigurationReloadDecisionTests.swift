import Testing
import Foundation
@testable import XcodeAssistantCopilotServer

@Test func decideReturnsHotReloadWhenOnlyAllowedCliToolsChanged() {
    let old = ServerConfiguration(allowedCliTools: ["git"])
    let new = ServerConfiguration(allowedCliTools: ["git", "xcodebuild"])
    let decision = ConfigurationReloadDecision.decide(from: old, to: new)
    if case .hotReload = decision {
        #expect(Bool(true))
    } else {
        #expect(Bool(false), "Expected .hotReload but got \(decision)")
    }
}

@Test func decideReturnsHotReloadWhenOnlyReasoningEffortChanged() {
    let old = ServerConfiguration(reasoningEffort: .low)
    let new = ServerConfiguration(reasoningEffort: .high)
    let decision = ConfigurationReloadDecision.decide(from: old, to: new)
    if case .hotReload = decision {
        #expect(Bool(true))
    } else {
        #expect(Bool(false), "Expected .hotReload but got \(decision)")
    }
}

@Test func decideReturnsHotReloadWhenOnlyAutoApprovePermissionsChanged() {
    let old = ServerConfiguration(autoApprovePermissions: .all(false))
    let new = ServerConfiguration(autoApprovePermissions: .all(true))
    let decision = ConfigurationReloadDecision.decide(from: old, to: new)
    if case .hotReload = decision {
        #expect(Bool(true))
    } else {
        #expect(Bool(false), "Expected .hotReload but got \(decision)")
    }
}

@Test func decideReturnsHotReloadWhenOnlyTimeoutsChanged() {
    let old = ServerConfiguration(timeouts: TimeoutsConfiguration(requestTimeoutSeconds: 60))
    let new = ServerConfiguration(timeouts: TimeoutsConfiguration(requestTimeoutSeconds: 120))
    let decision = ConfigurationReloadDecision.decide(from: old, to: new)
    if case .hotReload = decision {
        #expect(Bool(true))
    } else {
        #expect(Bool(false), "Expected .hotReload but got \(decision)")
    }
}

@Test func decideReturnsHotReloadWhenOnlyMaxAgentLoopIterationsChanged() {
    let old = ServerConfiguration(maxAgentLoopIterations: 20)
    let new = ServerConfiguration(maxAgentLoopIterations: 80)
    let decision = ConfigurationReloadDecision.decide(from: old, to: new)
    if case .hotReload = decision {
        #expect(Bool(true))
    } else {
        #expect(Bool(false), "Expected .hotReload but got \(decision)")
    }
}

@Test func decideReturnsHotReloadWhenNothingChanged() {
    let config = ServerConfiguration()
    let decision = ConfigurationReloadDecision.decide(from: config, to: config)
    if case .hotReload = decision {
        #expect(Bool(true))
    } else {
        #expect(Bool(false), "Expected .hotReload but got \(decision)")
    }
}

@Test func decideReturnsMCPRestartWhenMCPServersChanged() {
    let old = ServerConfiguration(mcpServers: [:])
    let server = MCPServerConfiguration(type: .stdio, command: "/usr/bin/node")
    let new = ServerConfiguration(mcpServers: ["myServer": server])
    let decision = ConfigurationReloadDecision.decide(from: old, to: new)
    if case .mcpRestart = decision {
        #expect(Bool(true))
    } else {
        #expect(Bool(false), "Expected .mcpRestart but got \(decision)")
    }
}

@Test func decideReturnsMCPRestartWhenMCPServerCommandChanged() {
    let oldServer = MCPServerConfiguration(type: .stdio, command: "/usr/bin/node")
    let newServer = MCPServerConfiguration(type: .stdio, command: "/usr/local/bin/node")
    let old = ServerConfiguration(mcpServers: ["myServer": oldServer])
    let new = ServerConfiguration(mcpServers: ["myServer": newServer])
    let decision = ConfigurationReloadDecision.decide(from: old, to: new)
    if case .mcpRestart = decision {
        #expect(Bool(true))
    } else {
        #expect(Bool(false), "Expected .mcpRestart but got \(decision)")
    }
}

@Test func decideReturnsManualRestartWhenBodyLimitChanged() {
    let old = ServerConfiguration(bodyLimitMiB: 4)
    let new = ServerConfiguration(bodyLimitMiB: 8)
    let decision = ConfigurationReloadDecision.decide(from: old, to: new)
    if case .requiresManualRestart = decision {
        #expect(Bool(true))
    } else {
        #expect(Bool(false), "Expected .requiresManualRestart but got \(decision)")
    }
}

@Test func decideReturnsManualRestartEvenWhenMCPServersAlsoChanged() {
    let server = MCPServerConfiguration(type: .stdio, command: "/usr/bin/node")
    let old = ServerConfiguration(mcpServers: [:], bodyLimitMiB: 4)
    let new = ServerConfiguration(mcpServers: ["myServer": server], bodyLimitMiB: 8)
    let decision = ConfigurationReloadDecision.decide(from: old, to: new)
    if case .requiresManualRestart = decision {
        #expect(Bool(true))
    } else {
        #expect(Bool(false), "Expected .requiresManualRestart but got \(decision)")
    }
}

@Test func decideCarriesNewConfigInHotReloadCase() {
    let old = ServerConfiguration(allowedCliTools: ["git"])
    let new = ServerConfiguration(allowedCliTools: ["git", "xcodebuild"])
    let decision = ConfigurationReloadDecision.decide(from: old, to: new)
    if case .hotReload(let carried) = decision {
        #expect(carried.allowedCliTools == ["git", "xcodebuild"])
    } else {
        #expect(Bool(false), "Expected .hotReload but got \(decision)")
    }
}

@Test func decideCarriesNewConfigInMCPRestartCase() {
    let server = MCPServerConfiguration(type: .stdio, command: "/usr/bin/node")
    let old = ServerConfiguration(mcpServers: [:])
    let new = ServerConfiguration(mcpServers: ["myServer": server])
    let decision = ConfigurationReloadDecision.decide(from: old, to: new)
    if case .mcpRestart(let carried) = decision {
        #expect(carried.mcpServers["myServer"]?.command == "/usr/bin/node")
    } else {
        #expect(Bool(false), "Expected .mcpRestart but got \(decision)")
    }
}

@Test func manualRestartReasonMentionsBodyLimitMiB() {
    let old = ServerConfiguration(bodyLimitMiB: 4)
    let new = ServerConfiguration(bodyLimitMiB: 16)
    let decision = ConfigurationReloadDecision.decide(from: old, to: new)
    if case .requiresManualRestart(let reason) = decision {
        #expect(reason.contains("bodyLimitMiB"))
    } else {
        #expect(Bool(false), "Expected .requiresManualRestart but got \(decision)")
    }
}
