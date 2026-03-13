import Darwin
import Dispatch
import Foundation

public protocol ConfigurationWatcherProtocol: Sendable {
    func start() async
    func stop() async
    func changes() async -> AsyncStream<ServerConfiguration>
}

public actor ConfigurationWatcher: ConfigurationWatcherProtocol {
    private let path: String
    private let loader: ConfigurationLoaderProtocol
    private let logger: LoggerProtocol
    private var continuation: AsyncStream<ServerConfiguration>.Continuation?
    private var source: DispatchSourceFileSystemObject?
    private var debounceTask: Task<Void, Never>?
    private var reopenTask: Task<Void, Never>?
    private var fileDescriptor: Int32 = -1

    private static let reopenAttempts = 5
    private static let reopenBaseDelayMilliseconds: Int = 50

    public init(path: String, loader: ConfigurationLoaderProtocol, logger: LoggerProtocol) {
        self.path = path
        self.loader = loader
        self.logger = logger
    }

    public func changes() -> AsyncStream<ServerConfiguration> {
        let stream = AsyncStream<ServerConfiguration> { continuation in
            self.continuation = continuation
            continuation.onTermination = { [weak self] _ in
                guard let self else { return }
                Task { await self.stop() }
            }
        }
        return stream
    }

    public func start() async {
        let fd = Darwin.open(path, O_EVTONLY)
        guard fd != -1 else {
            logger.warn("ConfigurationWatcher: failed to open file at \(path)")
            return
        }
        fileDescriptor = fd
        attachSource(fd: fd)
    }

    public func stop() async {
        debounceTask?.cancel()
        debounceTask = nil
        reopenTask?.cancel()
        reopenTask = nil
        source?.cancel()
        source = nil
        continuation?.finish()
        continuation = nil
        if fileDescriptor != -1 {
            Darwin.close(fileDescriptor)
            fileDescriptor = -1
        }
    }

    private func attachSource(fd: Int32) {
        let newSource = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fd,
            eventMask: [.write, .delete, .rename],
            queue: .global()
        )

        // data must be captured synchronously inside the event handler while
        // still on the GCD queue — it is reset after the handler returns and
        // is not safe to read later from an async Task.
        newSource.setEventHandler { [weak self] in
            guard let self else { return }
            let capturedData = newSource.data
            let sendableData = capturedData.rawValue
            Task { await self.handleEvent(DispatchSource.FileSystemEvent(rawValue: sendableData)) }
        }

        newSource.setCancelHandler { [weak self] in
            guard let self else { return }
            Task { await self.closeCancelledDescriptor(fd) }
        }

        source = newSource
        newSource.resume()
    }

    private func handleEvent(_ eventData: DispatchSource.FileSystemEvent) {
        if eventData.contains(.delete) || eventData.contains(.rename) {
            source?.cancel()
            source = nil
            scheduleReopen()
        } else if eventData.contains(.write) {
            scheduleDebounce()
        }
    }

    private func scheduleReopen() {
        reopenTask?.cancel()
        reopenTask = Task {
            await reopenWithBackoff()
        }
    }

    private func reopenWithBackoff() async {
        for attempt in 0..<Self.reopenAttempts {
            let delayMs = Self.reopenBaseDelayMilliseconds * (1 << attempt)
            do {
                try await Task.sleep(for: .milliseconds(delayMs))
            } catch {
                return
            }

            guard !Task.isCancelled else { return }

            let fd = Darwin.open(path, O_EVTONLY)
            if fd != -1 {
                fileDescriptor = fd
                attachSource(fd: fd)
                scheduleDebounce()
                return
            }

            logger.warn("ConfigurationWatcher: failed to open file at \(path) (attempt \(attempt + 1)/\(Self.reopenAttempts))")
        }

        logger.warn("ConfigurationWatcher: giving up watching \(path) after \(Self.reopenAttempts) attempts")
    }

    private func closeCancelledDescriptor(_ fd: Int32) {
        if fileDescriptor == fd {
            Darwin.close(fd)
            fileDescriptor = -1
        }
    }

    private func scheduleDebounce() {
        debounceTask?.cancel()
        debounceTask = Task {
            do {
                try await Task.sleep(for: .milliseconds(300))
                await triggerReload()
            } catch {
                // Task was cancelled — no action needed
            }
        }
    }

    private func triggerReload() async {
        do {
            let config = try loader.load(from: path)
            continuation?.yield(config)
        } catch {
            logger.warn("Failed to reload configuration: \(error)")
        }
    }
}