import Foundation

public enum ConfigurationReloadDecision {
    case hotReload(ServerConfiguration)
    case mcpRestart(ServerConfiguration)
    case requiresManualRestart(reason: String)

    public static func decide(from old: ServerConfiguration, to new: ServerConfiguration) -> ConfigurationReloadDecision {
        if old.bodyLimitMiB != new.bodyLimitMiB {
            return .requiresManualRestart(reason: "bodyLimitMiB changed (\(old.bodyLimitMiB) → \(new.bodyLimitMiB))")
        }

        if mcpServersChanged(old.mcpServers, new.mcpServers) {
            return .mcpRestart(new)
        }

        return .hotReload(new)
    }

    private static func mcpServersChanged(
        _ old: [String: MCPServerConfiguration],
        _ new: [String: MCPServerConfiguration]
    ) -> Bool {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        guard
            let oldData = try? encoder.encode(old),
            let newData = try? encoder.encode(new)
        else {
            return true
        }
        return oldData != newData
    }
}
