import AppKit
import SwiftUI
import TokenManagerCore

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
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
                .frame(minWidth: 820, minHeight: 520)
                .task {
                    await self.model.refreshEnabledAccounts()
                }
        }
        .defaultSize(width: 920, height: 620)

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
    }
}
