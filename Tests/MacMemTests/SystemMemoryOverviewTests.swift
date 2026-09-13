import XCTest
@testable import MacMemKit

final class SystemMemoryOverviewTests: XCTestCase {

    func testUnifiedMemoryPartitionAndPercentagesAddUp() {
        // Simulating the user scenario: 16 GB total, 14.24 GB total host used (89%), 11.0 GB GPU allocated (LLM)
        let total: UInt64 = 16 * 1024 * 1024 * 1024
        let hostUsed: UInt64 = UInt64(14.24 * Double(1024 * 1024 * 1024))
        let gpuAllocated: UInt64 = 11 * 1024 * 1024 * 1024

        let overview = SystemMemoryOverview.create(
            totalPhysicalBytes: total,
            hostVMUsedBytes: hostUsed,
            gpuAllocatedBytes: gpuAllocated,
            isUnifiedMemory: true
        )

        // Mathematical invariants
        XCTAssertEqual(overview.cpuUsedBytes + overview.gpuUsedBytes, overview.totalUsedBytes)
        XCTAssertEqual(overview.totalUsedBytes + overview.freeBytes, total)

        // Ratios must add up exactly
        XCTAssertEqual(overview.cpuRatio + overview.gpuRatio, overview.totalUsedRatio, accuracy: 0.0001)
        XCTAssertEqual(overview.totalUsedRatio + overview.freeRatio, 1.0, accuracy: 0.0001)

        // Values
        XCTAssertEqual(overview.gpuUsedBytes, gpuAllocated)
        XCTAssertEqual(overview.cpuUsedBytes, hostUsed - gpuAllocated)
        XCTAssertEqual(overview.totalUsedBytes, hostUsed)

        // Format checks
        XCTAssertEqual(overview.formattedTotal, "16.0 GB")
        XCTAssertEqual(overview.formattedGPUUsed, "11.0 GB")
        XCTAssertEqual(overview.formattedCPUUsed, "3.2 GB")
        XCTAssertEqual(overview.formattedTotalUsed, "14.2 GB")
    }

    func testGPUAllocationExceedingHostUsedIsSafelyCapped() {
        let total: UInt64 = 16 * 1024 * 1024 * 1024
        let hostUsed: UInt64 = 10 * 1024 * 1024 * 1024
        let gpuAllocated: UInt64 = 12 * 1024 * 1024 * 1024 // Driver reported slightly higher than active VM

        let overview = SystemMemoryOverview.create(
            totalPhysicalBytes: total,
            hostVMUsedBytes: hostUsed,
            gpuAllocatedBytes: gpuAllocated,
            isUnifiedMemory: true
        )

        XCTAssertEqual(overview.cpuUsedBytes + overview.gpuUsedBytes, overview.totalUsedBytes)
        XCTAssertEqual(overview.totalUsedBytes, hostUsed)
        XCTAssertEqual(overview.gpuUsedBytes, hostUsed)
        XCTAssertEqual(overview.cpuUsedBytes, 0)
    }

    func testZeroPhysicalMemorySafety() {
        let overview = SystemMemoryOverview.empty
        XCTAssertEqual(overview.cpuRatio, 0.0)
        XCTAssertEqual(overview.gpuRatio, 0.0)
        XCTAssertEqual(overview.totalUsedRatio, 0.0)
        XCTAssertEqual(overview.freeRatio, 0.0)
        XCTAssertEqual(overview.formattedTotalUsedPercentage, "0.0%")
    }
}
