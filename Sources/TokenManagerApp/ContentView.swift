import SwiftUI
import TokenManagerCore

struct ContentView: View {
    @EnvironmentObject private var model: TokenManagerAppModel
    @AppStorage("appLanguage") private var appLanguage = "zh-Hans"

    var copy: AppCopy {
        AppCopy(language: self.appLanguage)
    }

    var body: some View {
        NavigationSplitView {
            ProviderSidebar(copy: self.copy)
                .navigationSplitViewColumnWidth(min: 270, ideal: 292, max: 330)
        } detail: {
            ProviderDashboard(copy: self.copy, providerID: self.model.selectedProviderID)
        }
        .toolbar {
            ToolbarItemGroup {
                Picker("", selection: self.$appLanguage) {
                    Text("中文").tag("zh-Hans")
                    Text("EN").tag("en")
                }
                .pickerStyle(.segmented)
                .frame(width: 112)

                Button {
                    Task { await self.model.refreshEnabledAccounts() }
                } label: {
                    Label(self.copy.refresh, systemImage: "arrow.clockwise")
                }
                .disabled(self.model.isRefreshing)

                SettingsLink {
                    Label(self.copy.settings, systemImage: "gearshape")
                }
            }
        }
    }
}

private struct ProviderSidebar: View {
    @EnvironmentObject private var model: TokenManagerAppModel
    let copy: AppCopy

    var body: some View {
        List(selection: self.$model.selectedProviderID) {
            Section(self.copy.activeAccounts) {
                ForEach(self.model.enabledAccounts) { account in
                    let provider = self.model.catalog.provider(id: account.providerID)
                    ProviderSidebarRow(
                        title: provider?.shortName ?? account.providerID.rawValue,
                        subtitle: account.displayName,
                        isEnabled: true,
                        hasError: self.model.errors[account.providerID] != nil)
                    .tag(account.providerID)
                }
            }

            Section(self.copy.providerCatalog) {
                ForEach(self.model.catalog.providers.filter { !self.model.isEnabled($0.id) }) { provider in
                    ProviderSidebarRow(
                        title: provider.shortName,
                        subtitle: provider.displayName,
                        isEnabled: false,
                        hasError: self.model.errors[provider.id] != nil)
                    .tag(provider.id)
                }
            }
        }
        .listStyle(.sidebar)
        .navigationTitle("tokenmanager")
        .safeAreaInset(edge: .bottom) {
            HStack(spacing: 8) {
                Image(systemName: "lock.shield")
                    .foregroundStyle(.green)
                Text(self.copy.localOnly)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(.bar)
        }
    }
}

private struct ProviderSidebarRow: View {
    let title: String
    let subtitle: String
    let isEnabled: Bool
    let hasError: Bool

    var body: some View {
        HStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(self.isEnabled ? Color.accentColor.opacity(0.16) : Color.secondary.opacity(0.10))
                Image(systemName: self.isEnabled ? "chart.bar.fill" : "plus")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(self.isEnabled ? Color.accentColor : Color.secondary)
            }
            .frame(width: 28, height: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(self.title)
                    .font(.body)
                    .lineLimit(1)
                Text(self.subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            if self.hasError {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.orange)
                    .imageScale(.small)
            }
        }
        .padding(.vertical, 3)
    }
}

private struct ProviderDashboard: View {
    @EnvironmentObject private var model: TokenManagerAppModel
    let copy: AppCopy
    let providerID: ProviderID?
    @State private var apiKey = ""
    @State private var displayName = ""

    var body: some View {
        if let providerID, let provider = self.model.catalog.provider(id: providerID) {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    HeroHeader(copy: self.copy, provider: provider, snapshot: self.model.snapshots[provider.id])
                    MetricGrid(copy: self.copy, provider: provider, snapshot: self.model.snapshots[provider.id])
                    if let snapshot = self.model.snapshots[provider.id], !snapshot.quotaWindows.isEmpty {
                        QuotaSection(copy: self.copy, snapshot: snapshot)
                    }
                    CredentialCard(
                        copy: self.copy,
                        provider: provider,
                        apiKey: self.$apiKey,
                        displayName: self.$displayName,
                        save: {
                            Task {
                                await self.model.saveAPIKey(self.apiKey, providerID: provider.id, displayName: self.displayName)
                                self.apiKey = ""
                            }
                        })
                    ProviderNotesCard(copy: self.copy, provider: provider, error: self.model.errors[provider.id])
                }
                .padding(24)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .background(Color(nsColor: .windowBackgroundColor))
            .navigationTitle(provider.displayName)
        } else {
            ContentUnavailableView(self.copy.selectProvider, systemImage: "chart.bar.doc.horizontal")
        }
    }
}

private struct HeroHeader: View {
    let copy: AppCopy
    let provider: ProviderDescriptor
    let snapshot: ProviderUsageSnapshot?

    var body: some View {
        HStack(alignment: .center, spacing: 18) {
            ZStack {
                Circle()
                    .fill(LinearGradient(
                        colors: [Color.accentColor.opacity(0.92), Color.cyan.opacity(0.82)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing))
                Image(systemName: "sum")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(.white)
            }
            .frame(width: 68, height: 68)

            VStack(alignment: .leading, spacing: 6) {
                Text(provider.displayName)
                    .font(.system(size: 30, weight: .semibold))
                Text(snapshot?.accountName ?? self.copy.providerSubtitle(provider))
                    .font(.callout)
                    .foregroundStyle(.secondary)
                HStack(spacing: 8) {
                    Label(provider.supportsLiveRefresh ? self.copy.liveRefresh : self.copy.manualReady, systemImage: provider.supportsLiveRefresh ? "bolt.fill" : "tray.and.arrow.down")
                    Label(self.copy.keychainOnly, systemImage: "key.fill")
                    Label(self.copy.localOnly, systemImage: "lock.fill")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 6) {
                Text(snapshot?.updatedAt.formatted(date: .abbreviated, time: .shortened) ?? self.copy.noSnapshot)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if let url = provider.dashboardURL {
                    Link(destination: url) {
                        Label(self.copy.openDashboard, systemImage: "safari")
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
        .padding(22)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

private struct MetricGrid: View {
    let copy: AppCopy
    let provider: ProviderDescriptor
    let snapshot: ProviderUsageSnapshot?

    var body: some View {
        Grid(horizontalSpacing: 12, verticalSpacing: 12) {
            GridRow {
                MetricCard(title: self.copy.balance, value: snapshot?.balance?.displayString ?? "—", symbol: "creditcard", tint: .green)
                MetricCard(title: self.copy.usage, value: snapshot?.usage?.displayString ?? "—", symbol: "waveform.path.ecg", tint: .blue)
                MetricCard(title: self.copy.limit, value: snapshot?.limit?.displayString ?? "—", symbol: "gauge.medium", tint: .purple)
            }
            GridRow {
                MetricCard(title: self.copy.metrics, value: provider.supportedMetrics.map(\.rawValue).sorted().joined(separator: " · "), symbol: "square.stack.3d.up", tint: .orange)
                    .gridCellColumns(2)
                MetricCard(title: self.copy.source, value: snapshot?.source ?? self.copy.waitingForKey, symbol: "network", tint: .teal)
            }
        }
    }
}

private struct MetricCard: View {
    let title: String
    let value: String
    let symbol: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: self.symbol)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(self.tint)
                    .frame(width: 28, height: 28)
                    .background(self.tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 6, style: .continuous))
                Spacer()
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(self.title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(self.value)
                    .font(.system(size: 18, weight: .semibold))
                    .lineLimit(2)
                    .minimumScaleFactor(0.72)
                    .textSelection(.enabled)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, minHeight: 126, alignment: .topLeading)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

private struct QuotaSection: View {
    let copy: AppCopy
    let snapshot: ProviderUsageSnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(self.copy.codingPlan)
                .font(.headline)
            ForEach(snapshot.quotaWindows) { window in
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(window.title)
                                .font(.callout.weight(.semibold))
                            Text(self.copy.windowUsage(window))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text(window.usedPercent.map { "\(Int($0.rounded()))%" } ?? "—")
                            .font(.callout.weight(.semibold))
                    }
                    ProgressView(value: (window.usedPercent ?? 0) / 100)
                        .progressViewStyle(.linear)
                }
                .padding(14)
                .background(Color.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
        }
        .padding(18)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

private struct CredentialCard: View {
    let copy: AppCopy
    let provider: ProviderDescriptor
    @Binding var apiKey: String
    @Binding var displayName: String
    let save: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(self.copy.localCredential)
                .font(.headline)
            Text(self.copy.credentialHelp)
                .font(.callout)
                .foregroundStyle(.secondary)
            HStack(spacing: 12) {
                TextField(self.copy.accountName, text: self.$displayName)
                    .textFieldStyle(.roundedBorder)
                SecureField(self.provider.authMethods.contains(.accessKeySecret) ? self.copy.apiOrAccessKey : self.copy.apiKey, text: self.$apiKey)
                    .textFieldStyle(.roundedBorder)
                Button {
                    self.save()
                } label: {
                    Label(self.copy.saveKey, systemImage: "key")
                }
                .disabled(self.apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding(18)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

private struct ProviderNotesCard: View {
    let copy: AppCopy
    let provider: ProviderDescriptor
    let error: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(self.copy.providerNotes)
                .font(.headline)
            Text(self.provider.implementationNote.isEmpty ? self.copy.defaultProviderNote(self.provider) : self.provider.implementationNote)
                .foregroundStyle(.secondary)
            if let error {
                Text(error)
                    .foregroundStyle(.orange)
                    .textSelection(.enabled)
            }
            if let docsURL = provider.docsURL {
                Link(self.copy.providerDocs, destination: docsURL)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

struct AppCopy {
    let language: String

    var refresh: String { self.pick("Refresh", "刷新") }
    var settings: String { self.pick("Settings", "设置") }
    var activeAccounts: String { self.pick("Active Accounts", "已启用账户") }
    var providerCatalog: String { self.pick("Provider Catalog", "厂商目录") }
    var providers: String { self.pick("Providers", "厂商") }
    var providersSubtitle: String { self.pick("Enable the providers you want to track from the menu bar.", "启用需要在菜单栏追踪的模型厂商。") }
    var privacy: String { self.pick("Privacy", "隐私") }
    var privacySubtitle: String { self.pick("All credentials, configuration, and account data stay on this Mac.", "所有凭据、配置和账户数据都保留在这台 Mac。") }
    var about: String { self.pick("About", "关于") }
    var aboutSubtitle: String { self.pick("100% local data tracking for AI API accounts.", "AI API 账户数据 100% 本地追踪。") }
    var aboutBody: String { self.pick("TokenManager is a native macOS menu bar app for balances, quotas, usage, and coding plans across mainstream AI providers. It has no project server: keys stay in macOS Keychain, settings stay on disk, and refresh requests go directly from your Mac to the providers you enable.", "TokenManager 是原生 macOS 菜单栏应用，用于追踪主流 AI 厂商的余额、额度、用量与 Coding Plan。项目没有服务器：密钥保存在 macOS 钥匙串，设置保留在本机磁盘，刷新请求只会从你的 Mac 直接发往已启用的厂商。") }
    var languageLabel: String { self.pick("Language", "语言") }
    var localOnly: String { self.pick("100% local", "100% 本地") }
    var selectProvider: String { self.pick("Select a provider", "选择厂商") }
    var liveRefresh: String { self.pick("Live refresh", "实时刷新") }
    var manualReady: String { self.pick("Manual ready", "可手动记录") }
    var keychainOnly: String { self.pick("Keychain", "钥匙串") }
    var keychainPrivacy: String { self.pick("API keys and access tokens are stored in macOS Keychain only.", "API Key 和访问令牌仅保存到 macOS 钥匙串。") }
    var configPath: String { self.pick("Config path", "配置路径") }
    var directProviderCalls: String { self.pick("Direct provider calls", "直连厂商 API") }
    var directProviderCallsBody: String { self.pick("There is no project server. Refresh calls go from this Mac to enabled provider APIs.", "项目没有服务器。刷新请求从这台 Mac 直接发往已启用的厂商 API。") }
    var noSnapshot: String { self.pick("No snapshot", "暂无快照") }
    var pending: String { self.pick("Pending", "待刷新") }
    var noAccounts: String { self.pick("No accounts", "暂无账户") }
    var addProviderKeys: String { self.pick("Add provider keys in Settings.", "请在设置中添加厂商密钥。") }
    var openDashboard: String { self.pick("Dashboard", "控制台") }
    var open: String { self.pick("Open", "打开") }
    var quit: String { self.pick("Quit", "退出") }
    var balance: String { self.pick("Balance", "余额") }
    var usage: String { self.pick("Usage", "用量") }
    var limit: String { self.pick("Limit", "额度") }
    var metrics: String { self.pick("Metrics", "指标") }
    var source: String { self.pick("Source", "来源") }
    var waitingForKey: String { self.pick("Waiting for local key", "等待本地密钥") }
    var codingPlan: String { self.pick("Coding Plan", "Coding Plan 额度") }
    var localCredential: String { self.pick("Local credential", "本地凭据") }
    var credentialHelp: String { self.pick("Keys are saved in macOS Keychain. The config stores only references.", "密钥保存到 macOS 钥匙串，配置文件只保存引用。") }
    var accountName: String { self.pick("Account name", "账户名称") }
    var apiKey: String { self.pick("API key", "API Key") }
    var apiOrAccessKey: String { self.pick("API key / access token", "API Key / 访问令牌") }
    var saveKey: String { self.pick("Save Key", "保存密钥") }
    var providerNotes: String { self.pick("Provider notes", "厂商说明") }
    var providerDocs: String { self.pick("Provider API docs", "厂商 API 文档") }

    func providerSubtitle(_ provider: ProviderDescriptor) -> String {
        provider.supportsLiveRefresh
            ? self.pick("Connect a local key to refresh usage.", "连接本地密钥即可刷新用量。")
            : self.pick("Catalog-ready; live adapter planned.", "目录已支持，实时适配器待接入。")
    }

    func menuSubtitle(_ count: Int) -> String {
        count == 1
            ? self.pick("1 active account", "1 个已启用账户")
            : self.pick("\(count) active accounts", "\(count) 个已启用账户")
    }

    func windowUsage(_ window: QuotaWindow) -> String {
        let used = window.used.map { NSDecimalNumber(decimal: $0).stringValue } ?? "—"
        let limit = window.limit.map { NSDecimalNumber(decimal: $0).stringValue } ?? "—"
        return self.pick("\(used) of \(limit) \(window.unit)", "\(used) / \(limit) \(window.unit)")
    }

    func defaultProviderNote(_ provider: ProviderDescriptor) -> String {
        provider.supportsLiveRefresh
            ? self.pick("This provider has a live API adapter.", "该厂商已支持实时 API 适配。")
            : self.pick("This provider is available for local tracking while a live adapter is added.", "该厂商可用于本地记录，实时适配器可在同一架构下补充。")
    }

    private func pick(_ english: String, _ chinese: String) -> String {
        self.language.hasPrefix("zh") ? chinese : english
    }
}
