import SwiftUI
import MacMemKit

/// Overview displaying simultaneous balance of CPU, GPU, and Total System memory.
public struct OverviewView: View {
    public let overview: SystemMemoryOverview
    public let cpu: CPUMemoryInfo
    public let gpu: GPUMemoryInfo

    public init(overview: SystemMemoryOverview, cpu: CPUMemoryInfo, gpu: GPUMemoryInfo) {
        self.overview = overview
        self.cpu = cpu
        self.gpu = gpu
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header Banner with Hardware Details
                hardwareBanner

                // Total System Memory Combined Card
                totalSystemMemoryCard

                // Memory Distribution Stacked Bar
                memoryDistributionSection

                // Side-by-Side CPU vs GPU Cards
                HStack(alignment: .top, spacing: 16) {
                    cpuSummaryCard
                    gpuSummaryCard
                }

                // Subsystem Comparison Matrix
                comparisonMatrixSection
            }
            .padding(20)
        }
    }

    // MARK: - Subviews

    private var hardwareBanner: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Image(systemName: "laptopcomputer")
                        .font(.title2)
                        .foregroundColor(.accentColor)
                    Text(Host.current().localizedName ?? "Mac")
                        .font(.title2)
                        .fontWeight(.bold)
                }
                Text("macOS \(ProcessInfo.processInfo.operatingSystemVersionString) • \(gpu.deviceName)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()

            HStack(spacing: 12) {
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Total Physical RAM")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text(overview.formattedTotal)
                        .font(.title3)
                        .fontWeight(.bold)
                }

                if gpu.isUnifiedMemory {
                    Label("Unified Memory", systemImage: "sparkles")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.purple.opacity(0.15))
                        .foregroundColor(.purple)
                        .cornerRadius(8)
                } else {
                    Label("Discrete VRAM", systemImage: "bolt.horizontal.fill")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.orange.opacity(0.15))
                        .foregroundColor(.orange)
                        .cornerRadius(8)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(nsColor: .controlBackgroundColor))
        )
    }

    private var totalSystemMemoryCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Label("Total System Memory", systemImage: "memorychip.fill")
                    .font(.headline)
                Spacer()
                Text("CPU + GPU = System Used")
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.accentColor.opacity(0.15))
                    .foregroundColor(.accentColor)
                    .cornerRadius(6)
            }

            HStack(spacing: 24) {
                GaugeRingView(
                    progress: overview.totalUsedRatio,
                    title: "System",
                    valueText: overview.formattedTotalUsedPercentage,
                    gradient: Gradient(colors: [.blue, .purple, .pink]),
                    lineWidth: 12,
                    size: 130
                )

                VStack(alignment: .leading, spacing: 10) {
                    Text("\(overview.formattedTotalUsed) Used of \(overview.formattedTotal) Total RAM")
                        .font(.title3)
                        .fontWeight(.bold)

                    // Partition Equation Badges
                    HStack(spacing: 8) {
                        partitionPill(
                            title: "CPU Only",
                            percentage: overview.formattedCPUPercentage,
                            bytes: overview.formattedCPUUsed,
                            color: .blue
                        )

                        Text("+")
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundColor(.secondary)

                        partitionPill(
                            title: "GPU Only",
                            percentage: overview.formattedGPUPercentage,
                            bytes: overview.formattedGPUUsed,
                            color: .indigo
                        )

                        Text("=")
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundColor(.secondary)

                        partitionPill(
                            title: "Total Used",
                            percentage: overview.formattedTotalUsedPercentage,
                            bytes: overview.formattedTotalUsed,
                            color: .purple
                        )

                        Spacer()

                        partitionPill(
                            title: "Free RAM",
                            percentage: overview.formattedFreePercentage,
                            bytes: overview.formattedFree,
                            color: .green
                        )
                    }

                    Text("Independent partition: Memory mapped to the GPU is excluded from CPU usage to ensure percentages strictly add up.")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(nsColor: .controlBackgroundColor))
        )
    }

    private func partitionPill(title: String, percentage: String, bytes: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
            HStack(spacing: 4) {
                Text(percentage)
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(color)
                Text("(\(bytes))")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(color.opacity(0.1))
        .cornerRadius(8)
    }

    private var memoryDistributionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Physical RAM Allocation Distribution")
                    .font(.headline)
                Spacer()
                Text("100% of Physical RAM")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            // Stacked Partition Bar: CPU (Blue) + GPU (Indigo) + Free (Green) = 100%
            GeometryReader { geo in
                let total = max(1.0, Double(overview.totalPhysicalBytes))
                let cpuWidth = CGFloat(Double(overview.cpuUsedBytes) / total) * geo.size.width
                let gpuWidth = CGFloat(Double(overview.gpuUsedBytes) / total) * geo.size.width
                let freeWidth = max(0, geo.size.width - (cpuWidth + gpuWidth))

                HStack(spacing: 2) {
                    Rectangle()
                        .fill(Color.blue)
                        .frame(width: max(2, cpuWidth))
                        .help("CPU Only: \(overview.formattedCPUUsed) (\(overview.formattedCPUPercentage))")

                    Rectangle()
                        .fill(Color.indigo)
                        .frame(width: max(2, gpuWidth))
                        .help("GPU Only: \(overview.formattedGPUUsed) (\(overview.formattedGPUPercentage))")

                    Rectangle()
                        .fill(Color.green)
                        .frame(width: max(2, freeWidth))
                        .help("Free RAM: \(overview.formattedFree) (\(overview.formattedFreePercentage))")
                }
                .cornerRadius(6)
            }
            .frame(height: 20)

            // Legend
            HStack(spacing: 20) {
                legendItem(title: "CPU Memory", value: "\(overview.formattedCPUUsed) (\(overview.formattedCPUPercentage))", color: .blue)
                legendItem(title: "GPU Memory", value: "\(overview.formattedGPUUsed) (\(overview.formattedGPUPercentage))", color: .indigo)
                legendItem(title: "Free RAM", value: "\(overview.formattedFree) (\(overview.formattedFreePercentage))", color: .green)
            }
            .font(.caption)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(nsColor: .controlBackgroundColor))
        )
    }

    private func legendItem(title: String, value: String, color: Color) -> some View {
        HStack(spacing: 6) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(title)
                .foregroundColor(.secondary)
            Text(value)
                .fontWeight(.semibold)
        }
    }

    private var cpuSummaryCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label("CPU Memory", systemImage: "cpu.fill")
                    .font(.headline)
                    .foregroundColor(.blue)
                Spacer()
                pressurePill
            }

            HStack(spacing: 20) {
                GaugeRingView(
                    progress: overview.cpuRatio,
                    title: "CPU Share",
                    valueText: overview.formattedCPUPercentage,
                    gradient: Gradient(colors: [.blue, .cyan]),
                    lineWidth: 10,
                    size: 110
                )

                VStack(alignment: .leading, spacing: 8) {
                    statRow(label: "CPU Used RAM", value: overview.formattedCPUUsed, color: .primary)
                    statRow(label: "App Memory", value: cpu.formattedAppMemory, color: .blue)
                    statRow(label: "Wired (OS)", value: cpu.formattedWired, color: .orange)
                    statRow(label: "Compressed", value: cpu.formattedCompressed, color: .purple)
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(nsColor: .controlBackgroundColor))
        )
    }

    private var gpuSummaryCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label("GPU Memory", systemImage: "display.2")
                    .font(.headline)
                    .foregroundColor(.indigo)
                Spacer()
                if let util = gpu.deviceUtilizationPercentage {
                    Text(String(format: "GPU: %.0f%%", util))
                        .font(.caption2)
                        .fontWeight(.bold)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.indigo.opacity(0.15))
                        .foregroundColor(.indigo)
                        .cornerRadius(6)
                }
            }

            HStack(spacing: 20) {
                GaugeRingView(
                    progress: overview.gpuRatio,
                    title: "GPU Share",
                    valueText: overview.formattedGPUPercentage,
                    gradient: Gradient(colors: [.indigo, .purple]),
                    lineWidth: 10,
                    size: 110
                )

                VStack(alignment: .leading, spacing: 8) {
                    statRow(label: "GPU Used RAM", value: overview.formattedGPUUsed, color: .primary)
                    statRow(label: "In Use (Active)", value: gpu.formattedInUse, color: .indigo)
                    statRow(label: "Metal Budget Max", value: gpu.formattedWorkingSet, color: .secondary)
                    statRow(label: "Active Clients", value: "\(gpu.activeClientCount)", color: .secondary)
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(nsColor: .controlBackgroundColor))
        )
    }

    private var pressurePill: some View {
        let (color, text): (Color, String) = {
            switch cpu.pressureLevel {
            case .normal: return (.green, "Normal")
            case .warning: return (.orange, "Warning")
            case .critical: return (.red, "Critical")
            case .unknown: return (.gray, "Unknown")
            }
        }()

        return Text(text)
            .font(.caption2)
            .fontWeight(.semibold)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(color.opacity(0.15))
            .foregroundColor(color)
            .cornerRadius(6)
    }

    private func statRow(label: String, value: String, color: Color) -> some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(color)
        }
    }

    private var comparisonMatrixSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Memory Subsystem Comparison")
                .font(.headline)

            Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 10) {
                GridRow {
                    Text("Attribute").fontWeight(.semibold).foregroundColor(.secondary)
                    Text("CPU Only").fontWeight(.semibold).foregroundColor(.blue)
                    Text("GPU Only").fontWeight(.semibold).foregroundColor(.indigo)
                    Text("Total System").fontWeight(.semibold).foregroundColor(.purple)
                }
                .font(.caption)

                Divider()

                GridRow {
                    Text("Memory Used")
                    Text(overview.formattedCPUUsed)
                    Text(overview.formattedGPUUsed)
                    Text(overview.formattedTotalUsed)
                }
                .font(.caption)

                GridRow {
                    Text("% of Physical RAM")
                    Text(overview.formattedCPUPercentage)
                    Text(overview.formattedGPUPercentage)
                    Text(overview.formattedTotalUsedPercentage)
                }
                .font(.caption)

                GridRow {
                    Text("Active Footprint")
                    Text(cpu.formattedAppMemory)
                    Text(gpu.formattedInUse)
                    Text(overview.formattedTotalUsed)
                }
                .font(.caption)

                GridRow {
                    Text("Pressure / Utilization")
                    Text(cpu.pressureLevel.description)
                    Text(gpu.formattedDeviceUtilization)
                    Text(overview.formattedFreePercentage + " Free")
                }
                .font(.caption)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(nsColor: .controlBackgroundColor))
        )
    }
}
