import Foundation
import IOKit
import Metal

/// Protocol defining the interface for reading GPU memory and utilization metrics.
public protocol GPUMemoryReaderProtocol: Sendable {
    func readGPUMemory() throws -> GPUMemoryInfo
}

public enum GPUMemoryReaderError: LocalizedError, Sendable {
    case noGPUDeviceFound

    public var errorDescription: String? {
        switch self {
        case .noGPUDeviceFound:
            return "No Metal-compatible GPU device was found on this system."
        }
    }
}

/// Reads real GPU memory and utilization metrics using Metal and macOS IOKit registry.
public struct DefaultGPUMemoryReader: GPUMemoryReaderProtocol {

    public init() {}

    public func readGPUMemory() throws -> GPUMemoryInfo {
        // 1. Query Metal for device metadata and recommended budgets
        let metalDevice = MTLCreateSystemDefaultDevice() ?? MTLCopyAllDevices().first

        let deviceName = metalDevice?.name ?? "Apple GPU"
        let isUnifiedMemory = metalDevice?.hasUnifiedMemory ?? true
        let recommendedMaxWorkingSet = UInt64(metalDevice?.recommendedMaxWorkingSetSize ?? 0)
        let processAllocated = UInt64(metalDevice?.currentAllocatedSize ?? 0)

        // 2. Query IOKit IOAccelerator for live performance statistics
        var ioAllocatedBytes: UInt64 = 0
        var ioInUseBytes: UInt64 = 0
        var deviceUtil: Double? = nil
        var rendererUtil: Double? = nil
        var tilerUtil: Double? = nil
        var clientCount = 0
        var vramTotal: UInt64? = nil
        var vramFree: UInt64? = nil

        var iterator: io_iterator_t = 0
        let matching = IOServiceMatching("IOAccelerator")
        let result = IOServiceGetMatchingServices(kIOMainPortDefault, matching, &iterator)

        if result == KERN_SUCCESS && iterator != 0 {
            while case let entry = IOIteratorNext(iterator), entry != 0 {
                var props: Unmanaged<CFMutableDictionary>?
                if IORegistryEntryCreateCFProperties(entry, &props, kCFAllocatorDefault, 0) == KERN_SUCCESS,
                   let dict = props?.takeRetainedValue() as? [String: Any] {

                    if let perf = dict["PerformanceStatistics"] as? [String: Any] {
                        if let alloc = perf["Alloc system memory"] as? NSNumber {
                            ioAllocatedBytes = max(ioAllocatedBytes, alloc.uint64Value)
                        } else if let alloc = perf["vramUsedBytes"] as? NSNumber {
                            ioAllocatedBytes = max(ioAllocatedBytes, alloc.uint64Value)
                        }

                        if let inUse = perf["In use system memory"] as? NSNumber {
                            ioInUseBytes = max(ioInUseBytes, inUse.uint64Value)
                        }

                        if let dev = perf["Device Utilization %"] as? NSNumber {
                            deviceUtil = dev.doubleValue
                        }
                        if let rend = perf["Renderer Utilization %"] as? NSNumber {
                            rendererUtil = rend.doubleValue
                        }
                        if let tile = perf["Tiler Utilization %"] as? NSNumber {
                            tilerUtil = tile.doubleValue
                        }

                        if let free = perf["vramFreeBytes"] as? NSNumber {
                            vramFree = free.uint64Value
                        }
                    }

                    if let vramMB = dict["VRAM,totalMB"] as? NSNumber {
                        vramTotal = vramMB.uint64Value * 1024 * 1024
                    }
                }

                // Count active client connections to this accelerator
                var childIterator: io_iterator_t = 0
                if IORegistryEntryGetChildIterator(entry, kIOServicePlane, &childIterator) == KERN_SUCCESS && childIterator != 0 {
                    while case let child = IOIteratorNext(childIterator), child != 0 {
                        clientCount += 1
                        IOObjectRelease(child)
                    }
                    IOObjectRelease(childIterator)
                }

                IOObjectRelease(entry)
            }
            IOObjectRelease(iterator)
        }

        // 3. Reconcile fallback values
        let finalAllocated = ioAllocatedBytes > 0 ? ioAllocatedBytes : processAllocated
        let finalInUse = ioInUseBytes > 0 ? ioInUseBytes : min(finalAllocated, processAllocated)

        let finalWorkingSet: UInt64
        if recommendedMaxWorkingSet > 0 {
            finalWorkingSet = recommendedMaxWorkingSet
        } else {
            // Fallback: estimate 75% of physical memory for unified memory
            let physical = ProcessInfo.processInfo.physicalMemory
            finalWorkingSet = UInt64(Double(physical) * 0.75)
        }

        return GPUMemoryInfo(
            deviceName: deviceName,
            isUnifiedMemory: isUnifiedMemory,
            allocatedBytes: finalAllocated,
            inUseBytes: finalInUse,
            recommendedMaxWorkingSetBytes: finalWorkingSet,
            processAllocatedBytes: processAllocated,
            deviceUtilizationPercentage: deviceUtil,
            rendererUtilizationPercentage: rendererUtil,
            tilerUtilizationPercentage: tilerUtil,
            activeClientCount: clientCount,
            vramTotalBytes: vramTotal,
            vramFreeBytes: vramFree
        )
    }
}
