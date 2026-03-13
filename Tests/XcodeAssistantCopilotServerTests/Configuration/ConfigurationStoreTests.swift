import Testing
import Foundation
@testable import XcodeAssistantCopilotServer

@Test func initialConfigurationIsReturnedByCurrent() async {
    let config = ServerConfiguration(allowedCliTools: ["git"])
    let store = ConfigurationStore(initial: config)
    let current = await store.current()
    #expect(current.allowedCliTools == ["git"])
}

@Test func updateChangesCurrentConfiguration() async {
    let initial = ServerConfiguration(allowedCliTools: ["git"])
    let updated = ServerConfiguration(allowedCliTools: ["git", "xcodebuild"])
    let store = ConfigurationStore(initial: initial)
    await store.update(updated)
    let current = await store.current()
    #expect(current.allowedCliTools == ["git", "xcodebuild"])
}

@Test func multipleUpdatesReturnLatest() async {
    let initial = ServerConfiguration(allowedCliTools: ["git"])
    let first = ServerConfiguration(allowedCliTools: ["git", "xcodebuild"])
    let second = ServerConfiguration(allowedCliTools: ["swift"])
    let store = ConfigurationStore(initial: initial)
    await store.update(first)
    await store.update(second)
    let current = await store.current()
    #expect(current.allowedCliTools == ["swift"])
}
