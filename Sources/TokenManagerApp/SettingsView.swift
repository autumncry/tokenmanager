import SwiftUI
import TokenManagerCore

struct SettingsView: View {
    @EnvironmentObject private var model: TokenManagerAppModel

    var body: some View {
        TabView {
            providerSettings
                .tabItem {
                    Label("Providers", systemImage: "square.stack.3d.up")
                }
            privacySettings
                .tabItem {
                    Label("Privacy", systemImage: "lock.shield")
                }
        }
        .padding(20)
    }

    private var providerSettings: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Providers")
                .font(.title3.weight(.semibold))
            List {
                ForEach(self.model.catalog.providers) { provider in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(provider.displayName)
                            Text(provider.supportsLiveRefresh ? "Live refresh available" : "Manual/local tracking")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Toggle("", isOn: Binding(
                            get: { self.model.isEnabled(provider.id) },
                            set: { self.model.setEnabled($0, providerID: provider.id) }))
                    }
                }
            }
        }
    }

    private var privacySettings: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Privacy")
                .font(.title3.weight(.semibold))
            Text("TokenManager has no project server. Provider credentials are stored in macOS Keychain, provider settings are stored in ~/.config/tokenmanager/config.json, and refresh calls go directly from this Mac to the provider APIs you enable.")
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            Text("Config path")
                .font(.headline)
            Text(TokenManagerConfigStore.default.url.path)
                .font(.system(.callout, design: .monospaced))
                .textSelection(.enabled)
            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
