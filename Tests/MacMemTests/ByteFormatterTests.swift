import XCTest
@testable import MacMemKit

final class ByteFormatterTests: XCTestCase {

    func testZeroBytesFormatting() {
        XCTAssertEqual(ByteFormatter.format(0), "0 B")
    }

    func testSubKilobyteFormatting() {
        XCTAssertEqual(ByteFormatter.format(512), "512 B")
        XCTAssertEqual(ByteFormatter.format(1023), "1023 B")
    }

    func testKilobyteFormatting() {
        XCTAssertEqual(ByteFormatter.format(1024), "1.0 KB")
        XCTAssertEqual(ByteFormatter.format(2048), "2.0 KB")
        XCTAssertEqual(ByteFormatter.format(1536), "1.5 KB")
    }

    func testMegabyteFormatting() {
        let oneMB: UInt64 = 1024 * 1024
        XCTAssertEqual(ByteFormatter.format(oneMB), "1.0 MB")
        XCTAssertEqual(ByteFormatter.format(UInt64(256.5 * Double(oneMB))), "256.5 MB")
    }

    func testGigabyteFormatting() {
        let oneGB: UInt64 = 1024 * 1024 * 1024
        XCTAssertEqual(ByteFormatter.format(16 * oneGB), "16.0 GB")
        XCTAssertEqual(ByteFormatter.format(UInt64(8.25 * Double(oneGB)), fractionDigits: 2), "8.25 GB")
    }

    func testTerabyteFormatting() {
        let oneTB: UInt64 = 1024 * 1024 * 1024 * 1024
        XCTAssertEqual(ByteFormatter.format(2 * oneTB), "2.0 TB")
    }

    func testPercentageFormatting() {
        XCTAssertEqual(ByteFormatter.formatPercentage(0.0), "0.0%")
        XCTAssertEqual(ByteFormatter.formatPercentage(0.452), "45.2%")
        XCTAssertEqual(ByteFormatter.formatPercentage(1.0), "100.0%")
        XCTAssertEqual(ByteFormatter.formatPercentage(1.5), "100.0%") // clamped
        XCTAssertEqual(ByteFormatter.formatPercentage(-0.2), "0.0%") // clamped
        XCTAssertEqual(ByteFormatter.formatPercentage(0.8765, fractionDigits: 2), "87.65%")
    }

    func testToGigabytesConversion() {
        let bytes: UInt64 = 8 * 1024 * 1024 * 1024
        XCTAssertEqual(ByteFormatter.toGigabytes(bytes), 8.0, accuracy: 0.0001)
    }

    func testToMegabytesConversion() {
        let bytes: UInt64 = 512 * 1024 * 1024
        XCTAssertEqual(ByteFormatter.toMegabytes(bytes), 512.0, accuracy: 0.0001)
    }
}
