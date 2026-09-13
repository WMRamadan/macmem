import Charts
import SwiftUI
import MacMemKit

public enum ChartDisplayMode: String, CaseIterable, Identifiable {
    case gigabytes = "Gigabytes (GB)"
    case percentage = "Percentage (%)"

    public var id: String { rawValue }
}

/// Interactive historical timeline charting CPU, GPU, and Total System memory dynamics.
public struct HistoryChartView: View {
    public let history: [MemorySample]
    public let onClear: () -> Void

    @State private var displayMode: ChartDisplayMode = .gigabytes

    public init(history: [MemorySample], onClear: @escaping () -> Void) {
        self.history = history
        self.onClear = onClear
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header & Mode Selector
                headerSection

                // Main Timeline Chart
                if history.isEmpty {
                    emptyStateView
                } else {
                    chartCard
                }

                // Summary Analytics Cards
                analyticsGrid
            }
            .padding(20)
        }
    }

    // MARK: - Subviews

    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Memory Trajectory")
                    .font(.title2)
                    .fontWeight(.bold)
                Text("CPU% + GPU% = Total System Used% (\(history.count) samples)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Picker("Display Mode", selection: $displayMode) {
                ForEach(ChartDisplayMode.allCases) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .frame(width: 240)

            Button(role: .destructive, action: onClear) {
                Label("Clear", systemImage: "trash")
            }
            .buttonStyle(.bordered)
        }
    }

    private var chartCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 20) {
                legendPill(title: "Total System Used", color: .purple)
                legendPill(title: "CPU Only", color: .blue)
                legendPill(title: "GPU Only", color: .indigo)
                legendPill(title: "GPU In-Use", color: .pink)
                Spacer()
            }

            Chart {
                ForEach(Array(history.enumerated()), id: \.element.id) { index, sample in
                    let xVal = index - history.count + 1

                    switch displayMode {
                    case .gigabytes:
                        // Total System Used
                        LineMark(
                            x: .value("Time (s)", xVal),
                            y: .value("Memory (GB)", sample.totalSystemUsedGB),
                            series: .value("Series", "Total System Used")
                        )
                        .foregroundStyle(Color.purple)
                        .lineStyle(StrokeStyle(lineWidth: 2.5))
                        .interpolationMethod(.catmullRom)

                        AreaMark(
                            x: .value("Time (s)", xVal),
                            y: .value("Memory (GB)", sample.totalSystemUsedGB),
                            series: .value("Series", "Total System Used")
                        )
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.purple.opacity(0.18), Color.purple.opacity(0.01)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .interpolationMethod(.catmullRom)

                        // CPU Used Only
                        LineMark(
                            x: .value("Time (s)", xVal),
                            y: .value("Memory (GB)", sample.cpuUsedGB),
                            series: .value("Series", "CPU Only")
                        )
                        .foregroundStyle(Color.blue)
                        .interpolationMethod(.catmullRom)

                        // GPU Allocated Only
                        LineMark(
                            x: .value("Time (s)", xVal),
                            y: .value("Memory (GB)", sample.gpuAllocatedGB),
                            series: .value("Series", "GPU Only")
                        )
                        .foregroundStyle(Color.indigo)
                        .interpolationMethod(.catmullRom)

                        // GPU In-Use
                        LineMark(
                            x: .value("Time (s)", xVal),
                            y: .value("Memory (GB)", sample.gpuInUseGB),
                            series: .value("Series", "GPU In-Use")
                        )
                        .foregroundStyle(Color.pink)
                        .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [4, 4]))
                        .interpolationMethod(.catmullRom)

                    case .percentage:
                        // Total System Used %
                        LineMark(
                            x: .value("Time (s)", xVal),
                            y: .value("Usage (%)", sample.totalSystemUsedRatio * 100.0),
                            series: .value("Series", "Total System Used")
                        )
                        .foregroundStyle(Color.purple)
                        .lineStyle(StrokeStyle(lineWidth: 2.5))
                        .interpolationMethod(.catmullRom)

                        AreaMark(
                            x: .value("Time (s)", xVal),
                            y: .value("Usage (%)", sample.totalSystemUsedRatio * 100.0),
                            series: .value("Series", "Total System Used")
                        )
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.purple.opacity(0.18), Color.purple.opacity(0.01)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .interpolationMethod(.catmullRom)

                        // CPU Used %
                        LineMark(
                            x: .value("Time (s)", xVal),
                            y: .value("Usage (%)", sample.cpuUsedRatio * 100.0),
                            series: .value("Series", "CPU Only")
                        )
                        .foregroundStyle(Color.blue)
                        .interpolationMethod(.catmullRom)

                        // GPU Allocated %
                        LineMark(
                            x: .value("Time (s)", xVal),
                            y: .value("Usage (%)", sample.gpuAllocatedRatio * 100.0),
                            series: .value("Series", "GPU Only")
                        )
                        .foregroundStyle(Color.indigo)
                        .interpolationMethod(.catmullRom)
                    }
                }
            }
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: 6)) { value in
                    AxisGridLine()
                    AxisTick()
                    if let seconds = value.as(Int.self) {
                        AxisValueLabel("\(seconds)s")
                    }
                }
            }
            .chartYAxis {
                AxisMarks(values: .automatic(desiredCount: 5)) { value in
                    AxisGridLine()
                    AxisTick()
                    if displayMode == .gigabytes {
                        if let gb = value.as(Double.self) {
                            AxisValueLabel(String(format: "%.1f GB", gb))
                        }
                    } else {
                        if let pct = value.as(Double.self) {
                            AxisValueLabel(String(format: "%.0f%%", pct))
                        }
                    }
                }
            }
            .frame(height: 320)
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(nsColor: .controlBackgroundColor))
        )
    }

    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 40))
                .foregroundColor(.secondary)
            Text("No Samples Recorded Yet")
                .font(.headline)
            Text("Historical telemetry will appear here as memory statistics are polled.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 280)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(nsColor: .controlBackgroundColor))
        )
    }

    private var analyticsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
            let peakSystem = history.map(\.totalSystemUsedBytes).max() ?? 0
            let peakCPU = history.map(\.cpuUsedBytes).max() ?? 0
            let peakGPU = history.map(\.gpuAllocatedBytes).max() ?? 0
            let avgSystem = history.isEmpty ? 0 : history.map(\.totalSystemUsedBytes).reduce(0, +) / UInt64(history.count)

            MetricCardView(
                title: "Peak System Memory",
                value: ByteFormatter.format(peakSystem),
                subtitle: "Max combined RAM used",
                icon: "arrow.up.circle.fill",
                iconColor: .purple,
                accentColor: .purple
            )

            MetricCardView(
                title: "Peak CPU Only",
                value: ByteFormatter.format(peakCPU),
                subtitle: "Max CPU-exclusive",
                icon: "arrow.up.circle",
                iconColor: .blue,
                accentColor: .blue
            )

            MetricCardView(
                title: "Peak GPU Only",
                value: ByteFormatter.format(peakGPU),
                subtitle: "Max GPU-exclusive",
                icon: "arrow.up.circle",
                iconColor: .indigo,
                accentColor: .indigo
            )

            MetricCardView(
                title: "Average System Used",
                value: ByteFormatter.format(avgSystem),
                subtitle: "Time-weighted",
                icon: "chart.bar.fill",
                iconColor: .primary,
                accentColor: .primary
            )
        }
    }

    private func legendPill(title: String, color: Color) -> some View {
        HStack(spacing: 6) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.primary)
        }
    }
}
