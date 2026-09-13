import Darwin
import Foundation

/// Protocol defining the interface for reading CPU / system RAM metrics.
public protocol CPUMemoryReaderProtocol: Sendable {
    func readCPUMemory() throws -> CPUMemoryInfo
}

public enum CPUMemoryReaderError: LocalizedError, Sendable {
    case hostStatisticsFailed(kern_return_t)
    case pageSizeQueryFailed

    public var errorDescription: String? {
        switch self {
        case .hostStatisticsFailed(let code):
            return "Failed to query Mach host statistics (kernel error code: \(code))."
        case .pageSizeQueryFailed:
            return "Failed to determine system VM page size."
        }
    }
}

/// Reads real macOS host memory metrics via Mach kernel and sysctl interfaces.
public struct DefaultCPUMemoryReader: CPUMemoryReaderProtocol {

    public init() {}

    public func readCPUMemory() throws -> CPUMemoryInfo {
        var pageSize: vm_size_t = 0
        let pageResult = host_page_size(mach_host_self(), &pageSize)
        guard pageResult == KERN_SUCCESS, pageSize > 0 else {
            throw CPUMemoryReaderError.pageSizeQueryFailed
        }

        var count = mach_msg_type_number_t(MemoryLayout<vm_statistics64_data_t>.size / MemoryLayout<integer_t>.size)
        var vmStats = vm_statistics64_data_t()

        let kerr = withUnsafeMutablePointer(to: &vmStats) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics64(mach_host_self(), HOST_VM_INFO64, $0, &count)
            }
        }

        guard kerr == KERN_SUCCESS else {
            throw CPUMemoryReaderError.hostStatisticsFailed(kerr)
        }

        let ps = UInt64(pageSize)
        let totalPhysical = ProcessInfo.processInfo.physicalMemory

        let freeBytes = UInt64(vmStats.free_count) * ps
        let activeBytes = UInt64(vmStats.active_count) * ps
        let inactiveBytes = UInt64(vmStats.inactive_count) * ps
        let wiredBytes = UInt64(vmStats.wire_count) * ps
        let compressedBytes = UInt64(vmStats.compressor_page_count) * ps

        // App memory: internal pages minus purgeable pages
        let internalPages = UInt64(vmStats.internal_page_count)
        let purgeablePages = UInt64(vmStats.purgeable_count)
        let appMemoryPages = internalPages >= purgeablePages ? (internalPages - purgeablePages) : internalPages
        let appMemoryBytes = appMemoryPages * ps

        // Cached files: inactive pages plus purgeable pages
        let cachedBytes = (inactiveBytes) + (purgeablePages * ps)

        // Activity Monitor standard formula for Used Memory:
        // Used = App Memory + Wired Memory + Compressed Memory
        let usedBytes = min(totalPhysical, appMemoryBytes + wiredBytes + compressedBytes)

        // Read Swap statistics via sysctl
        var swapUsage = xsw_usage()
        var swapSize = MemoryLayout<xsw_usage>.size
        var swapTotal: UInt64 = 0
        var swapUsed: UInt64 = 0
        var swapFree: UInt64 = 0

        if sysctlbyname("vm.swapusage", &swapUsage, &swapSize, nil, 0) == 0 {
            swapTotal = UInt64(swapUsage.xsu_total)
            swapUsed = UInt64(swapUsage.xsu_used)
            swapFree = UInt64(swapUsage.xsu_avail)
        }

        // Read Memory Pressure Level via sysctl
        var pressureVal: Int32 = 0
        var pressureSize = MemoryLayout<Int32>.size
        var pressureLevel: MemoryPressureLevel = .normal

        if sysctlbyname("kern.memorystatus_vm_pressure_level", &pressureVal, &pressureSize, nil, 0) == 0 {
            switch pressureVal {
            case 1:
                pressureLevel = .normal
            case 2:
                pressureLevel = .warning
            case 4:
                pressureLevel = .critical
            default:
                pressureLevel = .normal
            }
        }

        return CPUMemoryInfo(
            totalPhysicalBytes: totalPhysical,
            usedBytes: usedBytes,
            freeBytes: freeBytes,
            activeBytes: activeBytes,
            inactiveBytes: inactiveBytes,
            wiredBytes: wiredBytes,
            compressedBytes: compressedBytes,
            appMemoryBytes: appMemoryBytes,
            cachedBytes: cachedBytes,
            swapTotalBytes: swapTotal,
            swapUsedBytes: swapUsed,
            swapFreeBytes: swapFree,
            pressureLevel: pressureLevel,
            pageIns: UInt64(vmStats.pageins),
            pageOuts: UInt64(vmStats.pageouts)
        )
    }
}
