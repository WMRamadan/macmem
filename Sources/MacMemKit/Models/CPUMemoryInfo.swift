import Foundation

/// Represents macOS system memory pressure level.
public enum MemoryPressureLevel: String, Sendable, Codable, CaseIterable {
    case normal = "Normal"
    case warning = "Warning"
    case critical = "Critical"
    case unknown = "Unknown"

    public var description: String { rawValue }

    /// Normalized severity score between 0.0 (normal) and 1.0 (critical).
    public var severityScore: Double {
        switch self {
        case .normal: return 0.2
        case .warning: return 0.6
        case .critical: return 1.0
        case .unknown: return 0.0
        }
    }
}

/// Comprehensive metrics describing CPU / Host RAM state.
public struct CPUMemoryInfo: Sendable, Equatable, Codable {

    /// Total physical RAM installed on the machine (bytes).
    public let totalPhysicalBytes: UInt64

    /// Memory used ONLY by the CPU and host user space processes (bytes).
    /// On unified memory, GPU allocations are excluded so CPU and GPU do not overlap.
    public let usedBytes: UInt64

    /// Total system RAM used (App + Wired + Compressed) before splitting CPU vs GPU (bytes).
    public let systemTotalUsedBytes: UInt64

    /// Unallocated free memory (bytes).
    public let freeBytes: UInt64

    /// Memory currently in use by applications or recently allocated (bytes).
    public let activeBytes: UInt64

    /// Memory not recently used that can be reclaimed by macOS (bytes).
    public let inactiveBytes: UInt64

    /// Memory locked by the kernel and essential drivers; cannot be paged out (bytes).
    public let wiredBytes: UInt64

    /// Memory compressed in RAM by macOS memory compressor (bytes).
    public let compressedBytes: UInt64

    /// Memory dedicated to running user space applications (bytes):
    /// `(internal_page_count - purgeable_count) * pageSize`
    public let appMemoryBytes: UInt64

    /// Memory holding cached files for fast retrieval:
    /// `(inactive_count + purgeable_count) * pageSize`
    public let cachedBytes: UInt64

    /// Total swap space configured (bytes).
    public let swapTotalBytes: UInt64

    /// Swap space currently in use (bytes).
    public let swapUsedBytes: UInt64

    /// Available swap space (bytes).
    public let swapFreeBytes: UInt64

    /// System VM memory pressure indicator.
    public let pressureLevel: MemoryPressureLevel

    /// Cumulative system page-in operations.
    public let pageIns: UInt64

    /// Cumulative system page-out operations.
    public let pageOuts: UInt64

    public init(
        totalPhysicalBytes: UInt64,
        usedBytes: UInt64,
        systemTotalUsedBytes: UInt64? = nil,
        freeBytes: UInt64,
        activeBytes: UInt64,
        inactiveBytes: UInt64,
        wiredBytes: UInt64,
        compressedBytes: UInt64,
        appMemoryBytes: UInt64,
        cachedBytes: UInt64,
        swapTotalBytes: UInt64 = 0,
        swapUsedBytes: UInt64 = 0,
        swapFreeBytes: UInt64 = 0,
        pressureLevel: MemoryPressureLevel = .normal,
        pageIns: UInt64 = 0,
        pageOuts: UInt64 = 0
    ) {
        self.totalPhysicalBytes = totalPhysicalBytes
        self.usedBytes = usedBytes
        self.systemTotalUsedBytes = systemTotalUsedBytes ?? usedBytes
        self.freeBytes = freeBytes
        self.activeBytes = activeBytes
        self.inactiveBytes = inactiveBytes
        self.wiredBytes = wiredBytes
        self.compressedBytes = compressedBytes
        self.appMemoryBytes = appMemoryBytes
        self.cachedBytes = cachedBytes
        self.swapTotalBytes = swapTotalBytes
        self.swapUsedBytes = swapUsedBytes
        self.swapFreeBytes = swapFreeBytes
        self.pressureLevel = pressureLevel
        self.pageIns = pageIns
        self.pageOuts = pageOuts
    }

    /// Reconciles CPU memory usage against GPU memory on unified memory systems.
    /// Deducts GPU allocations from host used RAM so that CPU used memory represents
    /// strictly memory used only by the CPU.
    public func reconciling(gpuAllocatedBytes: UInt64, isUnifiedMemory: Bool) -> CPUMemoryInfo {
        guard isUnifiedMemory else {
            return self
        }

        let totalHostUsed = self.systemTotalUsedBytes
        let safeGPU = min(totalHostUsed, gpuAllocatedBytes)
        let cpuOnlyUsed = totalHostUsed >= safeGPU ? (totalHostUsed - safeGPU) : 0

        return CPUMemoryInfo(
            totalPhysicalBytes: self.totalPhysicalBytes,
            usedBytes: cpuOnlyUsed,
            systemTotalUsedBytes: totalHostUsed,
            freeBytes: self.freeBytes,
            activeBytes: self.activeBytes,
            inactiveBytes: self.inactiveBytes,
            wiredBytes: self.wiredBytes,
            compressedBytes: self.compressedBytes,
            appMemoryBytes: self.appMemoryBytes,
            cachedBytes: self.cachedBytes,
            swapTotalBytes: self.swapTotalBytes,
            swapUsedBytes: self.swapUsedBytes,
            swapFreeBytes: self.swapFreeBytes,
            pressureLevel: self.pressureLevel,
            pageIns: self.pageIns,
            pageOuts: self.pageOuts
        )
    }

    // MARK: - Computed Ratios & Percentages

    /// Percentage of total physical RAM currently used by CPU exclusively (0.0 ... 1.0).
    public var usedRatio: Double {
        guard totalPhysicalBytes > 0 else { return 0.0 }
        return min(1.0, max(0.0, Double(usedBytes) / Double(totalPhysicalBytes)))
    }

    /// Percentage of total physical RAM currently used by the entire system before partition (0.0 ... 1.0).
    public var systemTotalUsedRatio: Double {
        guard totalPhysicalBytes > 0 else { return 0.0 }
        return min(1.0, max(0.0, Double(systemTotalUsedBytes) / Double(totalPhysicalBytes)))
    }

    /// Percentage of total physical RAM currently free (0.0 ... 1.0).
    public var freeRatio: Double {
        guard totalPhysicalBytes > 0 else { return 0.0 }
        return min(1.0, max(0.0, Double(freeBytes) / Double(totalPhysicalBytes)))
    }

    /// Percentage of physical RAM occupied by app memory.
    public var appMemoryRatio: Double {
        guard totalPhysicalBytes > 0 else { return 0.0 }
        return min(1.0, max(0.0, Double(appMemoryBytes) / Double(totalPhysicalBytes)))
    }

    /// Percentage of physical RAM occupied by wired memory.
    public var wiredRatio: Double {
        guard totalPhysicalBytes > 0 else { return 0.0 }
        return min(1.0, max(0.0, Double(wiredBytes) / Double(totalPhysicalBytes)))
    }

    /// Percentage of physical RAM occupied by compressed memory.
    public var compressedRatio: Double {
        guard totalPhysicalBytes > 0 else { return 0.0 }
        return min(1.0, max(0.0, Double(compressedBytes) / Double(totalPhysicalBytes)))
    }

    /// Percentage of swap used (0.0 ... 1.0).
    public var swapUsedRatio: Double {
        guard swapTotalBytes > 0 else { return 0.0 }
        return min(1.0, max(0.0, Double(swapUsedBytes) / Double(swapTotalBytes)))
    }

    // MARK: - Formatting Helpers

    public var formattedTotal: String { ByteFormatter.format(totalPhysicalBytes) }
    public var formattedUsed: String { ByteFormatter.format(usedBytes) }
    public var formattedSystemTotalUsed: String { ByteFormatter.format(systemTotalUsedBytes) }
    public var formattedFree: String { ByteFormatter.format(freeBytes) }
    public var formattedAppMemory: String { ByteFormatter.format(appMemoryBytes) }
    public var formattedWired: String { ByteFormatter.format(wiredBytes) }
    public var formattedCompressed: String { ByteFormatter.format(compressedBytes) }
    public var formattedCached: String { ByteFormatter.format(cachedBytes) }
    public var formattedSwapUsed: String { ByteFormatter.format(swapUsedBytes) }
    public var formattedSwapTotal: String { ByteFormatter.format(swapTotalBytes) }
    public var formattedSwapFree: String { ByteFormatter.format(swapFreeBytes) }
    public var formattedUsedPercentage: String { ByteFormatter.formatPercentage(usedRatio) }
    public var formattedSystemTotalUsedPercentage: String { ByteFormatter.formatPercentage(systemTotalUsedRatio) }

    /// A fallback empty representation.
    public static let empty = CPUMemoryInfo(
        totalPhysicalBytes: 0,
        usedBytes: 0,
        systemTotalUsedBytes: 0,
        freeBytes: 0,
        activeBytes: 0,
        inactiveBytes: 0,
        wiredBytes: 0,
        compressedBytes: 0,
        appMemoryBytes: 0,
        cachedBytes: 0
    )
}
