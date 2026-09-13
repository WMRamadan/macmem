import Foundation

/// Comprehensive metrics describing GPU memory and hardware state.
public struct GPUMemoryInfo: Sendable, Equatable, Codable {

    /// Name or model of the primary graphics processor (e.g., "Apple M1", "Apple M3 Max").
    public let deviceName: String

    /// Whether the GPU shares physical RAM with the CPU (Unified Memory Architecture)
    /// as in Apple Silicon, or possesses discrete VRAM.
    public let isUnifiedMemory: Bool

    /// Total memory currently allocated and used ONLY by the GPU (bytes).
    /// Reported by macOS IOKit `PerformanceStatistics["Alloc system memory"]`.
    public let allocatedBytes: UInt64

    /// GPU memory actively in use by rendering, compute, or display pipelines (bytes).
    /// Reported by macOS IOKit `PerformanceStatistics["In use system memory"]`.
    public let inUseBytes: UInt64

    /// Recommended maximum working set size advised by Metal (bytes).
    /// Exceeding this budget causes driver swapping or system memory pressure.
    public let recommendedMaxWorkingSetBytes: UInt64

    /// GPU memory allocated by the current application process (bytes).
    /// Reported by Metal `MTLDevice.currentAllocatedSize`.
    public let processAllocatedBytes: UInt64

    /// Current GPU device utilization percentage (0.0 to 100.0), if reported by IOKit.
    public let deviceUtilizationPercentage: Double?

    /// Current GPU 3D renderer pipeline utilization percentage (0.0 to 100.0).
    public let rendererUtilizationPercentage: Double?

    /// Current GPU 2D/tile accelerator utilization percentage (0.0 to 100.0).
    public let tilerUtilizationPercentage: Double?

    /// Total count of active application user clients attached to the GPU driver.
    public let activeClientCount: Int

    /// Total VRAM for discrete GPUs, in bytes (nil on unified memory systems).
    public let vramTotalBytes: UInt64?

    /// Free VRAM for discrete GPUs, in bytes (nil on unified memory systems).
    public let vramFreeBytes: UInt64?

    public init(
        deviceName: String,
        isUnifiedMemory: Bool,
        allocatedBytes: UInt64,
        inUseBytes: UInt64,
        recommendedMaxWorkingSetBytes: UInt64,
        processAllocatedBytes: UInt64 = 0,
        deviceUtilizationPercentage: Double? = nil,
        rendererUtilizationPercentage: Double? = nil,
        tilerUtilizationPercentage: Double? = nil,
        activeClientCount: Int = 0,
        vramTotalBytes: UInt64? = nil,
        vramFreeBytes: UInt64? = nil
    ) {
        self.deviceName = deviceName
        self.isUnifiedMemory = isUnifiedMemory
        self.allocatedBytes = allocatedBytes
        self.inUseBytes = inUseBytes
        self.recommendedMaxWorkingSetBytes = recommendedMaxWorkingSetBytes
        self.processAllocatedBytes = processAllocatedBytes
        self.deviceUtilizationPercentage = deviceUtilizationPercentage
        self.rendererUtilizationPercentage = rendererUtilizationPercentage
        self.tilerUtilizationPercentage = tilerUtilizationPercentage
        self.activeClientCount = activeClientCount
        self.vramTotalBytes = vramTotalBytes
        self.vramFreeBytes = vramFreeBytes
    }

    // MARK: - Computed Ratios & Percentages

    /// Percentage of total system physical RAM allocated to GPU (0.0 ... 1.0).
    /// This allows direct additive comparison: CPU % + GPU % = Total System Used %.
    public func systemMemoryRatio(totalPhysicalBytes: UInt64) -> Double {
        guard totalPhysicalBytes > 0 else { return 0.0 }
        return min(1.0, max(0.0, Double(allocatedBytes) / Double(totalPhysicalBytes)))
    }

    public func formattedSystemPercentage(totalPhysicalBytes: UInt64) -> String {
        ByteFormatter.formatPercentage(systemMemoryRatio(totalPhysicalBytes: totalPhysicalBytes))
    }

    /// Ratio of allocated memory against the Metal recommended working set budget (0.0 ... 1.0).
    public var workingSetBudgetRatio: Double {
        guard recommendedMaxWorkingSetBytes > 0 else { return 0.0 }
        return min(1.0, max(0.0, Double(allocatedBytes) / Double(recommendedMaxWorkingSetBytes)))
    }

    /// Alias for backwards compatibility.
    public var allocatedRatioOfWorkingSet: Double {
        workingSetBudgetRatio
    }

    /// Ratio of active in-use GPU memory to allocated GPU memory (0.0 ... 1.0).
    public var inUseRatioOfAllocated: Double {
        guard allocatedBytes > 0 else { return 0.0 }
        return min(1.0, max(0.0, Double(inUseBytes) / Double(allocatedBytes)))
    }

    /// Free GPU memory budget within recommended working set (bytes).
    public var availableBudgetBytes: UInt64 {
        if recommendedMaxWorkingSetBytes > allocatedBytes {
            return recommendedMaxWorkingSetBytes - allocatedBytes
        }
        return 0
    }

    // MARK: - Formatting Helpers

    public var formattedAllocated: String { ByteFormatter.format(allocatedBytes) }
    public var formattedInUse: String { ByteFormatter.format(inUseBytes) }
    public var formattedWorkingSet: String { ByteFormatter.format(recommendedMaxWorkingSetBytes) }
    public var formattedAvailableBudget: String { ByteFormatter.format(availableBudgetBytes) }
    public var formattedProcessAllocated: String { ByteFormatter.format(processAllocatedBytes) }

    public var formattedDeviceUtilization: String {
        guard let util = deviceUtilizationPercentage else { return "N/A" }
        return String(format: "%.1f%%", util)
    }

    public var formattedRendererUtilization: String {
        guard let util = rendererUtilizationPercentage else { return "N/A" }
        return String(format: "%.1f%%", util)
    }

    public var formattedTilerUtilization: String {
        guard let util = tilerUtilizationPercentage else { return "N/A" }
        return String(format: "%.1f%%", util)
    }

    /// Fallback empty representation.
    public static let empty = GPUMemoryInfo(
        deviceName: "Unknown GPU",
        isUnifiedMemory: true,
        allocatedBytes: 0,
        inUseBytes: 0,
        recommendedMaxWorkingSetBytes: 0
    )
}
