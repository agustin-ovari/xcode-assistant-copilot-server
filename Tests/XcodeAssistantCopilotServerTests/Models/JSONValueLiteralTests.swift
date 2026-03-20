import Foundation
import Testing
@testable import XcodeAssistantCopilotServer

@Test func stringLiteralCreatesStringCase() {
    let v: JSONValue = "hello"
    guard case .string(let s) = v else {
        Issue.record("Expected .string, got \(v)")
        return
    }
    #expect(s == "hello")
}

@Test func integerLiteralCreatesIntCase() {
    let v: JSONValue = 42
    guard case .int(let i) = v else {
        Issue.record("Expected .int, got \(v)")
        return
    }
    #expect(i == 42)
}

@Test func floatLiteralCreatesDoubleCase() {
    let v: JSONValue = 3.14
    guard case .double(let d) = v else {
        Issue.record("Expected .double, got \(v)")
        return
    }
    #expect(abs(d - 3.14) < 1e-10)
}

@Test func boolLiteralCreatesBoolCase() {
    let v: JSONValue = true
    guard case .bool(let b) = v else {
        Issue.record("Expected .bool, got \(v)")
        return
    }
    #expect(b == true)
}

@Test func nilLiteralCreatesNullCase() {
    let v: JSONValue = nil
    guard case .null = v else {
        Issue.record("Expected .null, got \(v)")
        return
    }
}

@Test func arrayLiteralCreatesArrayCase() {
    let v: JSONValue = [1, "two", true]
    guard case .array(let elements) = v else {
        Issue.record("Expected .array, got \(v)")
        return
    }
    #expect(elements.count == 3)
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
}

@Test func dictionaryLiteralCreatesObjectCase() {
    let v: JSONValue = ["key": "value"]
    guard case .object(let dict) = v else {
        Issue.record("Expected .object, got \(v)")
        return
    }
    guard let keyVal = dict["key"], case .string(let s) = keyVal else {
        Issue.record("Expected .string for 'key'"); return
    }
    #expect(s == "value")
}

@Test func nestedLiteralsWork() {
    let v: JSONValue = ["name": "test", "count": 5]
    guard case .object(let dict) = v else {
        Issue.record("Expected .object, got \(v)")
        return
    }
    guard let nameVal = dict["name"], case .string(let name) = nameVal else {
        Issue.record("Expected .string for 'name'"); return
    }
    #expect(name == "test")
    guard let countVal = dict["count"], case .int(let count) = countVal else {
        Issue.record("Expected .int for 'count'"); return
    }
    #expect(count == 5)
}

@Test func accessorBoolValue() {
    #expect(JSONValue.bool(true).boolValue == true)
    #expect(JSONValue.bool(false).boolValue == false)
    #expect(JSONValue.string("true").boolValue == nil)
    #expect(JSONValue.int(1).boolValue == nil)
    #expect(JSONValue.null.boolValue == nil)
    #expect(JSONValue.array([]).boolValue == nil)
    #expect(JSONValue.object([:]).boolValue == nil)
    #expect(JSONValue.double(1.0).boolValue == nil)
    #expect(JSONValue.string("hello").stringValue == "hello")
    #expect(JSONValue.int(42).intValue == 42)
    #expect(JSONValue.double(3.14).doubleValue == 3.14)
    #expect(JSONValue.array([.int(1)]).arrayValue?.count == 1)
    #expect(JSONValue.object(["k": .string("v")]).objectValue?["k"] == .string("v"))
}