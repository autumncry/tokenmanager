import Foundation
import TokenManagerCore

@main
enum TokenManagerCLI {
    static func main() async {
        do {
            try await Self.run(arguments: Array(CommandLine.arguments.dropFirst()))
        } catch {
            fputs("tokenmanagerctl: \(error.localizedDescription)\n", stderr)
            Foundation.exit(1)
        }
    }

    private static func run(arguments: [String]) async throws {
        guard let command = arguments.first else {
            Self.printHelp()
            return
        }

        switch command {
        case "providers":
            try Self.printProviders(json: arguments.contains("--json"))
        case "balance":
            try await Self.printBalance(Array(arguments.dropFirst()), json: arguments.contains("--json"))
        case "config":
            try await Self.runConfig(Array(arguments.dropFirst()))
        case "status":
            try await Self.printStatus(json: arguments.contains("--json"))
        case "help", "--help", "-h":
            Self.printHelp()
        default:
            throw CLIError.unknownCommand(command)
        }
    }

    private static func printProviders(json: Bool) throws {
        let providers = ProviderCatalog.default.providers
        if json {
            let payload = providers.map { provider in
                ProviderPayload(
                    id: provider.id.rawValue,
                    displayName: provider.displayName,
                    liveRefresh: provider.supportsLiveRefresh,
                    metrics: provider.supportedMetrics.map(\.rawValue).sorted())
            }
            let data = try JSONEncoder.tokenManager.encode(payload)
            print(String(decoding: data, as: UTF8.self))
            return
        }

        for provider in providers {
            let live = provider.supportsLiveRefresh ? "live" : "manual"
            print("\(provider.id.rawValue)\t\(provider.displayName)\t\(live)")
        }
    }

    private static func runConfig(_ arguments: [String]) async throws {
        guard let subcommand = arguments.first else {
            throw CLIError.missingArgument("config subcommand")
        }

        switch subcommand {
        case "path":
            print(TokenManagerConfigStore.default.url.path)
        case "dump":
            let config = try TokenManagerConfigStore.default.load()
            let data = try JSONEncoder.tokenManager.encode(config)
            print(String(decoding: data, as: UTF8.self))
        case "set-api-key":
            try await Self.setAPIKey(Array(arguments.dropFirst()))
        default:
            throw CLIError.unknownCommand("config \(subcommand)")
        }
    }

    private static func printBalance(_ arguments: [String], json: Bool) async throws {
        let providerName = try requiredValue(after: "--provider", in: arguments)
        let provider = try ProviderCatalog.default.resolve(providerName).orThrow(CLIError.unknownProvider(providerName))
        let client = ProviderBalanceClient(credentialStore: KeychainCredentialStore())
        let snapshot: ProviderUsageSnapshot

        if let apiKey = try Self.apiKeyArgument(in: arguments) {
            snapshot = try await client.refresh(providerID: provider.id, apiKey: apiKey)
        } else {
            let config = try TokenManagerConfigStore.default.load()
            guard let account = config.accounts.first(where: { $0.providerID == provider.id && $0.isEnabled }) else {
                throw CLIError.missingArgument("api key or saved provider account")
            }
            snapshot = try await client.refresh(account: account)
        }

        if json {
            let data = try JSONEncoder.tokenManager.encode(snapshot)
            print(String(decoding: data, as: UTF8.self))
            return
        }

        let balance = snapshot.balance.map(Self.display) ?? "—"
        print("\(provider.displayName)\t\(balance)")
        for item in snapshot.breakdown {
            print("\(item.label)\t\(item.currency) \(NSDecimalNumber(decimal: item.amount).stringValue)")
        }
    }

    private static func setAPIKey(_ arguments: [String]) async throws {
        let providerName = try requiredValue(after: "--provider", in: arguments)
        let provider = try ProviderCatalog.default.resolve(providerName).orThrow(CLIError.unknownProvider(providerName))
        let name = value(after: "--name", in: arguments) ?? "\(provider.shortName) account"
        let secret: String
        if arguments.contains("--stdin") {
            secret = String(data: FileHandle.standardInput.readDataToEndOfFile(), encoding: .utf8)?
                .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        } else {
            secret = try requiredValue(after: "--api-key", in: arguments)
        }
        guard !secret.isEmpty else {
            throw CLIError.missingArgument("api key")
        }

        var config = try TokenManagerConfigStore.default.load()
        let accountID = stableAccountID(providerID: provider.id, name: name)
        let reference = CredentialReference.keychain(
            service: "app.tokenmanager.credentials",
            account: "\(provider.id.rawValue).\(accountID.uuidString.lowercased())")
        try await KeychainCredentialStore().save(secret, for: reference)

        let account = ProviderAccount(
            id: accountID,
            providerID: provider.id,
            displayName: name,
            credentialReference: reference,
            isEnabled: true,
            refreshInterval: .minutes(15),
            baseURLOverride: nil,
            notes: nil)
        config.accounts.removeAll { $0.id == accountID }
        config.accounts.append(account)
        try TokenManagerConfigStore.default.save(config)
        print("Saved \(provider.displayName) credential to Keychain and enabled local account '\(name)'.")
    }

    private static func printStatus(json: Bool) async throws {
        let config = try TokenManagerConfigStore.default.load()
        let accounts = config.accounts.filter(\.isEnabled)
        if json {
            let data = try JSONEncoder.tokenManager.encode(accounts)
            print(String(decoding: data, as: UTF8.self))
            return
        }
        if accounts.isEmpty {
            print("No enabled accounts. Add one with tokenmanagerctl config set-api-key --provider deepseek --stdin")
            return
        }
        for account in accounts {
            let provider = ProviderCatalog.default.provider(id: account.providerID)?.displayName ?? account.providerID.rawValue
            print("\(provider)\t\(account.displayName)\tenabled")
        }
    }

    private static func printHelp() {
        print(
            """
            tokenmanagerctl

            Commands:
              providers [--json]                         List supported providers
              balance --provider <id> [--stdin|--api-key <key>] [--json]
                                                          Fetch a provider balance once
              status [--json]                            Show enabled local accounts
              config path                                Print config path
              config dump                                Print local config JSON
              config set-api-key --provider <id> --stdin  Save API key in macOS Keychain
            """)
    }

    private static func value(after flag: String, in arguments: [String]) -> String? {
        guard let index = arguments.firstIndex(of: flag) else { return nil }
        let next = arguments.index(after: index)
        guard next < arguments.endIndex else { return nil }
        return arguments[next]
    }

    private static func requiredValue(after flag: String, in arguments: [String]) throws -> String {
        guard let value = Self.value(after: flag, in: arguments) else {
            throw CLIError.missingArgument(flag)
        }
        return value
    }

    private static func apiKeyArgument(in arguments: [String]) throws -> String? {
        if arguments.contains("--stdin") {
            let value = String(data: FileHandle.standardInput.readDataToEndOfFile(), encoding: .utf8)?
                .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            guard !value.isEmpty else {
                throw CLIError.missingArgument("api key")
            }
            return value
        }
        return Self.value(after: "--api-key", in: arguments)
    }

    private static func stableAccountID(providerID: ProviderID, name: String) -> UUID {
        let raw = "\(providerID.rawValue):\(name)".utf8.reduce(UInt64(14_695_981_039_346_656_037)) { hash, byte in
            (hash ^ UInt64(byte)) &* 1_099_511_628_211
        }
        let hex = String(format: "%016llx%016llx", raw, raw.byteSwapped)
        let uuidString = "\(hex.prefix(8))-\(hex.dropFirst(8).prefix(4))-\(hex.dropFirst(12).prefix(4))-\(hex.dropFirst(16).prefix(4))-\(hex.dropFirst(20).prefix(12))"
        return UUID(uuidString: uuidString) ?? UUID()
    }

    private static func display(_ amount: MoneyAmount) -> String {
        "\(amount.currency) \(NSDecimalNumber(decimal: amount.amount).stringValue)"
    }
}

private struct ProviderPayload: Encodable {
    let id: String
    let displayName: String
    let liveRefresh: Bool
    let metrics: [String]
}

private enum CLIError: LocalizedError {
    case unknownCommand(String)
    case unknownProvider(String)
    case missingArgument(String)

    var errorDescription: String? {
        switch self {
        case let .unknownCommand(command):
            "Unknown command: \(command)"
        case let .unknownProvider(provider):
            "Unknown provider: \(provider)"
        case let .missingArgument(argument):
            "Missing argument: \(argument)"
        }
    }
}

private extension Optional {
    func orThrow(_ error: @autoclosure () -> Error) throws -> Wrapped {
        guard let value = self else { throw error() }
        return value
    }
}
