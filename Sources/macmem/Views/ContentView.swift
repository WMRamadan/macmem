import SwiftUI
import MacMemKit

/// Root navigation view for the MacMem desktop application.
public struct ContentView: View {
    @Bindable var viewModel: DashboardViewModel

    public init(viewModel: DashboardViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        NavigationSplitView {
            sidebar
        } detail: {
            detailContent
        }
        .toolbar {
            toolbarItems
        }
        .alert("MacMem", isPresented: $viewModel.showAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.alertMessage ?? "")
        }
        .frame(minWidth: 860, minHeight: 600)
    }

    // MARK: - Sidebar

    private var sidebar: some View {
        List(NavigationTab.allCases, id: \.self, selection: $viewModel.selectedTab) { tab in
            NavigationLink(value: tab) {
                Label(tab.rawValue, systemImage: tab.icon)
            }
        }
        .navigationTitle("MacMem")
        .listStyle(.sidebar)
        .frame(minWidth: 190)
    }

    // MARK: - Detail Content

    @ViewBuilder
    private var detailContent: some View {
        switch viewModel.selectedTab {
        case .overview:
            OverviewView(
                overview: viewModel.overview,
                cpu: viewModel.cpu,
                gpu: viewModel.gpu
            )
        case .cpu:
            CPUMemoryView(cpu: viewModel.cpu)
        case .gpu:
            GPUMemoryView(
                gpu: viewModel.gpu,
                totalPhysicalBytes: viewModel.overview.totalPhysicalBytes
            )
        case .charts:
            HistoryChartView(
                history: viewModel.history,
                onClear: { viewModel.clearHistory() }
            )
        }
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarItems: some ToolbarContent {
        ToolbarItemGroup(placement: .automatic) {
            // Live Status Indicator
            HStack(spacing: 6) {
                Circle()
                    .fill(viewModel.isPaused ? Color.orange : Color.green)
                    .frame(width: 8, height: 8)
                Text(viewModel.isPaused ? "Paused" : "Live")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .padding(.trailing, 8)

            // Refresh Interval Picker
            Picker("Interval", selection: $viewModel.refreshInterval) {
                ForEach(viewModel.refreshIntervalOptions, id: \.self) { sec in
                    Text(String(format: "%.1fs", sec)).tag(sec)
                }
            }
            .pickerStyle(.menu)
            .frame(width: 90)
            .help("Telemetry polling interval")

            // Pause / Resume
            Button {
                viewModel.togglePause()
            } label: {
                Image(systemName: viewModel.isPaused ? "play.fill" : "pause.fill")
            }
            .help(viewModel.isPaused ? "Resume real-time monitoring" : "Pause monitoring")

            // Manual Refresh
            Button {
                viewModel.refresh()
            } label: {
                Image(systemName: "arrow.clockwise")
            }
            .help("Poll memory now")

            // Export Actions Menu
            Menu {
                Button {
                    viewModel.copyJSONToClipboard()
                } label: {
                    Label("Copy Snapshot JSON", systemImage: "doc.on.doc")
                }

                Button {
                    viewModel.exportJSONToFile()
                } label: {
                    Label("Save Snapshot to File...", systemImage: "square.and.arrow.down")
                }
            } label: {
                Image(systemName: "square.and.arrow.up")
            }
            .help("Export memory snapshot")
        }
    }
}
