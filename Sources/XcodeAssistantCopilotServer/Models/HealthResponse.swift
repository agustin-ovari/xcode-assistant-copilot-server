import Foundation

public struct HealthResponse: Encodable, Sendable {
    public let status: String
    public let uptimeSeconds: Int
    public let mcpBridge: MCPBridgeStatus
    public let authentication: AuthenticationStatus
    public let lastModelFetchTime: String?

    public init(
        status: String,
        uptimeSeconds: Int,
        mcpBridge: MCPBridgeStatus,
        authentication: AuthenticationStatus,
        lastModelFetchTime: String?
    ) {
        self.status = status
        self.uptimeSeconds = uptimeSeconds
        self.mcpBridge = mcpBridge
        self.authentication = authentication
        self.lastModelFetchTime = lastModelFetchTime
    }

    enum CodingKeys: String, CodingKey {
        case status
        case uptimeSeconds = "uptime_seconds"
        case mcpBridge = "mcp_bridge"
        case authentication
        case lastModelFetchTime = "last_model_fetch_time"
    }
}

public struct MCPBridgeStatus: Encodable, Sendable {
    public let enabled: Bool

    public init(enabled: Bool) {
        self.enabled = enabled
    }
}