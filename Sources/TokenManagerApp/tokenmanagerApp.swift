import AppKit
import SwiftUI
import TokenManagerCore

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        let arguments = Set(CommandLine.arguments)
        let needsDockWindow = arguments.contains("--demo")
            || arguments.contains("--open-settings")
            || arguments.contains("--open-quick-preview")
        NSApp.setActivationPolicy(needsDockWindow ? .regular : .accessory)
        if needsDockWindow {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                NSApp.activate(ignoringOtherApps: true)
            }
        }
    }
}

@main
struct TokenManagerNativeApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var model = TokenManagerAppModel()

    var body: some Scene {
        WindowGroup("tokenmanager", id: "main") {
            ContentView()
                .environmentObject(self.model)
                .frame(minWidth: 980, minHeight: 560)
                .background(LaunchAutomationView())
                .task {
                    await self.model.refreshEnabledAccounts()
                }
        }
        .defaultSize(width: 1120, height: 720)

        Settings {
            SettingsView()
                .environmentObject(self.model)
                .frame(width: 720, height: 520)
        }

        MenuBarExtra {
            MenuBarPanel()
                .environmentObject(self.model)
        } label: {
            Label(self.model.menuTitle, systemImage: "chart.bar.xaxis")
        }
        .menuBarExtraStyle(.window)

        WindowGroup("tokenmanager Quick View", id: "quick-preview") {
            MenuBarPanel()
                .environmentObject(self.model)
                .frame(width: 390)
        }
        .defaultSize(width: 390, height: 526)
    }
}

private struct LaunchAutomationView: View {
    @Environment(\.openWindow) private var openWindow
    @Environment(\.openSettings) private var openSettings
    @State private var didRun = false

    var body: some View {
        Color.clear
            .frame(width: 0, height: 0)
            .task {
                guard !self.didRun else { return }
                self.didRun = true
                let arguments = Set(CommandLine.arguments)
                guard arguments.contains("--open-settings") || arguments.contains("--open-quick-preview") else {
                    return
                }
                try? await Task.sleep(nanoseconds: 650_000_000)
                if arguments.contains("--open-settings") {
                    self.openSettings()
                }
                if arguments.contains("--open-quick-preview") {
                    self.openWindow(id: "quick-preview")
                }
                NSApp.activate(ignoringOtherApps: true)
            }
    }
}
