import AppKit
import SwiftUI
import TokenManagerCore

struct MenuBarPanel: View {
    @EnvironmentObject private var model: TokenManagerAppModel
    @Environment(\.openWindow) private var openWindow
    @Environment(\.openSettings) private var openSettings

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("tokenmanager")
                    .font(.headline)
                Spacer()
                Button {
                    Task { await self.model.refreshEnabledAccounts() }
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .buttonStyle(.borderless)
                .help("Refresh")
            }

            if self.model.enabledAccounts.isEmpty {
                ContentUnavailableView("No accounts", systemImage: "key", description: Text("Add provider keys in Settings."))
                    .frame(width: 320, height: 160)
            } else {
                VStack(spacing: 8) {
                    ForEach(self.model.enabledAccounts) { account in
                        MenuAccountRow(account: account)
                    }
                }
            }

            Divider()

            HStack {
                Button("Open") {
                    self.openWindow(id: "main")
                    NSApp.activate(ignoringOtherApps: true)
                }
                Button("Settings") {
                    self.openSettings()
                    NSApp.activate(ignoringOtherApps: true)
                }
                Spacer()
                Button("Quit") {
                    NSApplication.shared.terminate(nil)
                }
            }
        }
        .padding(14)
        .frame(width: 360)
    }
}

private struct MenuAccountRow: View {
    @EnvironmentObject private var model: TokenManagerAppModel
    let account: ProviderAccount

    var body: some View {
        let provider = self.model.catalog.provider(id: self.account.providerID)
        let snapshot = self.model.snapshots[self.account.providerID]
        HStack(alignment: .top, spacing: 10) {
            Circle()
                .fill(snapshot == nil ? Color.secondary.opacity(0.35) : Color.accentColor)
                .frame(width: 9, height: 9)
                .padding(.top, 5)
            VStack(alignment: .leading, spacing: 3) {
                Text(provider?.shortName ?? self.account.providerID.rawValue)
                    .font(.callout.weight(.semibold))
                Text(snapshot?.balance?.displayString ?? self.model.errors[self.account.providerID] ?? "No snapshot")
                    .font(.caption)
                    .foregroundStyle(snapshot == nil ? .secondary : .primary)
                    .lineLimit(2)
            }
            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private extension MoneyAmount {
    var displayString: String {
        "\(self.currency) \(NSDecimalNumber(decimal: self.amount).stringValue)"
    }
}
