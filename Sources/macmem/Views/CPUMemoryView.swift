import SwiftUI
import MacMemKit

/// Dedicated deep-dive view into CPU / Host system memory.
public struct CPUMemoryView: View {
    public let cpu: CPUMemoryInfo

    public init(cpu: CPUMemoryInfo) {
        self.cpu = cpu
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Headline Section
                headlineSection

                // Key Metric Cards
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
                    MetricCardView(
                        title: "CPU Used RAM",
                        value: cpu.formattedUsed,
                        subtitle: "\(cpu.formattedUsedPercentage) of system RAM",
                        icon: "cpu.fill",
                        iconColor: .blue,
                        accentColor: .blue
                    )

                    MetricCardView(
                        title: "App Memory",
                        value: cpu.formattedAppMemory,
                        subtitle: "User space apps",
                        icon: "app.badge.fill",
                        iconColor: .blue,
                        accentColor: .primary
                    )

                    MetricCardView(
                        title: "Wired Memory",
                        value: cpu.formattedWired,
                        subtitle: "Locked by kernel & OS",
                        icon: "lock.shield.fill",
                        iconColor: .orange,
                        accentColor: .orange
                    )

                    MetricCardView(
                        title: "Compressed",
                        value: cpu.formattedCompressed,
                        subtitle: "Stored in RAM by compressor",
                        icon: "arrow.down.right.and.arrow.up.left",
                        iconColor: .purple,
                        accentColor: .purple
                    )

                    MetricCardView(
                        title: "Cached Files",
                        value: cpu.formattedCached,
                        subtitle: "Purgeable cache",
                        icon: "folder.badge.gearshape",
                        iconColor: .teal,
                        accentColor: .teal
                    )

                    MetricCardView(
                        title: "Free Memory",
                        value: cpu.formattedFree,
                        subtitle: "Unallocated RAM",
                        icon: "leaf.fill",
                        iconColor: .green,
                        accentColor: .green
                    )
                }

                // Swap Space & VM Paging Section
                HStack(alignment: .top, spacing: 16) {
                    swapSection
                    vmPagingSection
                }

                // Memory Pressure Diagnostic
                memoryPressureDiagnostic
            }
            .padding(20)
        }
    }

    // MARK: - Subviews

    private var headlineSection: some View {
        HStack(spacing: 24) {
            GaugeRingView(
                progress: cpu.usedRatio,
                title: "CPU Only",
                valueText: cpu.formattedUsedPercentage,
                gradient: Gradient(colors: [.blue, .cyan]),
                lineWidth: 14,
                size: 140
            )

            VStack(alignment: .leading, spacing: 8) {
                Text("CPU Memory (Host Exclusive)")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("\(cpu.formattedUsed) of \(cpu.formattedTotal) physical RAM used exclusively by CPU tasks")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                HStack(spacing: 12) {
                    HStack(spacing: 6) {
                        Text("Pressure:")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Text(cpu.pressureLevel.description)
                            .font(.caption)
                            .fontWeight(.bold)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(pressureColor.opacity(0.15))
                            .foregroundColor(pressureColor)
                            .cornerRadius(6)
                    }

                    Text("Total System Used (CPU + GPU): \(cpu.formattedSystemTotalUsed) (\(cpu.formattedSystemTotalUsedPercentage))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                ProgressView(value: cpu.usedRatio)
                    .progressViewStyle(.linear)
                    .tint(.blue)
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

    private var swapSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Virtual Swap Memory", systemImage: "arrow.triangle.2.circlepath")
                .font(.headline)

            VStack(spacing: 8) {
                statRow(label: "Swap Used", value: cpu.formattedSwapUsed, color: .orange)
                statRow(label: "Swap Free", value: cpu.formattedSwapFree, color: .secondary)
                statRow(label: "Swap Total", value: cpu.formattedSwapTotal, color: .primary)

                ProgressView(value: cpu.swapUsedRatio)
                    .progressViewStyle(.linear)
                    .tint(.orange)
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

    private var vmPagingSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Kernel VM Paging", systemImage: "arrow.up.and.down.circle")
                .font(.headline)

            VStack(spacing: 8) {
                statRow(label: "Page Ins", value: "\(cpu.pageIns.formatted()) pages", color: .primary)
                statRow(label: "Page Outs", value: "\(cpu.pageOuts.formatted()) pages", color: .primary)
                statRow(label: "Inactive Pages", value: ByteFormatter.format(cpu.inactiveBytes), color: .secondary)
                statRow(label: "Active Pages", value: ByteFormatter.format(cpu.activeBytes), color: .secondary)
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

    private var memoryPressureDiagnostic: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "gauge.with.needle.fill")
                    .foregroundColor(pressureColor)
                Text("Memory Pressure Assessment")
                    .font(.headline)
            }

            Text(pressureExplanation)
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

    private var pressureColor: Color {
        switch cpu.pressureLevel {
        case .normal: return .green
        case .warning: return .orange
        case .critical: return .red
        case .unknown: return .gray
        }
    }

    private var pressureExplanation: String {
        switch cpu.pressureLevel {
        case .normal:
            return "Normal: Physical RAM has sufficient headroom for active applications and file caching. Memory compressor and swap are operating comfortably."
        case .warning:
            return "Warning: Physical memory is experiencing elevated load. macOS is actively compressing memory pages and may begin utilizing swap space."
        case .critical:
            return "Critical: Memory pressure is severe. Intensive swapping is occurring and system responsiveness may degrade until memory is freed."
        case .unknown:
            return "Memory pressure telemetry is currently unavailable."
        }
    }

    private func statRow(label: String, value: String, color: Color) -> some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(color)
        }
    }
}
