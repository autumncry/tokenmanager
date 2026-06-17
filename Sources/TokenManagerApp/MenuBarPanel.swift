import AppKit
import SwiftUI
import TokenManagerCore

struct MenuBarPanel: View {
    @EnvironmentObject private var model: TokenManagerAppModel
    @Environment(\.openWindow) private var openWindow
    @Environment(\.openSettings) private var openSettings
    @AppStorage("appLanguage") private var appLanguage = "en"

    private var copy: AppCopy {
        AppCopy(language: self.appLanguage)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            self.header

            if self.model.enabledAccounts.isEmpty {
                ContentUnavailableView(
                    self.copy.noAccounts,
                    systemImage: "key",
                    description: Text(self.copy.addProviderKeys))
                .frame(width: 358, height: 188)
            } else {
                VStack(spacing: 8) {
                    ForEach(self.model.enabledAccounts) { account in
                        MenuAccountRow(account: account, copy: self.copy)
                    }
                }
            }

            Divider()

            self.actions
        }
        .padding(16)
        .frame(width: 390)
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private var header: some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text("tokenmanager")
                    .font(.system(size: 17, weight: .semibold))
                Text(self.copy.menuSubtitle(self.model.enabledAccounts.count))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button {
                Task { await self.model.refreshEnabledAccounts() }
            } label: {
                Label(self.copy.refresh, systemImage: "arrow.clockwise")
                    .labelStyle(.iconOnly)
            }
            .buttonStyle(.borderless)
            .disabled(self.model.isRefreshing)
            .help(self.copy.refresh)
        }
    }

    private var actions: some View {
        HStack(spacing: 8) {
            Button {
                self.openWindow(id: "main")
                NSApp.activate(ignoringOtherApps: true)
            } label: {
                Label(self.copy.open, systemImage: "macwindow")
            }

            Button {
                self.openSettings()
                NSApp.activate(ignoringOtherApps: true)
            } label: {
                Label(self.copy.settings, systemImage: "gearshape")
            }

            Spacer()

            Button(role: .destructive) {
                NSApplication.shared.terminate(nil)
            } label: {
                Label(self.copy.quit, systemImage: "power")
            }
        }
        .buttonStyle(.bordered)
        .controlSize(.small)
    }
}

private struct MenuAccountRow: View {
    @EnvironmentObject private var model: TokenManagerAppModel
    let account: ProviderAccount
    let copy: AppCopy

    var body: some View {
        let provider = self.model.catalog.provider(id: self.account.providerID)
        let snapshot = self.model.snapshots[self.account.providerID]
        HStack(alignment: .center, spacing: 12) {
            Circle()
                .fill(self.statusColor(snapshot: snapshot))
                .frame(width: 10, height: 10)

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(provider?.shortName ?? self.account.providerID.rawValue)
                        .font(.callout.weight(.semibold))
                    Spacer()
                    Text(snapshot?.balance?.displayString ?? self.copy.pending)
                        .font(.callout.weight(.semibold))
                        .foregroundStyle(snapshot == nil ? .secondary : .primary)
                }

                HStack(spacing: 8) {
                    Text(self.detail(provider: provider, snapshot: snapshot))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                    Spacer()
                    if let percent = snapshot?.quotaWindows.first?.usedPercent {
                        Text("\(Int(percent.rounded()))%")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                }

                if let percent = snapshot?.quotaWindows.first?.usedPercent {
                    ProgressView(value: percent / 100)
                        .progressViewStyle(.linear)
                        .tint(self.statusColor(snapshot: snapshot))
                }
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, minHeight: 70, alignment: .leading)
        .background(Color.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private func detail(provider: ProviderDescriptor?, snapshot: ProviderUsageSnapshot?) -> String {
        if let error = self.model.errors[self.account.providerID] {
            return error
        }
        if let window = snapshot?.quotaWindows.first {
            return self.copy.windowUsage(window)
        }
        if let usage = snapshot?.usage {
            return "\(self.copy.usage): \(usage.displayString)"
        }
        return provider?.supportsLiveRefresh == true ? self.copy.liveRefresh : self.copy.manualReady
    }

    private func statusColor(snapshot: ProviderUsageSnapshot?) -> Color {
        guard snapshot != nil else { return .secondary.opacity(0.45) }
        if self.model.errors[self.account.providerID] != nil { return .orange }
        return .accentColor
    }
}
