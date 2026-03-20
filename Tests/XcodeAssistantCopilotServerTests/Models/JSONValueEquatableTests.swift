import Foundation
import Testing
@testable import XcodeAssistantCopilotServer

@Test func equalityStringMatchesIdenticalString() {
    #expect(JSONValue.string("hello") == JSONValue.string("hello"))
}

@Test func equalityStringDoesNotMatchDifferentString() {
    #expect(JSONValue.string("hello") != JSONValue.string("world"))
}

@Test func equalityEmptyStringMatchesEmptyString() {
    #expect(JSONValue.string("") == JSONValue.string(""))
}

@Test func equalityIntMatchesIdenticalInt() {
    #expect(JSONValue.int(42) == JSONValue.int(42))
}

@Test func equalityIntDoesNotMatchDifferentInt() {
    #expect(JSONValue.int(1) != JSONValue.int(2))
}

@Test func equalityNegativeIntMatchesIdenticalNegativeInt() {
    #expect(JSONValue.int(-99) == JSONValue.int(-99))
}

@Test func equalityDoubleMatchesIdenticalDouble() {
    #expect(JSONValue.double(3.14) == JSONValue.double(3.14))
}

@Test func equalityDoubleDoesNotMatchDifferentDouble() {
    #expect(JSONValue.double(1.0) != JSONValue.double(1.1))
}

@Test func equalityBoolTrueMatchesBoolTrue() {
    #expect(JSONValue.bool(true) == JSONValue.bool(true))
}

@Test func equalityBoolFalseMatchesBoolFalse() {
    #expect(JSONValue.bool(false) == JSONValue.bool(false))
}

@Test func equalityBoolTrueDoesNotMatchBoolFalse() {
    #expect(JSONValue.bool(true) != JSONValue.bool(false))
}

@Test func equalityNullMatchesNull() {
    #expect(JSONValue.null == JSONValue.null)
}

@Test func equalityBoolTrueNotEqualToIntOne() {
    #expect(JSONValue.bool(true) != JSONValue.int(1))
}

@Test func equalityBoolFalseNotEqualToIntZero() {
    #expect(JSONValue.bool(false) != JSONValue.int(0))
}

@Test func equalityIntNotEqualToMatchingDouble() {
    #expect(JSONValue.int(3) != JSONValue.double(3.0))
}

@Test func equalityStringNotEqualToInt() {
    #expect(JSONValue.string("1") != JSONValue.int(1))
}

@Test func equalityStringNotEqualToBool() {
    #expect(JSONValue.string("true") != JSONValue.bool(true))
}

@Test func equalityNullNotEqualToString() {
    #expect(JSONValue.null != JSONValue.string(""))
}

@Test func equalityNullNotEqualToIntZero() {
    #expect(JSONValue.null != JSONValue.int(0))
}

@Test func equalityNullNotEqualToBoolFalse() {
    #expect(JSONValue.null != JSONValue.bool(false))
}

@Test func equalityIdenticalArraysAreEqual() {
    let a = JSONValue.array([.int(1), .int(2)])
    let b = JSONValue.array([.int(1), .int(2)])
    #expect(a == b)
}

@Test func equalityArraysWithDifferentValuesAreNotEqual() {
    let a = JSONValue.array([.int(1), .int(2)])
    let b = JSONValue.array([.int(1), .int(3)])
    #expect(a != b)
}

@Test func equalityArraysWithDifferentLengthsAreNotEqual() {
    let a = JSONValue.array([.int(1)])
    let b = JSONValue.array([.int(1), .int(2)])
    #expect(a != b)
}

@Test func equalityEmptyArraysAreEqual() {
    #expect(JSONValue.array([]) == JSONValue.array([]))
}

@Test func equalityArraysWithMixedTypesAreEqual() {
    let a = JSONValue.array([.string("x"), .bool(true), .null])
    let b = JSONValue.array([.string("x"), .bool(true), .null])
    #expect(a == b)
}

@Test func equalityArrayOrderMatters() {
    let a = JSONValue.array([.int(1), .int(2)])
    let b = JSONValue.array([.int(2), .int(1)])
    #expect(a != b)
}

@Test func equalityIdenticalObjectsAreEqual() {
    let a = JSONValue.object(["key": .string("value")])
    let b = JSONValue.object(["key": .string("value")])
    #expect(a == b)
}

@Test func equalityObjectsWithDifferentValuesAreNotEqual() {
    let a = JSONValue.object(["key": .string("value")])
    let b = JSONValue.object(["key": .string("other")])
    #expect(a != b)
}

@Test func equalityObjectsWithDifferentKeysAreNotEqual() {
    let a = JSONValue.object(["keyA": .int(1)])
    let b = JSONValue.object(["keyB": .int(1)])
    #expect(a != b)
}

@Test func equalityEmptyObjectsAreEqual() {
    #expect(JSONValue.object([:]) == JSONValue.object([:]))
}

@Test func equalityObjectsWithMultipleKeysAreEqual() {
    let a = JSONValue.object(["name": .string("swift"), "version": .int(6)])
    let b = JSONValue.object(["name": .string("swift"), "version": .int(6)])
    #expect(a == b)
}

@Test func equalityNestedArraysAreEqual() {
    let inner = JSONValue.array([.string("a")])
    let a = JSONValue.array([inner])
    let b = JSONValue.array([.array([.string("a")])])
    #expect(a == b)
}

@Test func equalityNestedObjectsAreEqual() {
    let a = JSONValue.object(["outer": .object(["inner": .bool(true)])])
    let b = JSONValue.object(["outer": .object(["inner": .bool(true)])])
    #expect(a == b)
}

@Test func equalityObjectContainingArrayIsEqual() {
    let a = JSONValue.object(["items": .array([.int(1), .int(2)])])
    let b = JSONValue.object(["items": .array([.int(1), .int(2)])])
    #expect(a == b)
}

@Test func hashableEqualValuesProduceSameHash() {
    let a = JSONValue.int(42)
    let b = JSONValue.int(42)
    #expect(a.hashValue == b.hashValue)
}

@Test func hashableEqualStringsProduceSameHash() {
    let a = JSONValue.string("hello")
    let b = JSONValue.string("hello")
    #expect(a.hashValue == b.hashValue)
}

@Test func hashableEqualBooleansProduceSameHash() {
    #expect(JSONValue.bool(true).hashValue == JSONValue.bool(true).hashValue)
    #expect(JSONValue.bool(false).hashValue == JSONValue.bool(false).hashValue)
}

@Test func hashableNullProducesSameHash() {
    #expect(JSONValue.null.hashValue == JSONValue.null.hashValue)
}

@Test func hashableDoubleProducesSameHash() {
    let a = JSONValue.double(2.718)
    let b = JSONValue.double(2.718)
    #expect(a.hashValue == b.hashValue)
}

@Test func hashableBoolTrueAndIntOneDifferentHashes() {
    let boolHash = JSONValue.bool(true).hashValue
    let intHash = JSONValue.int(1).hashValue
    #expect(boolHash != intHash)
}

@Test func hashableBoolFalseAndIntZeroDifferentHashes() {
    let boolHash = JSONValue.bool(false).hashValue
    let intHash = JSONValue.int(0).hashValue
    #expect(boolHash != intHash)
}

@Test func hashableCanBeInsertedIntoSet() {
    let set: Set<JSONValue> = [
        .string("a"),
        .string("b"),
        .string("a")
    ]
    #expect(set.count == 2)
}

@Test func hashableSetContainsLookupByValue() {
    let set: Set<JSONValue> = [.int(1), .int(2), .int(3)]
    #expect(set.contains(.int(2)))
    #expect(!set.contains(.int(99)))
}

@Test func hashableMixedTypeSetDeduplicatesCorrectly() {
    let set: Set<JSONValue> = [
        .bool(true),
        .int(1),
        .bool(true)
    ]
    #expect(set.count == 2)
}

@Test func hashableNullDeduplicatedInSet() {
    let set: Set<JSONValue> = [.null, .null]
    #expect(set.count == 1)
}

@Test func hashableCanBeUsedAsDictionaryKey() {
    var dict: [JSONValue: String] = [:]
    let key = JSONValue.string("key")
    dict[key] = "value"
    #expect(dict[JSONValue.string("key")] == "value")
}

@Test func hashableDictionaryKeyLookupByEqualValue() {
    var dict: [JSONValue: Int] = [:]
    dict[.int(10)] = 100
    dict[.bool(false)] = 200
    #expect(dict[.int(10)] == 100)
    #expect(dict[.bool(false)] == 200)
    #expect(dict.count == 2)
}

@Test func hashableDictionaryKeyMissReturnsNil() {
    let dict: [JSONValue: String] = [.string("present"): "yes"]
    #expect(dict[.string("absent")] == nil)
}