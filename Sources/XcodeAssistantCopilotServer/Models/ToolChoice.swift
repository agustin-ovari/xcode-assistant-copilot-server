import Foundation

public enum ToolChoice: Codable, Sendable, Equatable {
    case none
    case auto
    case required
    case function(name: String)

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let raw = try? container.decode(String.self) {
            switch raw {
            case "none": self = .none
            case "auto": self = .auto
            case "required": self = .required
            default:
                throw DecodingError.dataCorruptedError(
                    in: container,
                    debugDescription: "Unknown tool_choice string: \(raw)"
                )
            }
            return
        }
        let objectContainer = try decoder.container(keyedBy: ObjectCodingKeys.self)
        let type = try objectContainer.decode(String.self, forKey: .type)
        guard type == "function" else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Unknown tool_choice type: \(type)"
            )
        }
        let functionContainer = try objectContainer.nestedContainer(keyedBy: FunctionCodingKeys.self, forKey: .function)
        let name = try functionContainer.decode(String.self, forKey: .name)
        self = .function(name: name)
    }

    public func encode(to encoder: Encoder) throws {
        switch self {
        case .none:
            var container = encoder.singleValueContainer()
            try container.encode("none")
        case .auto:
            var container = encoder.singleValueContainer()
            try container.encode("auto")
        case .required:
            var container = encoder.singleValueContainer()
            try container.encode("required")
        case .function(let name):
            var container = encoder.container(keyedBy: ObjectCodingKeys.self)
            try container.encode("function", forKey: .type)
            var functionContainer = container.nestedContainer(keyedBy: FunctionCodingKeys.self, forKey: .function)
            try functionContainer.encode(name, forKey: .name)
        }
    }

    private enum ObjectCodingKeys: String, CodingKey {
        case type
        case function
    }

    private enum FunctionCodingKeys: String, CodingKey {
        case name
    }
}
