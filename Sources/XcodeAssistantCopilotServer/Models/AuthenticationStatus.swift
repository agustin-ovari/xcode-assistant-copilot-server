import Foundation

public struct AuthenticationStatus: Encodable, Sendable {
    public let authenticated: Bool
    public let copilotTokenExpiry: String?

    public init(authenticated: Bool, copilotTokenExpiry: String?) {
        self.authenticated = authenticated
        self.copilotTokenExpiry = copilotTokenExpiry
    }

    enum CodingKeys: String, CodingKey {
        case authenticated
        case copilotTokenExpiry = "copilot_token_expiry"
    }
}