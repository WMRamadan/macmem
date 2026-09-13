import AppKit
import Foundation
import MacMemKit
import Observation

public enum NavigationTab: String, CaseIterable, Identifiable {
    case overview = "Overview"
    case cpu = "CPU Memory"
    case gpu = "GPU Memory"
    case charts = "Trends & Charts"

    public var id: String { rawValue }

    public var icon: String {
        switch self {
        case .overview: return "square.grid.2x2.fill"
        case .cpu: return "cpu.fill"
        case .gpu: return "display.2"
        case .charts: return "chart.xyaxis.line"
        }
    }
}

@Observable
@MainActor
public final class DashboardViewModel {

    public let service: MemoryMonitorService
    public var selectedTab: NavigationTab = .overview
    public var alertMessage: String?
    public var showAlert: Bool = false

    public var refreshIntervalOptions: [TimeInterval] = [0.5, 1.0, 2.0, 5.0]

    public init(service: MemoryMonitorService = MemoryMonitorService()) {
        self.service = service
    }

    public var overview: SystemMemoryOverview { service.systemOverview }
    public var cpu: CPUMemoryInfo { service.cpuInfo }
    public var gpu: GPUMemoryInfo { service.gpuInfo }
    public var history: [MemorySample] { service.history }
    public var isPaused: Bool { service.isPaused }
    public var refreshInterval: TimeInterval {
        get { service.refreshInterval }
        set { service.refreshInterval = newValue }
    }
    public var lastUpdated: Date? { service.lastUpdated }
    public var lastErrorMessage: String? { service.lastErrorMessage }

    public func togglePause() {
        service.togglePause()
    }

    public func refresh() {
        service.refresh()
    }

    public func clearHistory() {
        service.clearHistory()
    }

    /// Copies current snapshot JSON to macOS system clipboard.
    public func copyJSONToClipboard() {
        do {
            let json = try service.exportJSON()
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(json, forType: .string)
            self.alertMessage = "Snapshot JSON copied to clipboard!"
            self.showAlert = true
        } catch {
            self.alertMessage = "Failed to copy JSON: \(error.localizedDescription)"
            self.showAlert = true
        }
    }

    /// Prompts user with NSSavePanel to save snapshot to a .json file.
    public func exportJSONToFile() {
        do {
            let json = try service.exportJSON()
            let panel = NSSavePanel()
            panel.title = "Save Memory Snapshot"
            panel.nameFieldStringValue = "macmem_snapshot_\(Int(Date().timeIntervalSince1970)).json"
            panel.allowedContentTypes = [.json]

            if panel.runModal() == .OK, let url = panel.url {
                try json.write(to: url, atomically: true, encoding: .utf8)
                self.alertMessage = "Snapshot successfully saved to \(url.lastPathComponent)!"
                self.showAlert = true
            }
        } catch {
            self.alertMessage = "Failed to export JSON: \(error.localizedDescription)"
            self.showAlert = true
        }
    }
}
