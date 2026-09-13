import XCTest
@testable import MacMemKit

final class GPUMemoryInfoTests: XCTestCase {

    func testWorkingSetRatioAndAvailableBudget() {
        let info = GPUMemoryInfo(
            deviceName: "Apple M1",
            isUnifiedMemory: true,
            allocatedBytes: 4 * 1024 * 1024 * 1024,
            inUseBytes: 1 * 1024 * 1024 * 1024,
            recommendedMaxWorkingSetBytes: 8 * 1024 * 1024 * 1024,
            processAllocatedBytes: 128 * 1024 * 1024,
            deviceUtilizationPercentage: 35.5,
            rendererUtilizationPercentage: 30.0,
            tilerUtilizationPercentage: 20.0,
            activeClientCount: 22
        )

        let totalRAM: UInt64 = 16 * 1024 * 1024 * 1024

        // Check system memory ratio relative to physical RAM
        XCTAssertEqual(info.systemMemoryRatio(totalPhysicalBytes: totalRAM), 0.25, accuracy: 0.001)
        XCTAssertEqual(info.formattedSystemPercentage(totalPhysicalBytes: totalRAM), "25.0%")

        // Check working set budget ratio
        XCTAssertEqual(info.allocatedRatioOfWorkingSet, 0.5, accuracy: 0.001)
        XCTAssertEqual(info.workingSetBudgetRatio, 0.5, accuracy: 0.001)
        XCTAssertEqual(info.inUseRatioOfAllocated, 0.25, accuracy: 0.001)
        XCTAssertEqual(info.availableBudgetBytes, 4 * 1024 * 1024 * 1024)
        XCTAssertEqual(info.formattedAllocated, "4.0 GB")
        XCTAssertEqual(info.formattedInUse, "1.0 GB")
        XCTAssertEqual(info.formattedWorkingSet, "8.0 GB")
        XCTAssertEqual(info.formattedDeviceUtilization, "35.5%")
        XCTAssertEqual(info.formattedRendererUtilization, "30.0%")
        XCTAssertEqual(info.formattedTilerUtilization, "20.0%")
        XCTAssertEqual(info.activeClientCount, 22)
    }

    func testAvailableBudgetWhenAllocatedExceedsWorkingSet() {
        let info = GPUMemoryInfo(
            deviceName: "Apple M2",
            isUnifiedMemory: true,
            allocatedBytes: 10 * 1024 * 1024 * 1024,
            inUseBytes: 2 * 1024 * 1024 * 1024,
            recommendedMaxWorkingSetBytes: 8 * 1024 * 1024 * 1024
        )

        XCTAssertEqual(info.availableBudgetBytes, 0)
        XCTAssertEqual(info.allocatedRatioOfWorkingSet, 1.0)
    }

    func testEmptyFallback() {
        let empty = GPUMemoryInfo.empty
        XCTAssertEqual(empty.allocatedRatioOfWorkingSet, 0.0)
        XCTAssertEqual(empty.inUseRatioOfAllocated, 0.0)
        XCTAssertEqual(empty.availableBudgetBytes, 0)
        XCTAssertEqual(empty.formattedDeviceUtilization, "N/A")
    }
}
