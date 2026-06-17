import Foundation
import SwiftUI
import TokenManagerCore

@MainActor
final class TokenManagerAppModel: ObservableObject {
    @Published var config: TokenManagerConfig
    @Published var snapshots: [ProviderID: ProviderUsageSnapshot] = [:]
    @Published var errors: [ProviderID: String] = [:]
    @Published var isRefreshing = false
    @Published var selectedProviderID: ProviderID?

    let catalog = ProviderCatalog.default
    private let configStore = TokenManagerConfigStore.default
    private let credentialStore = KeychainCredentialStore()
    let isDemoMode: Bool

    init() {
        let arguments = Set(CommandLine.arguments)
        self.isDemoMode = arguments.contains("--demo") || ProcessInfo.processInfo.environment["TOKENMANAGER_DEMO_MODE"] == "1"
        if self.isDemoMode {
            self.config = DemoDataFactory.config()
            let demoSnapshots = DemoDataFactory.snapshots()
            self.snapshots = Dictionary(uniqueKeysWithValues: demoSnapshots.map { ($0.providerID, $0) })
            self.selectedProviderID = .volcengineArk
        } else {
            self.config = (try? self.configStore.load()) ?? TokenManagerConfig()
            self.selectedProviderID = self.catalog.providers.first?.id
        }
    }

    var enabledAccounts: [ProviderAccount] {
        self.config.accounts.filter(\.isEnabled)
    }

    var menuTitle: String {
        let enabled = self.enabledAccounts.count
        guard enabled > 0 else { return "tokenmanager" }
        let staleCount = self.errors.count
        if staleCount > 0 {
            return "tokenmanager \(enabled)/\(staleCount)"
        }
        return "tokenmanager \(enabled)"
    }

    func account(for providerID: ProviderID) -> ProviderAccount? {
        self.config.accounts.first { $0.providerID == providerID }
    }

    func isEnabled(_ providerID: ProviderID) -> Bool {
        self.account(for: providerID)?.isEnabled == true
    }

    func setEnabled(_ enabled: Bool, providerID: ProviderID) {
        if let index = self.config.accounts.firstIndex(where: { $0.providerID == providerID }) {
            self.config.accounts[index].isEnabled = enabled
        } else if let provider = self.catalog.provider(id: providerID) {
            self.config.accounts.append(ProviderAccount(
                providerID: providerID,
                displayName: "\(provider.shortName) account",
                credentialReference: nil,
                isEnabled: enabled,
                refreshInterval: .minutes(15),
                baseURLOverride: nil,
                notes: nil))
        }
        self.saveConfig()
    }

    func saveAPIKey(_ apiKey: String, providerID: ProviderID, displayName: String?) async {
        let trimmed = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let provider = self.catalog.provider(id: providerID)
        let accountID = self.account(for: providerID)?.id ?? UUID()
        let reference = CredentialReference.keychain(
            service: "app.tokenmanager.credentials",
            account: "\(providerID.rawValue).\(accountID.uuidString.lowercased())")
        do {
            try await self.credentialStore.save(trimmed, for: reference)
            let account = ProviderAccount(
                id: accountID,
                providerID: providerID,
                displayName: displayName?.isEmpty == false ? displayName! : "\(provider?.shortName ?? providerID.rawValue) account",
                credentialReference: reference,
                isEnabled: true,
                refreshInterval: .minutes(15),
                baseURLOverride: nil,
                notes: nil)
            self.config.accounts.removeAll { $0.providerID == providerID }
            self.config.accounts.append(account)
            self.saveConfig()
            self.errors[providerID] = nil
            await self.refresh(providerID: providerID)
        } catch {
            self.errors[providerID] = error.localizedDescription
        }
    }

    func refreshEnabledAccounts() async {
        if self.isDemoMode {
            let demoSnapshots = DemoDataFactory.snapshots()
            self.snapshots = Dictionary(uniqueKeysWithValues: demoSnapshots.map { ($0.providerID, $0) })
            return
        }
        self.isRefreshing = true
        defer { self.isRefreshing = false }
        for account in self.enabledAccounts {
            await self.refresh(account: account)
        }
    }

    func refresh(providerID: ProviderID) async {
        if self.isDemoMode {
            self.snapshots[providerID] = DemoDataFactory.snapshots().first { $0.providerID == providerID }
            return
        }
        guard let account = self.account(for: providerID) else {
            self.errors[providerID] = "Add an API key or enable manual tracking first."
            return
        }
        await self.refresh(account: account)
    }

    private func refresh(account: ProviderAccount) async {
        let client = ProviderBalanceClient(
            catalog: self.catalog,
            credentialStore: self.credentialStore)
        do {
            let snapshot = try await client.refresh(account: account)
            self.snapshots[account.providerID] = snapshot
            self.errors[account.providerID] = nil
        } catch {
            self.errors[account.providerID] = error.localizedDescription
        }
    }

    private func saveConfig() {
        do {
            try self.configStore.save(self.config)
        } catch {
            // Surface config failures in the first provider row so the menu does not silently lose state.
            if let first = self.catalog.providers.first?.id {
                self.errors[first] = error.localizedDescription
            }
        }
    }
}
