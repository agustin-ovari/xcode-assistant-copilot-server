import Foundation

public struct ToolFunction: Codable, Sendable {
    public let name: String
    public let description: String?
    public let parameters: [String: JSONValue]?

    public init(name: String, description: String? = nil, parameters: [String: JSONValue]? = nil) {
        self.name = name
        self.description = description
        self.parameters = parameters
    }
}

public struct Tool: Codable, Sendable {
    public let type: String
    public let function: ToolFunction

    public init(type: String, function: ToolFunction) {
        self.type = type
        self.function = function
    }
}

public struct ChatCompletionRequest: Codable, Sendable {
    public let model: String
    public let messages: [ChatCompletionMessage]
    public let temperature: Double?
    public let topP: Double?
    public let stop: StopSequence?
    public let maxTokens: Int?
    public let presencePenalty: Double?
    public let frequencyPenalty: Double?
    public let tools: [Tool]?
    public let toolChoice: ToolChoice?
    public let user: String?
    public let stream: Bool?

    enum CodingKeys: String, CodingKey {
        case model
        case messages
        case temperature
        case topP = "top_p"
        case stop
        case maxTokens = "max_tokens"
        case presencePenalty = "presence_penalty"
        case frequencyPenalty = "frequency_penalty"
        case tools
        case toolChoice = "tool_choice"
        case user
        case stream
    }

    public init(
        model: String,
        messages: [ChatCompletionMessage],
        temperature: Double? = nil,
        topP: Double? = nil,
        stop: StopSequence? = nil,
        maxTokens: Int? = nil,
        presencePenalty: Double? = nil,
        frequencyPenalty: Double? = nil,
        tools: [Tool]? = nil,
        toolChoice: ToolChoice? = nil,
        user: String? = nil,
        stream: Bool? = nil
    ) {
        self.model = model
        self.messages = messages
        self.temperature = temperature
        self.topP = topP
        self.stop = stop
        self.maxTokens = maxTokens
        self.presencePenalty = presencePenalty
        self.frequencyPenalty = frequencyPenalty
        self.tools = tools
        self.toolChoice = toolChoice
        self.user = user
        self.stream = stream
    }
}

public enum StopSequence: Codable, Sendable {
    case single(String)
    case multiple([String])

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let text = try? container.decode(String.self) {
            self = .single(text)
        } else if let array = try? container.decode([String].self) {
            self = .multiple(array)
        } else {
            throw DecodingError.typeMismatch(
                StopSequence.self,
                DecodingError.Context(
                    codingPath: decoder.codingPath,
                    debugDescription: "Expected String or [String] for stop sequence"
                )
            )
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .single(let text):
            try container.encode(text)
        case .multiple(let array):
            try container.encode(array)
        }
    }
}
