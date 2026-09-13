import XCTest
@testable import MacMemKit

final class GPUMemoryReaderTests: XCTestCase {

    func testRealGPUMemoryReaderReturnsValidData() throws {
        let reader = DefaultGPUMemoryReader()
        let info = try reader.readGPUMemory()

        XCTAssertFalse(info.deviceName.isEmpty, "Device name should not be empty.")
        XCTAssertGreaterThan(info.recommendedMaxWorkingSetBytes, 0, "Recommended working set should be positive.")
        XCTAssertGreaterThanOrEqual(info.allocatedBytes, 0)
        XCTAssertGreaterThanOrEqual(info.inUseBytes, 0)
    }

    func testMockReaderReturnsExpectedData() throws {
        let expected = GPUMemoryInfo.mockDefault
        let mock = MockGPUMemoryReader(stubbedInfo: expected)

        let result = try mock.readGPUMemory()

        XCTAssertEqual(result, expected)
        XCTAssertEqual(mock.callCount, 1)
    }

    func testMockReaderThrowsError() {
        struct TestError: Error, Equatable {}
        let mock = MockGPUMemoryReader(stubbedError: TestError())

        XCTAssertThrowsError(try mock.readGPUMemory()) { error in
            XCTAssertTrue(error is TestError)
        }
        XCTAssertEqual(mock.callCount, 1)
    }
}
