import AppKit
import SwiftUI
import MacMemKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApplication.shared.setActivationPolicy(.regular)
        NSApplication.shared.activate(ignoringOtherApps: true)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }
}

@main
struct MacMemApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @State private var viewModel = DashboardViewModel()

    init() {
        // Ensure regular application mode when run as a standalone binary via swift run
        NSApplication.shared.setActivationPolicy(.regular)
    }

    var body: some Scene {
        WindowGroup {
            ContentView(viewModel: viewModel)
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified)
        .defaultSize(width: 960, height: 660)
        .commands {
            CommandGroup(replacing: .newItem) {}

            CommandMenu("Monitor") {
                Button(viewModel.isPaused ? "Resume Polling" : "Pause Polling") {
                    viewModel.togglePause()
                }
                .keyboardShortcut("p", modifiers: [.command])

                Button("Refresh Now") {
                    viewModel.refresh()
                }
                .keyboardShortcut("r", modifiers: [.command])

                Divider()

                Button("Clear History") {
                    viewModel.clearHistory()
                }
                .keyboardShortcut("k", modifiers: [.command])

                Divider()

                Button("Copy Snapshot JSON") {
                    viewModel.copyJSONToClipboard()
                }
                .keyboardShortcut("c", modifiers: [.command, .shift])

                Button("Save Snapshot to File...") {
                    viewModel.exportJSONToFile()
                }
                .keyboardShortcut("s", modifiers: [.command])
            }
        }
    }
}
