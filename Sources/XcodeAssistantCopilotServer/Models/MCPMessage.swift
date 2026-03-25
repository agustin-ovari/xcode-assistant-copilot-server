import Foundation

public enum JSONRPCId: Codable, Hashable, Sendable, CustomStringConvertible,
                       ExpressibleByIntegerLiteral, ExpressibleByStringLiteral {
    case int(Int)
    case string(String)

    public init(integerLiteral value: Int) {
        self = .int(value)
    }

    public init(stringLiteral value: String) {
        self = .string(value)
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let intValue = try? container.decode(Int.self) {
            self = .int(intValue)
        } else if let stringValue = try? container.decode(String.self) {
            if let intValue = Int(stringValue) {
                self = .int(intValue)
            } else {
                self = .string(stringValue)
            }
        } else {
            throw DecodingError.typeMismatch(
                JSONRPCId.self,
                DecodingError.Context(
                    codingPath: decoder.codingPath,
                    debugDescription: "Expected Int or String for JSON-RPC id"
                )
            )
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .int(let value):
            try container.encode(value)
        case .string(let value):
            try container.encode(value)
        }
    }

    public var description: String {
        switch self {
        case .int(let value): return "\(value)"
        case .string(let value): return value
        }
    }
}

public struct MCPRequest: Encodable, Sendable {
    public let jsonrpc: String
    public let id: JSONRPCId
    public let method: String
    public let params: [String: JSONValue]?

    public init(id: Int, method: String, params: [String: JSONValue]? = nil) {
        self.jsonrpc = "2.0"
        self.id = .int(id)
        self.method = method
        self.params = params
    }
}

public struct MCPResponse: Decodable, Sendable {
    public let id: JSONRPCId?
    public let result: MCPResult?
    public let error: MCPError?

    public init(id: JSONRPCId? = nil, result: MCPResult? = nil, error: MCPError? = nil) {
        self.id = id
        self.result = result
        self.error = error
    }

    enum CodingKeys: String, CodingKey {
        case id
        case result
        case error
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decodeIfPresent(JSONRPCId.self, forKey: .id)
        self.error = try container.decodeIfPresent(MCPError.self, forKey: .error)

        if self.error != nil {
            self.result = nil
        } else if container.contains(.result) {
            self.result = try container.decodeIfPresent(MCPResult.self, forKey: .result) ?? MCPResult()
        } else {
            self.result = MCPResult()
        }
    }
}

public struct MCPResult: Decodable, Sendable {
    public let content: [MCPContent]?
    public let tools: [MCPToolDefinition]?
    public let capabilities: MCPCapabilities?
    public let raw: [String: JSONValue]

    public init(
        content: [MCPContent]? = nil,
        tools: [MCPToolDefinition]? = nil,
        capabilities: MCPCapabilities? = nil,
        raw: [String: JSONValue] = [:]
    ) {
        self.content = content
        self.tools = tools
        self.capabilities = capabilities
        self.raw = raw
    }

    private struct DynamicCodingKey: CodingKey {
        var stringValue: String
        var intValue: Int?

        init?(stringValue: String) {
            self.stringValue = stringValue
            self.intValue = nil
        }

        init?(intValue: Int) {
            self.stringValue = String(intValue)
            self.intValue = intValue
        }
    }

    enum CodingKeys: String, CodingKey {
        case content
        case tools
        case capabilities
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.content = try container.decodeIfPresent([MCPContent].self, forKey: .content)
        self.tools = try container.decodeIfPresent([MCPToolDefinition].self, forKey: .tools)
        self.capabilities = try container.decodeIfPresent(MCPCapabilities.self, forKey: .capabilities)

        let dynamicContainer = try decoder.container(keyedBy: DynamicCodingKey.self)
        var rawDict = [String: JSONValue]()
        for key in dynamicContainer.allKeys {
            let value = try dynamicContainer.decode(JSONValue.self, forKey: key)
            rawDict[key.stringValue] = value
        }

        rawDict = Self.patchStructuredContent(rawDict, content: self.content)

        self.raw = rawDict
    }

    private static func patchStructuredContent(
        _ raw: [String: JSONValue],
        content: [MCPContent]?
    ) -> [String: JSONValue] {
        guard let contentItems = content, !contentItems.isEmpty else { return raw }
        guard raw["structuredContent"] == nil else { return raw }

        guard let textItem = contentItems.first(where: { $0.type == "text" }),
              let text = textItem.text else {
            return raw
        }

        var patched = raw
        if let jsonData = text.data(using: .utf8),
           let parsed = try? JSONDecoder().decode(JSONValue.self, from: jsonData) {
            patched["structuredContent"] = parsed
        } else {
            patched["structuredContent"] = .object(["text": .string(text)])
        }

        return patched
    }
}

public struct MCPContent: Decodable, Sendable {
    public let type: String
    public let text: String?

    public init(type: String, text: String? = nil) {
        self.type = type
        self.text = text
    }
}

public struct MCPCapabilities: Decodable, Sendable {
    public let tools: MCPToolsCapability?

    public init(tools: MCPToolsCapability? = nil) {
        self.tools = tools
    }
}

public struct MCPToolsCapability: Decodable, Sendable {
    public let listChanged: Bool?

    public init(listChanged: Bool? = nil) {
        self.listChanged = listChanged
    }
}

public struct MCPError: Decodable, Sendable {
    public let code: Int
    public let message: String

    public init(code: Int, message: String) {
        self.code = code
        self.message = message
    }
}

public struct MCPToolDefinition: Decodable, Sendable {
    public let name: String
    public let description: String?
    public let inputSchema: [String: JSONValue]?

    public init(name: String, description: String? = nil, inputSchema: [String: JSONValue]? = nil) {
        self.name = name
        self.description = description
        self.inputSchema = inputSchema
    }
}

public struct MCPNotification: Encodable, Sendable {
    public let jsonrpc: String
    public let method: String
    public let params: [String: JSONValue]?

    public init(method: String, params: [String: JSONValue]? = nil) {
        self.jsonrpc = "2.0"
        self.method = method
        self.params = params
    }
}
