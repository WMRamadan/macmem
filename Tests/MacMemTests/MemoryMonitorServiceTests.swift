import XCTest
@testable import MacMemKit

final class MemoryMonitorServiceTests: XCTestCase {

    @MainActor
    func testInitialRefreshAndState() {
        let cpuMock = MockCPUMemoryReader(stubbedInfo: .mockDefault)
        let gpuMock = MockGPUMemoryReader(stubbedInfo: .mockDefault)

        let service = MemoryMonitorService(
            cpuReader: cpuMock,
            gpuReader: gpuMock,
            initialRefreshInterval: 1.0,
            maxHistoryCount: 10
        )

        // Verify that CPU and GPU are partitioned into systemOverview
        XCTAssertEqual(service.systemOverview.cpuUsedBytes + service.systemOverview.gpuUsedBytes, service.systemOverview.totalUsedBytes)
        XCTAssertEqual(service.systemOverview.cpuRatio + service.systemOverview.gpuRatio, service.systemOverview.totalUsedRatio, accuracy: 0.0001)

        XCTAssertEqual(service.cpuInfo.usedBytes, service.systemOverview.cpuUsedBytes)
        XCTAssertEqual(service.gpuInfo.allocatedBytes, service.systemOverview.gpuUsedBytes)
        XCTAssertEqual(service.history.count, 1)
        XCTAssertFalse(service.isPaused)
        XCTAssertNil(service.lastErrorMessage)
        XCTAssertNotNil(service.lastUpdated)

        service.stopMonitoring()
    }

    @MainActor
    func testHistoryTrimmingAtMaxLimit() {
        let cpuMock = MockCPUMemoryReader(stubbedInfo: .mockDefault)
        let gpuMock = MockGPUMemoryReader(stubbedInfo: .mockDefault)

        let service = MemoryMonitorService(
            cpuReader: cpuMock,
            gpuReader: gpuMock,
            initialRefreshInterval: 1.0,
            maxHistoryCount: 5
        )

        // Initial refresh added 1 sample
        for _ in 1...10 {
            service.refresh()
        }

        XCTAssertEqual(service.history.count, 5, "History count should be strictly capped at maxHistoryCount.")
        service.stopMonitoring()
    }

    @MainActor
    func testClearHistory() {
        let cpuMock = MockCPUMemoryReader(stubbedInfo: .mockDefault)
        let gpuMock = MockGPUMemoryReader(stubbedInfo: .mockDefault)

        let service = MemoryMonitorService(
            cpuReader: cpuMock,
            gpuReader: gpuMock,
            initialRefreshInterval: 1.0,
            maxHistoryCount: 10
        )

        XCTAssertGreaterThan(service.history.count, 0)
        service.clearHistory()
        XCTAssertEqual(service.history.count, 0)
        service.stopMonitoring()
    }

    @MainActor
    func testTogglePause() {
        let cpuMock = MockCPUMemoryReader(stubbedInfo: .mockDefault)
        let gpuMock = MockGPUMemoryReader(stubbedInfo: .mockDefault)

        let service = MemoryMonitorService(
            cpuReader: cpuMock,
            gpuReader: gpuMock,
            initialRefreshInterval: 1.0,
            maxHistoryCount: 10
        )

        XCTAssertFalse(service.isPaused)
        service.togglePause()
        XCTAssertTrue(service.isPaused)
        service.togglePause()
        XCTAssertFalse(service.isPaused)
        service.stopMonitoring()
    }

    @MainActor
    func testExportJSONContainsValidSnapshot() throws {
        let cpuMock = MockCPUMemoryReader(stubbedInfo: .mockDefault)
        let gpuMock = MockGPUMemoryReader(stubbedInfo: .mockDefault)

        let service = MemoryMonitorService(
            cpuReader: cpuMock,
            gpuReader: gpuMock,
            initialRefreshInterval: 1.0,
            maxHistoryCount: 10
        )

        let jsonString = try service.exportJSON()
        XCTAssertFalse(jsonString.isEmpty)

        guard let data = jsonString.data(using: .utf8) else {
            XCTFail("Failed to convert JSON string to data")
            return
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let snapshot = try decoder.decode(SystemMemorySnapshot.self, from: data)

        XCTAssertEqual(snapshot.cpu, service.cpuInfo)
        XCTAssertEqual(snapshot.gpu, service.gpuInfo)
        XCTAssertEqual(snapshot.overview, service.systemOverview)
        service.stopMonitoring()
    }

    @MainActor
    func testErrorHandlingInReaders() {
        struct MockError: Error, LocalizedError {
            var errorDescription: String? { "Sample Reader Error" }
        }

        let cpuMock = MockCPUMemoryReader(stubbedError: MockError())
        let gpuMock = MockGPUMemoryReader(stubbedInfo: .mockDefault)

        let service = MemoryMonitorService(
            cpuReader: cpuMock,
            gpuReader: gpuMock,
            initialRefreshInterval: 1.0,
            maxHistoryCount: 10
        )

        XCTAssertEqual(service.lastErrorMessage, "Sample Reader Error")
        service.stopMonitoring()
    }
}
