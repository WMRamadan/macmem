import Foundation

/// Mock implementation of CPUMemoryReaderProtocol for testing and SwiftUI previews.
public final class MockCPUMemoryReader: CPUMemoryReaderProtocol, @unchecked Sendable {
    public var stubbedResult: Result<CPUMemoryInfo, Error>
    public private(set) var callCount: Int = 0

    public init(stubbedInfo: CPUMemoryInfo = .mockDefault) {
        self.stubbedResult = .success(stubbedInfo)
    }

    public init(stubbedError: Error) {
        self.stubbedResult = .failure(stubbedError)
    }

    public func readCPUMemory() throws -> CPUMemoryInfo {
        callCount += 1
        switch stubbedResult {
        case .success(let info):
            return info
        case .failure(let error):
            throw error
        }
    }
}

/// Mock implementation of GPUMemoryReaderProtocol for testing and SwiftUI previews.
public final class MockGPUMemoryReader: GPUMemoryReaderProtocol, @unchecked Sendable {
    public var stubbedResult: Result<GPUMemoryInfo, Error>
    public private(set) var callCount: Int = 0

    public init(stubbedInfo: GPUMemoryInfo = .mockDefault) {
        self.stubbedResult = .success(stubbedInfo)
    }

    public init(stubbedError: Error) {
        self.stubbedResult = .failure(stubbedError)
    }

    public func readGPUMemory() throws -> GPUMemoryInfo {
        callCount += 1
        switch stubbedResult {
        case .success(let info):
            return info
        case .failure(let error):
            throw error
        }
    }
}

// MARK: - Mock Sample Data

public extension CPUMemoryInfo {
    static let mockDefault = CPUMemoryInfo(
        totalPhysicalBytes: 16 * 1024 * 1024 * 1024,      // 16 GB
        usedBytes: 11 * 1024 * 1024 * 1024,               // 11 GB
        freeBytes: 5 * 1024 * 1024 * 1024,                // 5 GB
        activeBytes: 6 * 1024 * 1024 * 1024,
        inactiveBytes: 3 * 1024 * 1024 * 1024,
        wiredBytes: 2 * 1024 * 1024 * 1024,               // 2 GB
        compressedBytes: 1 * 1024 * 1024 * 1024,          // 1 GB
        appMemoryBytes: 8 * 1024 * 1024 * 1024,           // 8 GB
        cachedBytes: 2 * 1024 * 1024 * 1024,
        swapTotalBytes: 4 * 1024 * 1024 * 1024,
        swapUsedBytes: 512 * 1024 * 1024,
        swapFreeBytes: UInt64(3.5 * 1024 * 1024 * 1024),
        pressureLevel: .normal,
        pageIns: 120_000,
        pageOuts: 4_500
    )

    static let mockHighPressure = CPUMemoryInfo(
        totalPhysicalBytes: 16 * 1024 * 1024 * 1024,
        usedBytes: UInt64(15.2 * 1024 * 1024 * 1024),
        freeBytes: UInt64(0.8 * 1024 * 1024 * 1024),
        activeBytes: 9 * 1024 * 1024 * 1024,
        inactiveBytes: 1 * 1024 * 1024 * 1024,
        wiredBytes: 4 * 1024 * 1024 * 1024,
        compressedBytes: 4 * 1024 * 1024 * 1024,
        appMemoryBytes: 7 * 1024 * 1024 * 1024,
        cachedBytes: 1 * 1024 * 1024 * 1024,
        swapTotalBytes: 8 * 1024 * 1024 * 1024,
        swapUsedBytes: 6 * 1024 * 1024 * 1024,
        swapFreeBytes: 2 * 1024 * 1024 * 1024,
        pressureLevel: .critical,
        pageIns: 980_000,
        pageOuts: 450_000
    )
}

public extension GPUMemoryInfo {
    static let mockDefault = GPUMemoryInfo(
        deviceName: "Apple M3 Pro",
        isUnifiedMemory: true,
        allocatedBytes: UInt64(3.8 * 1024 * 1024 * 1024),     // 3.8 GB
        inUseBytes: UInt64(850 * 1024 * 1024),                // 850 MB
        recommendedMaxWorkingSetBytes: 12 * 1024 * 1024 * 1024, // 12 GB
        processAllocatedBytes: 64 * 1024 * 1024,
        deviceUtilizationPercentage: 24.5,
        rendererUtilizationPercentage: 22.0,
        tilerUtilizationPercentage: 18.2,
        activeClientCount: 38,
        vramTotalBytes: nil,
        vramFreeBytes: nil
    )

    static let mockDiscrete = GPUMemoryInfo(
        deviceName: "AMD Radeon Pro 5500M",
        isUnifiedMemory: false,
        allocatedBytes: UInt64(3.2 * 1024 * 1024 * 1024),
        inUseBytes: UInt64(1.5 * 1024 * 1024 * 1024),
        recommendedMaxWorkingSetBytes: 4 * 1024 * 1024 * 1024,
        processAllocatedBytes: 32 * 1024 * 1024,
        deviceUtilizationPercentage: 65.0,
        rendererUtilizationPercentage: 60.0,
        tilerUtilizationPercentage: nil,
        activeClientCount: 14,
        vramTotalBytes: 4 * 1024 * 1024 * 1024,
        vramFreeBytes: UInt64(0.8 * 1024 * 1024 * 1024)
    )
}
