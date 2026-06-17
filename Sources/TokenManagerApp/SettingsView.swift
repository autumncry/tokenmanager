import SwiftUI
import TokenManagerCore

struct SettingsView: View {
    @EnvironmentObject private var model: TokenManagerAppModel
    @AppStorage("appLanguage") private var appLanguage = "en"

    private var copy: AppCopy {
        AppCopy(language: self.appLanguage)
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
        VStack(alignment: .leading, spacing: 16) {
            SettingsHeader(
                title: self.copy.providers,
                subtitle: self.copy.providersSubtitle,
                symbol: "square.stack.3d.up")

            List {
                ForEach(self.model.catalog.providers) { provider in
                    ProviderSettingRow(provider: provider)
                }
            }
            .listStyle(.inset(alternatesRowBackgrounds: true))
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
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
                title: "tokenmanager",
                subtitle: self.copy.aboutSubtitle,
                symbol: "chart.bar.xaxis")

            VStack(alignment: .leading, spacing: 12) {
                HStack {
                Text(self.copy.languageLabel)
                        .font(.headline)
                    Spacer()
                    Picker("", selection: self.$appLanguage) {
                        Text("English").tag("en")
                        Text("中文").tag("zh-Hans")
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

private struct ProviderSettingRow: View {
    @EnvironmentObject private var model: TokenManagerAppModel
    @AppStorage("appLanguage") private var appLanguage = "en"
    let provider: ProviderDescriptor

    private var copy: AppCopy {
        AppCopy(language: self.appLanguage)
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: self.provider.supportsLiveRefresh ? "bolt.fill" : "tray.and.arrow.down")
                .foregroundStyle(self.provider.supportsLiveRefresh ? .green : .secondary)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 3) {
                Text(self.provider.displayName)
                    .font(.callout.weight(.semibold))
                Text(self.detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            Toggle("", isOn: Binding(
                get: { self.model.isEnabled(self.provider.id) },
                set: { self.model.setEnabled($0, providerID: self.provider.id) }))
            .toggleStyle(.switch)
        }
        .padding(.vertical, 4)
    }

    private var detail: String {
        let metrics = self.provider.supportedMetrics
            .map(\.rawValue)
            .sorted()
            .joined(separator: " · ")
        let refresh = self.provider.supportsLiveRefresh ? self.copy.liveRefresh : self.copy.manualReady
        return "\(refresh) · \(metrics)"
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
