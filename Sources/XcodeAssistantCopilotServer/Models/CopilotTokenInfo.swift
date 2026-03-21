import Foundation

public struct CopilotTokenInfo: Sendable {
    public let expiresAt: Date
    public let isAuthenticated: Bool

    public init(expiresAt: Date, isAuthenticated: Bool) {
        self.expiresAt = expiresAt
        self.isAuthenticated = isAuthenticated
    }
}
