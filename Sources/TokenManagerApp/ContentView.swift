import SwiftUI
import TokenManagerCore

struct ContentView: View {
    @EnvironmentObject private var model: TokenManagerAppModel

    var body: some View {
        NavigationSplitView {
            ProviderSidebar()
        } detail: {
            ProviderDetailView(providerID: self.model.selectedProviderID)
        }
        .toolbar {
            ToolbarItem {
                Button {
                    Task { await self.model.refreshEnabledAccounts() }
                } label: {
                    Label("Refresh", systemImage: "arrow.clockwise")
                }
                .disabled(self.model.isRefreshing)
            }
            ToolbarItem {
                SettingsLink {
                    Label("Settings", systemImage: "gearshape")
                }
            }
        }
    }
}

private struct ProviderSidebar: View {
    @EnvironmentObject private var model: TokenManagerAppModel

    var body: some View {
        List(selection: self.$model.selectedProviderID) {
            Section("Providers") {
                ForEach(self.model.catalog.providers) { provider in
                    ProviderRow(provider: provider)
                        .tag(provider.id)
                }
            }
        }
        .listStyle(.sidebar)
        .navigationTitle("tokenmanager")
    }
}

private struct ProviderRow: View {
    @EnvironmentObject private var model: TokenManagerAppModel
    let provider: ProviderDescriptor

    var body: some View {
        HStack(spacing: 10) {
            Circle()
                .fill(self.model.isEnabled(self.provider.id) ? Color.accentColor : Color.secondary.opacity(0.35))
                .frame(width: 8, height: 8)
            VStack(alignment: .leading, spacing: 2) {
                Text(self.provider.shortName)
                    .font(.body)
                Text(self.provider.supportsLiveRefresh ? "Live API" : "Manual / planned")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if self.model.errors[self.provider.id] != nil {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.orange)
                    .imageScale(.small)
            }
        }
        .padding(.vertical, 3)
    }
}

private struct ProviderDetailView: View {
    @EnvironmentObject private var model: TokenManagerAppModel
    let providerID: ProviderID?
    @State private var apiKey = ""
    @State private var displayName = ""

    var body: some View {
        if let providerID, let provider = self.model.catalog.provider(id: providerID) {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    header(provider)
                    snapshot(provider)
                    credentialEditor(provider)
                    implementationNotes(provider)
                }
                .padding(24)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .navigationTitle(provider.displayName)
        } else {
            ContentUnavailableView("Select a provider", systemImage: "chart.bar.doc.horizontal")
        }
    }

    private func header(_ provider: ProviderDescriptor) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(provider.displayName)
                    .font(.title2.weight(.semibold))
                Spacer()
                Toggle("Enabled", isOn: Binding(
                    get: { self.model.isEnabled(provider.id) },
                    set: { self.model.setEnabled($0, providerID: provider.id) }))
                    .toggleStyle(.switch)
            }
            Text(provider.storagePolicy)
                .font(.callout)
                .foregroundStyle(.secondary)
            HStack {
                ForEach(provider.supportedMetrics.map(\.rawValue).sorted(), id: \.self) { metric in
                    Text(metric)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(.quaternary, in: Capsule())
                }
            }
        }
    }

    private func snapshot(_ provider: ProviderDescriptor) -> some View {
        GroupBox("Current snapshot") {
            VStack(alignment: .leading, spacing: 10) {
                if let snapshot = self.model.snapshots[provider.id] {
                    MetricLine(title: "Balance", value: snapshot.balance?.displayString ?? "Not reported")
                    MetricLine(title: "Usage", value: snapshot.usage?.displayString ?? "Not reported")
                    MetricLine(title: "Limit", value: snapshot.limit?.displayString ?? "Not reported")
                    MetricLine(title: "Source", value: snapshot.source)
                    MetricLine(title: "Updated", value: snapshot.updatedAt.formatted(date: .abbreviated, time: .shortened))
                    if !snapshot.breakdown.isEmpty {
                        Divider()
                        ForEach(snapshot.breakdown, id: \.self) { item in
                            MetricLine(title: item.label, value: MoneyAmount(amount: item.amount, currency: item.currency).displayString)
                        }
                    }
                } else {
                    Text(self.model.errors[provider.id] ?? "No data yet. Save a key and refresh, or use this provider as a local manual tracker.")
                        .foregroundStyle(.secondary)
                }
                if let error = self.model.errors[provider.id] {
                    Text(error)
                        .font(.callout)
                        .foregroundStyle(.orange)
                        .textSelection(.enabled)
                }
                HStack {
                    Button {
                        Task { await self.model.refresh(providerID: provider.id) }
                    } label: {
                        Label("Refresh", systemImage: "arrow.clockwise")
                    }
                    .disabled(!self.model.isEnabled(provider.id))
                    if let url = provider.dashboardURL {
                        Link(destination: url) {
                            Label("Dashboard", systemImage: "safari")
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 4)
        }
    }

    private func credentialEditor(_ provider: ProviderDescriptor) -> some View {
        GroupBox("Local credential") {
            VStack(alignment: .leading, spacing: 12) {
                Text("API keys are saved in macOS Keychain. The JSON config stores only a Keychain reference.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                TextField("Account name", text: self.$displayName)
                    .textFieldStyle(.roundedBorder)
                SecureField(provider.authMethods.contains(.accessKeySecret) ? "API key / access token" : "API key", text: self.$apiKey)
                    .textFieldStyle(.roundedBorder)
                HStack {
                    Button {
                        Task {
                            await self.model.saveAPIKey(self.apiKey, providerID: provider.id, displayName: self.displayName)
                            self.apiKey = ""
                        }
                    } label: {
                        Label("Save Key", systemImage: "key")
                    }
                    .disabled(self.apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    Spacer()
                }
            }
            .padding(.vertical, 4)
        }
    }

    private func implementationNotes(_ provider: ProviderDescriptor) -> some View {
        GroupBox("Provider notes") {
            VStack(alignment: .leading, spacing: 8) {
                Text(provider.supportsLiveRefresh ? "Live refresh is enabled for this provider." : "This provider is included in the catalog and can be tracked locally; a signed/live adapter can be added behind the same Provider API.")
                    .foregroundStyle(.secondary)
                if !provider.implementationNote.isEmpty {
                    Text(provider.implementationNote)
                        .foregroundStyle(.secondary)
                }
                if let docsURL = provider.docsURL {
                    Link("Provider API docs", destination: docsURL)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 4)
        }
    }
}

private struct MetricLine: View {
    let title: String
    let value: String

    var body: some View {
        HStack {
            Text(self.title)
                .foregroundStyle(.secondary)
            Spacer()
            Text(self.value)
                .textSelection(.enabled)
        }
        .font(.callout)
    }
}

private extension MoneyAmount {
    var displayString: String {
        "\(self.currency) \(NSDecimalNumber(decimal: self.amount).stringValue)"
    }
}
