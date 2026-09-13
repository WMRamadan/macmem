import XCTest
@testable import MacMemKit

final class CPUMemoryReaderTests: XCTestCase {

    func testRealHostMemoryReaderReturnsValidData() throws {
        let reader = DefaultCPUMemoryReader()
        let info = try reader.readCPUMemory()

        XCTAssertGreaterThan(info.totalPhysicalBytes, 0, "Host must report positive physical RAM.")
        XCTAssertGreaterThan(info.usedBytes, 0, "Host must report positive used RAM.")
        XCTAssertLessThanOrEqual(info.usedBytes, info.totalPhysicalBytes, "Used RAM cannot exceed physical RAM.")
        XCTAssertGreaterThanOrEqual(info.appMemoryBytes, 0)
        XCTAssertGreaterThanOrEqual(info.wiredBytes, 0)
        XCTAssertGreaterThanOrEqual(info.compressedBytes, 0)
        XCTAssertTrue([.normal, .warning, .critical, .unknown].contains(info.pressureLevel))
    }

    func testMockReaderReturnsExpectedData() throws {
        let expected = CPUMemoryInfo.mockDefault
        let mock = MockCPUMemoryReader(stubbedInfo: expected)

        let result = try mock.readCPUMemory()

        XCTAssertEqual(result, expected)
        XCTAssertEqual(mock.callCount, 1)
    }

    func testMockReaderThrowsError() {
        struct TestError: Error, Equatable {}
        let mock = MockCPUMemoryReader(stubbedError: TestError())

        XCTAssertThrowsError(try mock.readCPUMemory()) { error in
            XCTAssertTrue(error is TestError)
        }
        XCTAssertEqual(mock.callCount, 1)
    }
}
