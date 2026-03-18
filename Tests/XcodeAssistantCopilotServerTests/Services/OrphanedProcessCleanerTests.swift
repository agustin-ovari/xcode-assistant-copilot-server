import Foundation
import Synchronization
import Testing

@testable import XcodeAssistantCopilotServer

@Suite("OrphanedProcessCleaner Tests")
struct OrphanedProcessCleanerTests {

    @Test("Does nothing when no PID file exists")
    func noPIDFile() async {
        let mockPIDFile = MockMCPBridgePIDFile()
        let logger = MockLogger()
        let cleaner = OrphanedProcessCleaner(pidFile: mockPIDFile, logger: logger)

        await cleaner.cleanupIfNeeded()

        #expect(mockPIDFile.readCallCount == 1)
        #expect(mockPIDFile.removeCallCount == 0)
        #expect(mockPIDFile.isProcessRunningCallCount == 0)
    }

    @Test("Removes stale PID file when process is no longer running")
    func staleProcessNotRunning() async {
        let mockPIDFile = MockMCPBridgePIDFile()
        mockPIDFile.storedPID = 12345
        mockPIDFile.processRunning = false
        let logger = MockLogger()
        let cleaner = OrphanedProcessCleaner(pidFile: mockPIDFile, logger: logger)

        await cleaner.cleanupIfNeeded()

        #expect(mockPIDFile.readCallCount == 1)
        #expect(mockPIDFile.isProcessRunningCallCount == 1)
        #expect(mockPIDFile.isProcessRunningReceivedPID == 12345)
        #expect(mockPIDFile.removeCallCount == 1)
        #expect(logger.infoMessages.contains { $0.contains("no longer running") })
    }

    @Test("Terminates orphaned process that is still running and removes PID file")
    func terminatesOrphanedProcess() async {
        let mockPIDFile = MockMCPBridgePIDFile()
        mockPIDFile.storedPID = 99999
        mockPIDFile.processRunning = true
        mockPIDFile.processBecomesDeadAfterCheck = 1
        let logger = MockLogger()
        let cleaner = OrphanedProcessCleaner(pidFile: mockPIDFile, logger: logger)

        await cleaner.cleanupIfNeeded()

        #expect(mockPIDFile.readCallCount == 1)
        #expect(mockPIDFile.isProcessRunningCallCount >= 2)
        #expect(mockPIDFile.removeCallCount == 1)
        #expect(logger.warnMessages.contains { $0.contains("Orphaned MCP bridge process detected") })
        #expect(logger.infoMessages.contains { $0.contains("cleaned up") })
    }

    @Test("Sends SIGKILL when process does not terminate gracefully")
    func sendsKillWhenProcessDoesNotTerminate() async {
        let mockPIDFile = MockMCPBridgePIDFile()
        mockPIDFile.storedPID = 88888
        mockPIDFile.processRunning = true
        mockPIDFile.processBecomesDeadAfterCheck = .max
        let logger = MockLogger()
        let cleaner = OrphanedProcessCleaner(pidFile: mockPIDFile, logger: logger)

        await cleaner.cleanupIfNeeded()

        #expect(mockPIDFile.removeCallCount == 1)
        #expect(logger.warnMessages.contains { $0.contains("SIGKILL") })
    }

    @Test("Logs PID correctly when orphaned process found")
    func logsPIDCorrectly() async {
        let mockPIDFile = MockMCPBridgePIDFile()
        mockPIDFile.storedPID = 54321
        mockPIDFile.processRunning = false
        let logger = MockLogger()
        let cleaner = OrphanedProcessCleaner(pidFile: mockPIDFile, logger: logger)

        await cleaner.cleanupIfNeeded()

        #expect(logger.infoMessages.contains { $0.contains("54321") })
    }
}

final class MockMCPBridgePIDFile: MCPBridgePIDFileProtocol, Sendable {
    private struct State {
        var storedPID: Int32?
        var processRunning: Bool = false
        var processBecomesDeadAfterCheck: Int = 0
        var writeCallCount = 0
        var writtenPID: Int32?
        var readCallCount = 0
        var removeCallCount = 0
        var isProcessRunningCallCount = 0
        var isProcessRunningReceivedPID: Int32?
    }

    private let mutex = Mutex(State())

    var storedPID: Int32? {
        get { mutex.withLock { $0.storedPID } }
        set { mutex.withLock { $0.storedPID = newValue } }
    }

    var processRunning: Bool {
        get { mutex.withLock { $0.processRunning } }
        set { mutex.withLock { $0.processRunning = newValue } }
    }

    var processBecomesDeadAfterCheck: Int {
        get { mutex.withLock { $0.processBecomesDeadAfterCheck } }
        set { mutex.withLock { $0.processBecomesDeadAfterCheck = newValue } }
    }

    var writeCallCount: Int { mutex.withLock { $0.writeCallCount } }
    var writtenPID: Int32? { mutex.withLock { $0.writtenPID } }
    var readCallCount: Int { mutex.withLock { $0.readCallCount } }
    var removeCallCount: Int { mutex.withLock { $0.removeCallCount } }
    var isProcessRunningCallCount: Int { mutex.withLock { $0.isProcessRunningCallCount } }
    var isProcessRunningReceivedPID: Int32? { mutex.withLock { $0.isProcessRunningReceivedPID } }

    func write(pid: Int32) throws {
        mutex.withLock {
            $0.writeCallCount += 1
            $0.writtenPID = pid
            $0.storedPID = pid
        }
    }

    func read() -> Int32? {
        mutex.withLock {
            $0.readCallCount += 1
            return $0.storedPID
        }
    }

    func remove() {
        mutex.withLock {
            $0.removeCallCount += 1
            $0.storedPID = nil
        }
    }

    func isProcessRunning(pid: Int32) -> Bool {
        mutex.withLock {
            $0.isProcessRunningCallCount += 1
            $0.isProcessRunningReceivedPID = pid
            if $0.isProcessRunningCallCount > $0.processBecomesDeadAfterCheck {
                return false
            }
            return $0.processRunning
        }
    }
}