import Foundation

extension FileHandle {
    func asyncDataStream(
        bufferingPolicy: AsyncStream<Data>.Continuation.BufferingPolicy = .unbounded
    ) -> AsyncStream<Data> {
        AsyncStream(bufferingPolicy: bufferingPolicy) { continuation in
            self.readabilityHandler = { handle in
                let data = handle.availableData
                if data.isEmpty {
                    handle.readabilityHandler = nil
                    continuation.finish()
                } else {
                    continuation.yield(data)
                }
            }
            continuation.onTermination = { @Sendable _ in
                self.readabilityHandler = nil
            }
        }
    }
}