import SwiftUI
import TokenManagerCore

struct SettingsView: View {
    @EnvironmentObject private var model: TokenManagerAppModel
    @AppStorage("appLanguage") private var appLanguage = "zh-Hans"

    private var copy: AppCopy {
        AppCopy(language: self.appLanguage)
    }

    private var selectedProvider: ProviderDescriptor? {
        if let selectedProviderID = self.model.selectedProviderID,
           let provider = self.model.catalog.provider(id: selectedProviderID)
        {
            return provider
        }
        return self.model.catalog.providers.first
    }

    var body: some View {
        TabView {
            self.providerSettings
                .tabItem {
                    Label(self.copy.providers, systemImage: "square.stack.3d.up")
                }
            self.privacySettings
                .tabItem {
                    Label(self.copy.privacy, systemImage: "lock.shield")
                }
            self.aboutSettings
                .tabItem {
                    Label(self.copy.about, systemImage: "info.circle")
                }
        }
        .padding(20)
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private var providerSettings: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 12) {
                SettingsHeader(
                    title: self.copy.providers,
                    subtitle: self.copy.providersSubtitle,
                    symbol: "square.stack.3d.up")

                List(selection: Binding<ProviderID?>(
                    get: { self.model.selectedProviderID ?? self.model.catalog.providers.first?.id },
                    set: { self.model.selectedProviderID = $0 }))
                {
                    ForEach(self.model.catalog.providers) { provider in
                        ProviderSettingsListRow(provider: provider)
                            .tag(provider.id)
                    }
                }
                .listStyle(.sidebar)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
            .frame(width: 280)

            if let provider = self.selectedProvider {
                ProviderConnectionPane(provider: provider, copy: self.copy)
            }
        }
        .onAppear {
            if self.model.selectedProviderID == nil {
                self.model.selectedProviderID = self.model.catalog.providers.first?.id
            }
        }
    }

    private var privacySettings: some View {
        VStack(alignment: .leading, spacing: 16) {
            SettingsHeader(
                title: self.copy.privacy,
                subtitle: self.copy.privacySubtitle,
                symbol: "lock.shield")

            VStack(alignment: .leading, spacing: 14) {
                PrivacyRow(symbol: "key.fill", title: self.copy.keychainOnly, detail: self.copy.keychainPrivacy)
                PrivacyRow(symbol: "folder.fill", title: self.copy.configPath, detail: TokenManagerConfigStore.default.url.path)
                PrivacyRow(symbol: "network", title: self.copy.directProviderCalls, detail: self.copy.directProviderCallsBody)
            }
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8, style: .continuous))

            Spacer()
        }
    }

    private var aboutSettings: some View {
        VStack(alignment: .leading, spacing: 18) {
            SettingsHeader(
                title: "TokenManager",
                subtitle: self.copy.aboutSubtitle,
                symbol: "chart.bar.xaxis")

            VStack(alignment: .leading, spacing: 12) {
                HStack {
                Text(self.copy.languageLabel)
                        .font(.headline)
                    Spacer()
                    Picker("", selection: self.$appLanguage) {
                        Text("中文").tag("zh-Hans")
                        Text("English").tag("en")
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 180)
                }

                Divider()

                Text(self.copy.aboutBody)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: 8, style: .continuous).fill(.regularMaterial))

            Spacer()
        }
    }
}

private struct SettingsHeader: View {
    let title: String
    let subtitle: String
    let symbol: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: self.symbol)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(Color.accentColor)
                .frame(width: 42, height: 42)
                .background(Color.accentColor.opacity(0.12), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            VStack(alignment: .leading, spacing: 3) {
                Text(self.title)
                    .font(.title3.weight(.semibold))
                Text(self.subtitle)
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
    }
}

private struct ProviderSettingsListRow: View {
    @EnvironmentObject private var model: TokenManagerAppModel
    @AppStorage("appLanguage") private var appLanguage = "zh-Hans"
    let provider: ProviderDescriptor

    private var copy: AppCopy {
        AppCopy(language: self.appLanguage)
    }

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(self.statusColor.opacity(0.14))
                Image(systemName: self.statusSymbol)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(self.statusColor)
            }
            .frame(width: 28, height: 28)

            VStack(alignment: .leading, spacing: 3) {
                Text(self.provider.displayName)
                    .font(.callout.weight(.semibold))
                Text(self.detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()
        }
        .padding(.vertical, 4)
    }

    private var statusSymbol: String {
        if self.model.errors[self.provider.id] != nil { return "exclamationmark.triangle.fill" }
        if self.model.hasCredential(self.provider.id) { return "key.fill" }
        return self.provider.supportsLiveRefresh ? "bolt.fill" : "tray.and.arrow.down"
    }

    private var statusColor: Color {
        if self.model.errors[self.provider.id] != nil { return .orange }
        if self.model.hasCredential(self.provider.id) { return .green }
        return self.provider.supportsLiveRefresh ? .blue : .secondary
    }

    private var detail: String {
        let metrics = self.provider.supportedMetrics
            .map(\.rawValue)
            .sorted()
            .joined(separator: " · ")
        let refresh: String
        if self.model.hasCredential(self.provider.id) {
            refresh = self.copy.savedCredential
        } else {
            refresh = self.provider.supportsLiveRefresh ? self.copy.liveRefresh : self.copy.manualReady
        }
        return "\(refresh) · \(self.provider.credentialLabel) · \(metrics)"
    }
}

private struct ProviderConnectionPane: View {
    @EnvironmentObject private var model: TokenManagerAppModel
    let provider: ProviderDescriptor
    let copy: AppCopy
    @State private var accountName = ""
    @State private var apiKey = ""
    @State private var isSaving = false
    @State private var isRefreshing = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: self.provider.supportsLiveRefresh ? "bolt.fill" : "tray.and.arrow.down")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(self.provider.supportsLiveRefresh ? .green : .secondary)
                    .frame(width: 42, height: 42)
                    .background(Color.secondary.opacity(0.10), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                VStack(alignment: .leading, spacing: 4) {
                    Text(self.provider.displayName)
                        .font(.title3.weight(.semibold))
                    Text(self.provider.implementationNote.isEmpty ? self.copy.defaultProviderNote(self.provider) : self.provider.implementationNote)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer()
            }

            Divider()

            Toggle(self.copy.menuBarTracking, isOn: Binding(
                get: { self.model.isEnabled(self.provider.id) },
                set: { self.model.setEnabled($0, providerID: self.provider.id) }))
            .toggleStyle(.switch)

            VStack(alignment: .leading, spacing: 8) {
                Text(self.copy.localCredential)
                    .font(.headline)
                Text(self.provider.supportsLiveRefresh ? self.copy.pasteKeyPrompt(self.provider) : self.copy.liveAdapterUnavailable)
                    .font(.callout)
                    .foregroundStyle(.secondary)

                TextField(self.copy.accountName, text: self.$accountName)
                    .textFieldStyle(.roundedBorder)

                SecureField(
                    self.copy.credentialPlaceholder(self.provider),
                    text: self.$apiKey)
                    .textFieldStyle(.roundedBorder)
                    .disabled(!self.provider.supportsLiveRefresh)

                HStack {
                    Button {
                        Task { await self.saveAndRefresh() }
                    } label: {
                        Label(self.copy.saveKey, systemImage: "key.fill")
                    }
                    .disabled(!self.canSave)

                    Button {
                        Task { await self.refresh() }
                    } label: {
                        Label(self.copy.refreshBalance, systemImage: "arrow.clockwise")
                    }
                    .disabled(!self.canRefresh)

                    Spacer()
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text(self.copy.latestResult)
                    .font(.headline)
                ProviderConnectionStatus(provider: self.provider, copy: self.copy)
                if let endpoint = self.provider.endpoint {
                    Label(endpoint.url.absoluteString, systemImage: "network")
                        .font(.caption.monospaced())
                        .foregroundStyle(.secondary)
                        .textSelection(.enabled)
                        .lineLimit(2)
                }
                if let dashboardURL = self.provider.dashboardURL {
                    Link(destination: dashboardURL) {
                        Label(self.copy.openDashboard, systemImage: "safari")
                    }
                }
                if let guideURL = self.provider.guideURL {
                    Link(destination: guideURL) {
                        Label(self.copy.providerGuide, systemImage: "book")
                    }
                }
                if let docsURL = self.provider.docsURL {
                    Link(destination: docsURL) {
                        Label(self.copy.providerDocs, systemImage: "doc.text")
                    }
                }
            }

            Spacer()
        }
        .padding(18)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .onAppear(perform: self.resetFields)
        .onChange(of: self.provider.id) { _, _ in self.resetFields() }
    }

    private var canSave: Bool {
        self.provider.supportsLiveRefresh
            && !self.isSaving
            && !self.apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var canRefresh: Bool {
        self.provider.supportsLiveRefresh
            && !self.isRefreshing
            && self.model.hasCredential(self.provider.id)
    }

    private func resetFields() {
        self.accountName = self.model.account(for: self.provider.id)?.displayName ?? "\(self.provider.shortName) account"
        self.apiKey = ""
    }

    @MainActor
    private func saveAndRefresh() async {
        self.isSaving = true
        defer { self.isSaving = false }
        await self.model.saveAPIKey(self.apiKey, providerID: self.provider.id, displayName: self.accountName)
        self.apiKey = ""
    }

    @MainActor
    private func refresh() async {
        self.isRefreshing = true
        defer { self.isRefreshing = false }
        await self.model.refresh(providerID: self.provider.id)
    }
}

private struct ProviderConnectionStatus: View {
    @EnvironmentObject private var model: TokenManagerAppModel
    let provider: ProviderDescriptor
    let copy: AppCopy

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(self.credentialText, systemImage: self.model.hasCredential(self.provider.id) ? "key.fill" : "key")
                .foregroundStyle(self.model.hasCredential(self.provider.id) ? .green : .secondary)
            if let snapshot = self.model.snapshots[self.provider.id] {
                if let balance = snapshot.balance {
                    Label(balance.displayString, systemImage: "creditcard")
                        .foregroundStyle(.primary)
                }
                ForEach(snapshot.breakdown, id: \.label) { item in
                    Text("\(item.label): \(item.currency) \(NSDecimalNumber(decimal: item.amount).stringValue)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .textSelection(.enabled)
                }
                ForEach(snapshot.quotaWindows) { window in
                    Text("\(window.title): \(self.copy.windowUsage(window))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .textSelection(.enabled)
                }
            }
            if let error = self.model.errors[self.provider.id] {
                Label(error, systemImage: "exclamationmark.triangle.fill")
                    .foregroundStyle(.orange)
                    .textSelection(.enabled)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .font(.callout)
    }

    private var credentialText: String {
        self.model.hasCredential(self.provider.id) ? self.copy.savedCredential : self.copy.noCredential
    }
}

private struct PrivacyRow: View {
    let symbol: String
    let title: String
    let detail: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: self.symbol)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Color.accentColor)
                .frame(width: 28, height: 28)
                .background(Color.accentColor.opacity(0.10), in: RoundedRectangle(cornerRadius: 6, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text(self.title)
                    .font(.headline)
                Text(self.detail)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .textSelection(.enabled)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}
