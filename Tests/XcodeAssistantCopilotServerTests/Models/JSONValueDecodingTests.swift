import Foundation
import Testing
@testable import XcodeAssistantCopilotServer

@Test func decodesJSONNull() throws {
    let json = "null".data(using: .utf8)!
    let decoded = try JSONDecoder().decode(JSONValue.self, from: json)
    guard case .null = decoded else {
        Issue.record("Expected .null, got \(decoded)")
        return
    }
}

@Test func decodesJSONBoolTrue() throws {
    let json = "true".data(using: .utf8)!
    let decoded = try JSONDecoder().decode(JSONValue.self, from: json)
    guard case .bool(let value) = decoded else {
        Issue.record("Expected .bool, got \(decoded)")
        return
    }
    #expect(value == true)
}

@Test func decodesJSONBoolFalse() throws {
    let json = "false".data(using: .utf8)!
    let decoded = try JSONDecoder().decode(JSONValue.self, from: json)
    guard case .bool(let value) = decoded else {
        Issue.record("Expected .bool, got \(decoded)")
        return
    }
    #expect(value == false)
}

@Test func decodesJSONInteger() throws {
    let json = "42".data(using: .utf8)!
    let decoded = try JSONDecoder().decode(JSONValue.self, from: json)
    guard case .int(let value) = decoded else {
        Issue.record("Expected .int, got \(decoded)")
        return
    }
    #expect(value == 42)
}

@Test func decodesJSONNegativeInteger() throws {
    let json = "-99".data(using: .utf8)!
    let decoded = try JSONDecoder().decode(JSONValue.self, from: json)
    guard case .int(let value) = decoded else {
        Issue.record("Expected .int, got \(decoded)")
        return
    }
    #expect(value == -99)
}

@Test func decodesJSONZero() throws {
    let json = "0".data(using: .utf8)!
    let decoded = try JSONDecoder().decode(JSONValue.self, from: json)
    guard case .int(let value) = decoded else {
        Issue.record("Expected .int, got \(decoded)")
        return
    }
    #expect(value == 0)
}

@Test func decodesJSONDouble() throws {
    let json = "3.14".data(using: .utf8)!
    let decoded = try JSONDecoder().decode(JSONValue.self, from: json)
    guard case .double(let value) = decoded else {
        Issue.record("Expected .double, got \(decoded)")
        return
    }
    #expect(abs(value - 3.14) < 1e-10)
}

@Test func decodesJSONNegativeDouble() throws {
    let json = "-2.71828".data(using: .utf8)!
    let decoded = try JSONDecoder().decode(JSONValue.self, from: json)
    guard case .double(let value) = decoded else {
        Issue.record("Expected .double, got \(decoded)")
        return
    }
    #expect(abs(value - (-2.71828)) < 1e-10)
}

@Test func decodesJSONString() throws {
    let json = #""hello world""#.data(using: .utf8)!
    let decoded = try JSONDecoder().decode(JSONValue.self, from: json)
    guard case .string(let value) = decoded else {
        Issue.record("Expected .string, got \(decoded)")
        return
    }
    #expect(value == "hello world")
}

@Test func decodesJSONEmptyString() throws {
    let json = #""""#.data(using: .utf8)!
    let decoded = try JSONDecoder().decode(JSONValue.self, from: json)
    guard case .string(let value) = decoded else {
        Issue.record("Expected .string, got \(decoded)")
        return
    }
    #expect(value == "")
}

@Test func decodesJSONArray() throws {
    let json = #"[1, "two", true, null]"#.data(using: .utf8)!
    let decoded = try JSONDecoder().decode(JSONValue.self, from: json)
    guard case .array(let elements) = decoded else {
        Issue.record("Expected .array, got \(decoded)")
        return
    }
    #expect(elements.count == 4)

    guard case .int(let first) = elements[0] else {
        Issue.record("Expected .int at index 0"); return
    }
    #expect(first == 1)

    guard case .string(let second) = elements[1] else {
        Issue.record("Expected .string at index 1"); return
    }
    #expect(second == "two")

    guard case .bool(let third) = elements[2] else {
        Issue.record("Expected .bool at index 2"); return
    }
    #expect(third == true)

    guard case .null = elements[3] else {
        Issue.record("Expected .null at index 3"); return
    }
}

@Test func decodesJSONEmptyArray() throws {
    let json = "[]".data(using: .utf8)!
    let decoded = try JSONDecoder().decode(JSONValue.self, from: json)
    guard case .array(let elements) = decoded else {
        Issue.record("Expected .array, got \(decoded)")
        return
    }
    #expect(elements.isEmpty)
}

@Test func decodesJSONObject() throws {
    let json = #"{"name": "swift", "version": 6, "stable": true}"#.data(using: .utf8)!
    let decoded = try JSONDecoder().decode(JSONValue.self, from: json)
    guard case .object(let dict) = decoded else {
        Issue.record("Expected .object, got \(decoded)")
        return
    }
    #expect(dict.count == 3)

    guard let nameVal = dict["name"], case .string(let name) = nameVal else {
        Issue.record("Expected .string for 'name'"); return
    }
    #expect(name == "swift")

    guard let versionVal = dict["version"], case .int(let version) = versionVal else {
        Issue.record("Expected .int for 'version'"); return
    }
    #expect(version == 6)

    guard let stableVal = dict["stable"], case .bool(let stable) = stableVal else {
        Issue.record("Expected .bool for 'stable'"); return
    }
    #expect(stable == true)
}

@Test func decodesJSONEmptyObject() throws {
    let json = "{}".data(using: .utf8)!
    let decoded = try JSONDecoder().decode(JSONValue.self, from: json)
    guard case .object(let dict) = decoded else {
        Issue.record("Expected .object, got \(decoded)")
        return
    }
    #expect(dict.isEmpty)
}

@Test func jsonBoolTrueIsNotDecodedAsInt() throws {
    let json = #"{"flag": true, "count": 1}"#.data(using: .utf8)!
    let decoded = try JSONDecoder().decode(JSONValue.self, from: json)
    guard case .object(let dict) = decoded else {
        Issue.record("Expected .object"); return
    }

    guard let flagVal = dict["flag"], case .bool(let flag) = flagVal else {
        Issue.record("Expected .bool for JSON true, got \(String(describing: dict["flag"]))")
        return
    }
    #expect(flag == true)

    guard let countVal = dict["count"], case .int(let count) = countVal else {
        Issue.record("Expected .int for JSON 1, got \(String(describing: dict["count"]))")
        return
    }
    #expect(count == 1)
}

@Test func jsonBoolFalseIsNotDecodedAsInt() throws {
    let json = #"{"enabled": false, "value": 0}"#.data(using: .utf8)!
    let decoded = try JSONDecoder().decode(JSONValue.self, from: json)
    guard case .object(let dict) = decoded else {
        Issue.record("Expected .object"); return
    }

    guard let enabledVal = dict["enabled"], case .bool(let enabled) = enabledVal else {
        Issue.record("Expected .bool for JSON false, got \(String(describing: dict["enabled"]))")
        return
    }
    #expect(enabled == false)

    guard let valueVal = dict["value"], case .int(let value) = valueVal else {
        Issue.record("Expected .int for JSON 0, got \(String(describing: dict["value"]))")
        return
    }
    #expect(value == 0)
}

@Test func decodesInt64MaxAsInt() throws {
    let json = "\(Int64.max)".data(using: .utf8)!
    let decoded = try JSONDecoder().decode(JSONValue.self, from: json)
    guard case .int(let value) = decoded else {
        Issue.record("Expected .int for Int64.max, got \(decoded)")
        return
    }
    #expect(value == Int.max)
}

@Test func decodesLargeUInt64AsDouble() throws {
    let json = "9223372036854775808".data(using: .utf8)!
    let decoded = try JSONDecoder().decode(JSONValue.self, from: json)
    guard case .double(let value) = decoded else {
        Issue.record("Expected .double for Int64.max+1, got \(decoded)")
        return
    }
    #expect(value >= Double(Int64.max))
}

@Test func decodesLargeIntWithinRangeAsInt() throws {
    let large = 1_000_000_000_000
    let json = "\(large)".data(using: .utf8)!
    let decoded = try JSONDecoder().decode(JSONValue.self, from: json)
    guard case .int(let value) = decoded else {
        Issue.record("Expected .int for \(large), got \(decoded)")
        return
    }
    #expect(value == large)
}

@Test func decodesNestedObject() throws {
    let json = #"{"outer": {"inner": "value"}}"#.data(using: .utf8)!
    let decoded = try JSONDecoder().decode(JSONValue.self, from: json)
    guard case .object(let outer) = decoded else {
        Issue.record("Expected .object at root"); return
    }
    guard let outerVal = outer["outer"], case .object(let inner) = outerVal else {
        Issue.record("Expected .object for 'outer'"); return
    }
    guard let innerVal = inner["inner"], case .string(let value) = innerVal else {
        Issue.record("Expected .string for 'inner'"); return
    }
    #expect(value == "value")
}

@Test func decodesArrayOfObjects() throws {
    let json = #"[{"id": 1}, {"id": 2}]"#.data(using: .utf8)!
    let decoded = try JSONDecoder().decode(JSONValue.self, from: json)
    guard case .array(let elements) = decoded else {
        Issue.record("Expected .array"); return
    }
    #expect(elements.count == 2)
    for (index, element) in elements.enumerated() {
        guard case .object(let dict) = element,
              let idVal = dict["id"],
              case .int(let id) = idVal else {
            Issue.record("Expected .object with .int 'id' at index \(index)")
            return
        }
        #expect(id == index + 1)
    }
}

@Test func roundTripString() throws {
    let original: JSONValue = .string("round-trip")
    let data = try JSONEncoder().encode(original)
    let decoded = try JSONDecoder().decode(JSONValue.self, from: data)
    #expect(decoded == original)
}

@Test func roundTripInt() throws {
    let original: JSONValue = .int(12345)
    let data = try JSONEncoder().encode(original)
    let decoded = try JSONDecoder().decode(JSONValue.self, from: data)
    #expect(decoded == original)
}

@Test func roundTripDouble() throws {
    let original: JSONValue = .double(2.71828)
    let data = try JSONEncoder().encode(original)
    let decoded = try JSONDecoder().decode(JSONValue.self, from: data)
    #expect(decoded == original)
}

@Test func roundTripBoolTrue() throws {
    let original: JSONValue = .bool(true)
    let data = try JSONEncoder().encode(original)
    let decoded = try JSONDecoder().decode(JSONValue.self, from: data)
    #expect(decoded == original)
}

@Test func roundTripBoolFalse() throws {
    let original: JSONValue = .bool(false)
    let data = try JSONEncoder().encode(original)
    let decoded = try JSONDecoder().decode(JSONValue.self, from: data)
    #expect(decoded == original)
}

@Test func roundTripNull() throws {
    let original: JSONValue = .null
    let data = try JSONEncoder().encode(original)
    let decoded = try JSONDecoder().decode(JSONValue.self, from: data)
    #expect(decoded == original)
}

@Test func roundTripArray() throws {
    let original: JSONValue = .array([.int(1), .string("two"), .bool(true), .null])
    let data = try JSONEncoder().encode(original)
    let decoded = try JSONDecoder().decode(JSONValue.self, from: data)
    #expect(decoded == original)
}

@Test func roundTripObject() throws {
    let original: JSONValue = .object([
        "name": .string("test"),
        "value": .int(99),
        "active": .bool(false)
    ])
    let data = try JSONEncoder().encode(original)
    let decoded = try JSONDecoder().decode(JSONValue.self, from: data)
    #expect(decoded == original)
}

@Test func roundTripNestedStructure() throws {
    let original: JSONValue = .object([
        "items": .array([
            .object(["id": .int(1)]),
            .object(["id": .int(2)])
        ]),
        "count": .int(2)
    ])
    let data = try JSONEncoder().encode(original)
    let decoded = try JSONDecoder().decode(JSONValue.self, from: data)
    #expect(decoded == original)
}