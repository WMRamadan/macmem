import Foundation

/// A point-in-time sample of CPU, GPU, and Total System Memory used for historical charting.
public struct MemorySample: Identifiable, Sendable, Equatable, Codable {
    public let id: UUID
    public let timestamp: Date
    public let cpuUsedBytes: UInt64
    public let cpuUsedRatio: Double
    public let gpuAllocatedBytes: UInt64
    public let gpuInUseBytes: UInt64
    public let gpuAllocatedRatio: Double
    public let totalSystemUsedBytes: UInt64
    public let totalSystemUsedRatio: Double
    public let gpuUtilizationPercentage: Double

    public init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        cpuUsedBytes: UInt64,
        cpuUsedRatio: Double,
        gpuAllocatedBytes: UInt64,
        gpuInUseBytes: UInt64,
        gpuAllocatedRatio: Double,
        totalSystemUsedBytes: UInt64? = nil,
        totalSystemUsedRatio: Double? = nil,
        gpuUtilizationPercentage: Double
    ) {
        self.id = id
        self.timestamp = timestamp
        self.cpuUsedBytes = cpuUsedBytes
        self.cpuUsedRatio = cpuUsedRatio
        self.gpuAllocatedBytes = gpuAllocatedBytes
        self.gpuInUseBytes = gpuInUseBytes
        self.gpuAllocatedRatio = gpuAllocatedRatio
        self.totalSystemUsedBytes = totalSystemUsedBytes ?? (cpuUsedBytes + gpuAllocatedBytes)
        self.totalSystemUsedRatio = totalSystemUsedRatio ?? (cpuUsedRatio + gpuAllocatedRatio)
        self.gpuUtilizationPercentage = gpuUtilizationPercentage
    }

    /// CPU used memory in Gigabytes (CPU-only share).
    public var cpuUsedGB: Double {
        ByteFormatter.toGigabytes(cpuUsedBytes)
    }

    /// GPU allocated memory in Gigabytes (GPU-only share).
    public var gpuAllocatedGB: Double {
        ByteFormatter.toGigabytes(gpuAllocatedBytes)
    }

    /// GPU in-use memory in Gigabytes.
    public var gpuInUseGB: Double {
        ByteFormatter.toGigabytes(gpuInUseBytes)
    }

    /// Total system memory used in Gigabytes (CPU + GPU combined).
    public var totalSystemUsedGB: Double {
        ByteFormatter.toGigabytes(totalSystemUsedBytes)
    }
}

/// A complete system memory snapshot capturing CPU, GPU, and reconciled system states.
public struct SystemMemorySnapshot: Sendable, Equatable, Codable {
    public let timestamp: Date
    public let hostName: String
    public let osVersion: String
    public let overview: SystemMemoryOverview
    public let cpu: CPUMemoryInfo
    public let gpu: GPUMemoryInfo

    public init(
        timestamp: Date = Date(),
        hostName: String = Host.current().localizedName ?? "Mac",
        osVersion: String = ProcessInfo.processInfo.operatingSystemVersionString,
        overview: SystemMemoryOverview? = nil,
        cpu: CPUMemoryInfo,
        gpu: GPUMemoryInfo
    ) {
        self.timestamp = timestamp
        self.hostName = hostName
        self.osVersion = osVersion
        self.cpu = cpu
        self.gpu = gpu
        self.overview = overview ?? SystemMemoryOverview.create(
            totalPhysicalBytes: cpu.totalPhysicalBytes,
            hostVMUsedBytes: cpu.systemTotalUsedBytes,
            gpuAllocatedBytes: gpu.allocatedBytes,
            isUnifiedMemory: gpu.isUnifiedMemory
        )
    }

    /// Serializes the snapshot to a formatted JSON string.
    public func toJSONString() throws -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(self)
        guard let string = String(data: data, encoding: .utf8) else {
            throw NSError(domain: "SystemMemorySnapshot", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to decode JSON data into UTF-8 string"])
        }
        return string
    }
}
