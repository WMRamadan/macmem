import XCTest
@testable import MacMemKit

final class CPUMemoryInfoTests: XCTestCase {

    func testUsedRatioCalculation() {
        let total: UInt64 = 16 * 1024 * 1024 * 1024
        let used: UInt64 = 8 * 1024 * 1024 * 1024

        let info = CPUMemoryInfo(
            totalPhysicalBytes: total,
            usedBytes: used,
            freeBytes: 8 * 1024 * 1024 * 1024,
            activeBytes: 4 * 1024 * 1024 * 1024,
            inactiveBytes: 4 * 1024 * 1024 * 1024,
            wiredBytes: 2 * 1024 * 1024 * 1024,
            compressedBytes: 2 * 1024 * 1024 * 1024,
            appMemoryBytes: 4 * 1024 * 1024 * 1024,
            cachedBytes: 4 * 1024 * 1024 * 1024
        )

        XCTAssertEqual(info.usedRatio, 0.5, accuracy: 0.001)
        XCTAssertEqual(info.freeRatio, 0.5, accuracy: 0.001)
        XCTAssertEqual(info.appMemoryRatio, 0.25, accuracy: 0.001)
        XCTAssertEqual(info.wiredRatio, 0.125, accuracy: 0.001)
        XCTAssertEqual(info.compressedRatio, 0.125, accuracy: 0.001)
        XCTAssertEqual(info.formattedTotal, "16.0 GB")
        XCTAssertEqual(info.formattedUsed, "8.0 GB")
        XCTAssertEqual(info.formattedUsedPercentage, "50.0%")
    }

    func testReconciliationDeductsGPUFromHostRAM() {
        let total: UInt64 = 16 * 1024 * 1024 * 1024
        let hostUsed: UInt64 = 14 * 1024 * 1024 * 1024
        let gpuAllocated: UInt64 = 10 * 1024 * 1024 * 1024 // 10 GB for LLM

        let raw = CPUMemoryInfo(
            totalPhysicalBytes: total,
            usedBytes: hostUsed,
            freeBytes: 2 * 1024 * 1024 * 1024,
            activeBytes: 8 * 1024 * 1024 * 1024,
            inactiveBytes: 2 * 1024 * 1024 * 1024,
            wiredBytes: 3 * 1024 * 1024 * 1024,
            compressedBytes: 3 * 1024 * 1024 * 1024,
            appMemoryBytes: 8 * 1024 * 1024 * 1024,
            cachedBytes: 2 * 1024 * 1024 * 1024
        )

        let reconciled = raw.reconciling(gpuAllocatedBytes: gpuAllocated, isUnifiedMemory: true)

        // Reconciled CPU used must be strictly 4 GB (hostUsed - gpuAllocated)
        XCTAssertEqual(reconciled.usedBytes, 4 * 1024 * 1024 * 1024)
        XCTAssertEqual(reconciled.usedRatio, 0.25, accuracy: 0.001)
        XCTAssertEqual(reconciled.formattedUsed, "4.0 GB")
        XCTAssertEqual(reconciled.formattedUsedPercentage, "25.0%")
        XCTAssertEqual(reconciled.systemTotalUsedBytes, hostUsed)
        XCTAssertEqual(reconciled.formattedSystemTotalUsed, "14.0 GB")
    }

    func testZeroTotalPhysicalMemorySafety() {
        let empty = CPUMemoryInfo.empty
        XCTAssertEqual(empty.usedRatio, 0.0)
        XCTAssertEqual(empty.freeRatio, 0.0)
        XCTAssertEqual(empty.appMemoryRatio, 0.0)
        XCTAssertEqual(empty.wiredRatio, 0.0)
        XCTAssertEqual(empty.compressedRatio, 0.0)
        XCTAssertEqual(empty.swapUsedRatio, 0.0)
    }

    func testSwapCalculations() {
        let info = CPUMemoryInfo(
            totalPhysicalBytes: 16 * 1024 * 1024 * 1024,
            usedBytes: 12 * 1024 * 1024 * 1024,
            freeBytes: 4 * 1024 * 1024 * 1024,
            activeBytes: 6 * 1024 * 1024 * 1024,
            inactiveBytes: 6 * 1024 * 1024 * 1024,
            wiredBytes: 3 * 1024 * 1024 * 1024,
            compressedBytes: 3 * 1024 * 1024 * 1024,
            appMemoryBytes: 6 * 1024 * 1024 * 1024,
            cachedBytes: 6 * 1024 * 1024 * 1024,
            swapTotalBytes: 4 * 1024 * 1024 * 1024,
            swapUsedBytes: 1 * 1024 * 1024 * 1024,
            swapFreeBytes: 3 * 1024 * 1024 * 1024
        )

        XCTAssertEqual(info.swapUsedRatio, 0.25, accuracy: 0.001)
        XCTAssertEqual(info.formattedSwapUsed, "1.0 GB")
        XCTAssertEqual(info.formattedSwapTotal, "4.0 GB")
        XCTAssertEqual(info.formattedSwapFree, "3.0 GB")
    }

    func testMemoryPressureLevelScores() {
        XCTAssertEqual(MemoryPressureLevel.normal.severityScore, 0.2)
        XCTAssertEqual(MemoryPressureLevel.warning.severityScore, 0.6)
        XCTAssertEqual(MemoryPressureLevel.critical.severityScore, 1.0)
        XCTAssertEqual(MemoryPressureLevel.unknown.severityScore, 0.0)
    }
}
