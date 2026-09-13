import Foundation

/// Reconciled system memory overview that partitions physical memory between CPU, GPU, and Free RAM.
/// Guarantees that:
/// `cpuUsedBytes + gpuUsedBytes == totalUsedBytes`
/// and `cpuRatio + gpuRatio == totalUsedRatio`.
public struct SystemMemoryOverview: Sendable, Equatable, Codable {

    /// Total physical RAM installed (bytes).
    public let totalPhysicalBytes: UInt64

    /// Total system memory in use (bytes) = cpuUsedBytes + gpuUsedBytes.
    public let totalUsedBytes: UInt64

    /// Memory used ONLY by CPU tasks and host applications (bytes).
    public let cpuUsedBytes: UInt64

    /// Memory used ONLY by GPU graphics, compute, and Metal buffers (bytes).
    public let gpuUsedBytes: UInt64

    /// Memory currently unallocated and free (bytes).
    public let freeBytes: UInt64

    public init(
        totalPhysicalBytes: UInt64,
        totalUsedBytes: UInt64,
        cpuUsedBytes: UInt64,
        gpuUsedBytes: UInt64,
        freeBytes: UInt64
    ) {
        self.totalPhysicalBytes = totalPhysicalBytes
        self.totalUsedBytes = totalUsedBytes
        self.cpuUsedBytes = cpuUsedBytes
        self.gpuUsedBytes = gpuUsedBytes
        self.freeBytes = freeBytes
    }

    /// Factory method that cleanly partitions host system memory and GPU memory without double counting.
    public static func create(
        totalPhysicalBytes: UInt64,
        hostVMUsedBytes: UInt64,
        gpuAllocatedBytes: UInt64,
        isUnifiedMemory: Bool
    ) -> SystemMemoryOverview {
        guard totalPhysicalBytes > 0 else {
            return .empty
        }

        if isUnifiedMemory {
            // On unified memory, GPU allocations originate from physical system RAM.
            // Cap GPU used at total physical RAM and host VM used.
            let safeTotalUsed = min(totalPhysicalBytes, hostVMUsedBytes)
            let safeGPUUsed = min(safeTotalUsed, gpuAllocatedBytes)
            let safeCPUUsed = safeTotalUsed >= safeGPUUsed ? (safeTotalUsed - safeGPUUsed) : 0
            let safeFree = totalPhysicalBytes >= safeTotalUsed ? (totalPhysicalBytes - safeTotalUsed) : 0

            return SystemMemoryOverview(
                totalPhysicalBytes: totalPhysicalBytes,
                totalUsedBytes: safeTotalUsed,
                cpuUsedBytes: safeCPUUsed,
                gpuUsedBytes: safeGPUUsed,
                freeBytes: safeFree
            )
        } else {
            // On discrete GPU systems, CPU uses system RAM and GPU has independent VRAM.
            let safeCPUUsed = min(totalPhysicalBytes, hostVMUsedBytes)
            let safeFree = totalPhysicalBytes >= safeCPUUsed ? (totalPhysicalBytes - safeCPUUsed) : 0

            return SystemMemoryOverview(
                totalPhysicalBytes: totalPhysicalBytes,
                totalUsedBytes: safeCPUUsed,
                cpuUsedBytes: safeCPUUsed,
                gpuUsedBytes: gpuAllocatedBytes,
                freeBytes: safeFree
            )
        }
    }

    // MARK: - Ratios (relative to Total Physical RAM)

    /// Percentage of physical RAM used exclusively by CPU (0.0 ... 1.0).
    public var cpuRatio: Double {
        guard totalPhysicalBytes > 0 else { return 0.0 }
        return min(1.0, max(0.0, Double(cpuUsedBytes) / Double(totalPhysicalBytes)))
    }

    /// Percentage of physical RAM used exclusively by GPU (0.0 ... 1.0).
    public var gpuRatio: Double {
        guard totalPhysicalBytes > 0 else { return 0.0 }
        return min(1.0, max(0.0, Double(gpuUsedBytes) / Double(totalPhysicalBytes)))
    }

    /// Total percentage of physical RAM in use (0.0 ... 1.0). Equal to cpuRatio + gpuRatio.
    public var totalUsedRatio: Double {
        guard totalPhysicalBytes > 0 else { return 0.0 }
        return min(1.0, max(0.0, Double(totalUsedBytes) / Double(totalPhysicalBytes)))
    }

    /// Percentage of physical RAM that is free (0.0 ... 1.0).
    public var freeRatio: Double {
        guard totalPhysicalBytes > 0 else { return 0.0 }
        return min(1.0, max(0.0, Double(freeBytes) / Double(totalPhysicalBytes)))
    }

    // MARK: - Formatting Helpers

    public var formattedTotal: String { ByteFormatter.format(totalPhysicalBytes) }
    public var formattedTotalUsed: String { ByteFormatter.format(totalUsedBytes) }
    public var formattedCPUUsed: String { ByteFormatter.format(cpuUsedBytes) }
    public var formattedGPUUsed: String { ByteFormatter.format(gpuUsedBytes) }
    public var formattedFree: String { ByteFormatter.format(freeBytes) }

    public var formattedTotalUsedPercentage: String { ByteFormatter.formatPercentage(totalUsedRatio) }
    public var formattedCPUPercentage: String { ByteFormatter.formatPercentage(cpuRatio) }
    public var formattedGPUPercentage: String { ByteFormatter.formatPercentage(gpuRatio) }
    public var formattedFreePercentage: String { ByteFormatter.formatPercentage(freeRatio) }

    public static let empty = SystemMemoryOverview(
        totalPhysicalBytes: 0,
        totalUsedBytes: 0,
        cpuUsedBytes: 0,
        gpuUsedBytes: 0,
        freeBytes: 0
    )
}
