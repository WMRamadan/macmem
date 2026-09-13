import Foundation
import Observation

/// Internal container to safely hold and cancel the polling Task across concurrency boundaries.
private final class TaskHolder: @unchecked Sendable {
    var task: Task<Void, Never>?

    func cancel() {
        task?.cancel()
        task = nil
    }
}

/// The primary monitoring engine that schedules polling and manages state and history.
@Observable
@MainActor
public final class MemoryMonitorService {

    public var systemOverview: SystemMemoryOverview
    public var cpuInfo: CPUMemoryInfo
    public var gpuInfo: GPUMemoryInfo
    public var history: [MemorySample]
    public var isPaused: Bool
    public var refreshInterval: TimeInterval {
        didSet {
            if !isPaused {
                restartTimer()
            }
        }
    }
    public var maxHistoryCount: Int
    public var lastUpdated: Date?
    public var lastErrorMessage: String?

    private let cpuReader: any CPUMemoryReaderProtocol
    private let gpuReader: any GPUMemoryReaderProtocol
    private let timerHolder = TaskHolder()

    public init(
        cpuReader: any CPUMemoryReaderProtocol = DefaultCPUMemoryReader(),
        gpuReader: any GPUMemoryReaderProtocol = DefaultGPUMemoryReader(),
        initialRefreshInterval: TimeInterval = 1.0,
        maxHistoryCount: Int = 60
    ) {
        self.cpuReader = cpuReader
        self.gpuReader = gpuReader
        self.refreshInterval = initialRefreshInterval
        self.maxHistoryCount = maxHistoryCount
        self.isPaused = false
        self.systemOverview = .empty
        self.cpuInfo = .empty
        self.gpuInfo = .empty
        self.history = []

        // Initial measurement
        refresh()
    }

    deinit {
        timerHolder.cancel()
    }

    /// Begins scheduled polling at the configured refresh interval.
    public func startMonitoring() {
        isPaused = false
        restartTimer()
    }

    /// Stops polling and cancels any active background tasks.
    public func stopMonitoring() {
        timerHolder.cancel()
    }

    /// Toggles pause state.
    public func togglePause() {
        isPaused.toggle()
        if isPaused {
            stopMonitoring()
        } else {
            startMonitoring()
        }
    }

    /// Performs an immediate poll of both CPU and GPU memory, reconciling the values
    /// so CPU used memory represents only CPU usage, GPU memory represents only GPU usage,
    /// and total used memory is their exact sum.
    public func refresh() {
        var cpuErr: Error?
        var gpuErr: Error?
        var fetchedCPU = self.cpuInfo
        var fetchedGPU = self.gpuInfo

        do {
            fetchedCPU = try cpuReader.readCPUMemory()
        } catch {
            cpuErr = error
        }

        do {
            fetchedGPU = try gpuReader.readGPUMemory()
        } catch {
            gpuErr = error
        }

        if let err = cpuErr ?? gpuErr {
            self.lastErrorMessage = err.localizedDescription
        } else {
            self.lastErrorMessage = nil
        }

        // Reconcile and partition memory
        let overview = SystemMemoryOverview.create(
            totalPhysicalBytes: fetchedCPU.totalPhysicalBytes,
            hostVMUsedBytes: fetchedCPU.systemTotalUsedBytes,
            gpuAllocatedBytes: fetchedGPU.allocatedBytes,
            isUnifiedMemory: fetchedGPU.isUnifiedMemory
        )

        self.systemOverview = overview
        self.cpuInfo = fetchedCPU.reconciling(
            gpuAllocatedBytes: fetchedGPU.allocatedBytes,
            isUnifiedMemory: fetchedGPU.isUnifiedMemory
        )
        self.gpuInfo = fetchedGPU

        let now = Date()
        self.lastUpdated = now

        // Append to history buffer
        let sample = MemorySample(
            timestamp: now,
            cpuUsedBytes: overview.cpuUsedBytes,
            cpuUsedRatio: overview.cpuRatio,
            gpuAllocatedBytes: overview.gpuUsedBytes,
            gpuInUseBytes: fetchedGPU.inUseBytes,
            gpuAllocatedRatio: overview.gpuRatio,
            totalSystemUsedBytes: overview.totalUsedBytes,
            totalSystemUsedRatio: overview.totalUsedRatio,
            gpuUtilizationPercentage: fetchedGPU.deviceUtilizationPercentage ?? 0.0
        )

        history.append(sample)
        if history.count > maxHistoryCount {
            history.removeFirst(history.count - maxHistoryCount)
        }
    }

    /// Resets all accumulated historical trend samples.
    public func clearHistory() {
        history.removeAll()
    }

    /// Creates a complete snapshot of current system memory.
    public func takeSnapshot() -> SystemMemorySnapshot {
        SystemMemorySnapshot(overview: systemOverview, cpu: cpuInfo, gpu: gpuInfo)
    }

    /// Serializes the current snapshot to formatted JSON string.
    public func exportJSON() throws -> String {
        try takeSnapshot().toJSONString()
    }

    // MARK: - Private Helpers

    private func restartTimer() {
        timerHolder.cancel()
        let intervalNanos = UInt64(max(0.2, refreshInterval) * 1_000_000_000)

        timerHolder.task = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: intervalNanos)
                if Task.isCancelled { break }
                guard let self else { break }
                self.refresh()
            }
        }
    }
}
