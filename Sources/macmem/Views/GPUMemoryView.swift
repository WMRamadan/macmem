import SwiftUI
import MacMemKit

/// Dedicated deep-dive view into GPU graphics memory and accelerator utilization.
public struct GPUMemoryView: View {
    public let gpu: GPUMemoryInfo
    public let totalPhysicalBytes: UInt64

    public init(gpu: GPUMemoryInfo, totalPhysicalBytes: UInt64) {
        self.gpu = gpu
        self.totalPhysicalBytes = totalPhysicalBytes
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Headline Section
                headlineSection

                // Key Metric Cards
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
                    MetricCardView(
                        title: "GPU Allocated RAM",
                        value: gpu.formattedAllocated,
                        subtitle: "\(gpu.formattedSystemPercentage(totalPhysicalBytes: totalPhysicalBytes)) of system RAM",
                        icon: "memorychip",
                        iconColor: .indigo,
                        accentColor: .indigo
                    )

                    MetricCardView(
                        title: "In-Use (Active)",
                        value: gpu.formattedInUse,
                        subtitle: "Live textures & render passes",
                        icon: "bolt.fill",
                        iconColor: .purple,
                        accentColor: .purple
                    )

                    MetricCardView(
                        title: "Max Working Set",
                        value: gpu.formattedWorkingSet,
                        subtitle: "Metal memory budget limit",
                        icon: "shield.ruler.fill",
                        iconColor: .primary,
                        accentColor: .primary
                    )

                    MetricCardView(
                        title: "Available Budget",
                        value: gpu.formattedAvailableBudget,
                        subtitle: "Headroom before driver paging",
                        icon: "arrow.up.circle.fill",
                        iconColor: .green,
                        accentColor: .green
                    )

                    MetricCardView(
                        title: "Process Memory",
                        value: gpu.formattedProcessAllocated,
                        subtitle: "Allocated by this app",
                        icon: "macwindow",
                        iconColor: .teal,
                        accentColor: .teal
                    )

                    MetricCardView(
                        title: "Active GPU Clients",
                        value: "\(gpu.activeClientCount)",
                        subtitle: "Running Metal/OpenGL clients",
                        icon: "person.2.fill",
                        iconColor: .secondary,
                        accentColor: .primary
                    )
                }

                // GPU Hardware & Utilization Breakdown
                HStack(alignment: .top, spacing: 16) {
                    utilizationSection
                    hardwareDetailsSection
                }

                // Architecture Mechanics
                architectureExplanation
            }
            .padding(20)
        }
    }

    // MARK: - Subviews

    private var headlineSection: some View {
        HStack(spacing: 24) {
            GaugeRingView(
                progress: gpu.systemMemoryRatio(totalPhysicalBytes: totalPhysicalBytes),
                title: "GPU Only",
                valueText: gpu.formattedSystemPercentage(totalPhysicalBytes: totalPhysicalBytes),
                gradient: Gradient(colors: [.indigo, .purple]),
                lineWidth: 14,
                size: 140
            )

            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Text(gpu.deviceName)
                        .font(.title2)
                        .fontWeight(.bold)

                    if gpu.isUnifiedMemory {
                        Text("Unified Memory")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Color.purple.opacity(0.15))
                            .foregroundColor(.purple)
                            .cornerRadius(6)
                    } else {
                        Text("Discrete VRAM")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Color.orange.opacity(0.15))
                            .foregroundColor(.orange)
                            .cornerRadius(6)
                    }
                }

                Text("\(gpu.formattedAllocated) allocated exclusively for GPU tasks (\(gpu.formattedSystemPercentage(totalPhysicalBytes: totalPhysicalBytes)) of \(ByteFormatter.format(totalPhysicalBytes)) RAM)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                HStack(spacing: 16) {
                    HStack(spacing: 4) {
                        Text("Metal Working Set Budget:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(ByteFormatter.formatPercentage(gpu.workingSetBudgetRatio))
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.indigo)
                    }

                    HStack(spacing: 4) {
                        Text("Active In-Use:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(ByteFormatter.formatPercentage(gpu.inUseRatioOfAllocated))
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.purple)
                    }
                }

                ProgressView(value: gpu.systemMemoryRatio(totalPhysicalBytes: totalPhysicalBytes))
                    .progressViewStyle(.linear)
                    .tint(.indigo)
                    .frame(maxWidth: 350)
            }

            Spacer()
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(nsColor: .controlBackgroundColor))
        )
    }

    private var utilizationSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("GPU Core Utilization", systemImage: "speedometer")
                .font(.headline)

            VStack(spacing: 12) {
                utilizationRow(
                    title: "Overall Device",
                    valueString: gpu.formattedDeviceUtilization,
                    ratio: (gpu.deviceUtilizationPercentage ?? 0.0) / 100.0,
                    color: .indigo
                )

                utilizationRow(
                    title: "3D Renderer Engine",
                    valueString: gpu.formattedRendererUtilization,
                    ratio: (gpu.rendererUtilizationPercentage ?? 0.0) / 100.0,
                    color: .purple
                )

                utilizationRow(
                    title: "2D Tiler Accelerator",
                    valueString: gpu.formattedTilerUtilization,
                    ratio: (gpu.tilerUtilizationPercentage ?? 0.0) / 100.0,
                    color: .cyan
                )
            }
            .padding(12)
            .background(Color(nsColor: .windowBackgroundColor).opacity(0.6))
            .cornerRadius(10)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(nsColor: .controlBackgroundColor))
        )
    }

    private func utilizationRow(title: String, valueString: String, ratio: Double, color: Color) -> some View {
        VStack(spacing: 4) {
            HStack {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Text(valueString)
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(color)
            }
            ProgressView(value: max(0.0, min(1.0, ratio)))
                .progressViewStyle(.linear)
                .tint(color)
        }
    }

    private var hardwareDetailsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("Hardware & Driver Registry", systemImage: "cpu")
                .font(.headline)

            VStack(spacing: 8) {
                statRow(label: "Device Name", value: gpu.deviceName)
                statRow(label: "Architecture", value: gpu.isUnifiedMemory ? "Apple Unified Memory" : "PCIe Discrete Graphics")
                statRow(label: "Attached Clients", value: "\(gpu.activeClientCount) processes")

                if let vramTotal = gpu.vramTotalBytes {
                    statRow(label: "Discrete VRAM Total", value: ByteFormatter.format(vramTotal))
                }
                if let vramFree = gpu.vramFreeBytes {
                    statRow(label: "Discrete VRAM Free", value: ByteFormatter.format(vramFree))
                }
            }
            .padding(12)
            .background(Color(nsColor: .windowBackgroundColor).opacity(0.6))
            .cornerRadius(10)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(nsColor: .controlBackgroundColor))
        )
    }

    private var architectureExplanation: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "info.circle.fill")
                    .foregroundColor(.indigo)
                Text("Understanding Apple Silicon GPU Memory")
                    .font(.headline)
            }

            Text("On Apple Silicon, CPU and GPU share a single unified high-bandwidth memory bus without PCI transfers. The GPU dynamically allocates buffers (including LLMs and neural models) from system RAM. MacMem tracks this allocation independently so CPU and GPU memory percentages sum to the total system memory used.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(nsColor: .controlBackgroundColor))
        )
    }

    private func statRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
        }
    }
}
