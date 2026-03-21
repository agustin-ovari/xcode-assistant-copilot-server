import Foundation

public actor ModelFetchCache {
    public private(set) var lastFetchTime: Date?

    public init() {}

    public func recordFetch() {
        lastFetchTime = .now
    }
}
