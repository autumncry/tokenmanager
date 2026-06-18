import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

public enum ProviderBalanceClientError: LocalizedError, Sendable {
    case providerNotFound(ProviderID)
    case liveRefreshUnsupported(ProviderID)
    case missingCredential(ProviderID)
    case invalidHTTPResponse
    case httpStatus(Int, String)

    public var errorDescription: String? {
        switch self {
        case let .providerNotFound(providerID):
            "Unknown provider \(providerID.rawValue)."
        case let .liveRefreshUnsupported(providerID):
            "\(providerID.rawValue) does not have a live refresh adapter yet. Use manual tracking for now."
        case let .missingCredential(providerID):
            "Missing local credential for \(providerID.rawValue)."
        case .invalidHTTPResponse:
            "The server did not return an HTTP response."
        case let .httpStatus(status, body):
            "Provider request failed with HTTP \(status): \(body)"
        }
    }
}

public protocol HTTPDataLoading: Sendable {
    func data(for request: URLRequest) async throws -> (Data, HTTPURLResponse)
}

public struct URLSessionHTTPDataLoader: HTTPDataLoading {
    public init() {}

    public func data(for request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw ProviderBalanceClientError.invalidHTTPResponse
        }
        return (data, http)
    }
}

public struct ProviderBalanceClient: Sendable {
    public let catalog: ProviderCatalog
    public let credentialStore: any CredentialStore
    public let httpClient: any HTTPDataLoading

    public init(
        catalog: ProviderCatalog = .default,
        credentialStore: any CredentialStore,
        httpClient: any HTTPDataLoading = URLSessionHTTPDataLoader())
    {
        self.catalog = catalog
        self.credentialStore = credentialStore
        self.httpClient = httpClient
    }

    public func refresh(account: ProviderAccount) async throws -> ProviderUsageSnapshot {
        guard let provider = self.catalog.provider(id: account.providerID) else {
            throw ProviderBalanceClientError.providerNotFound(account.providerID)
        }
        guard let credentialReference = account.credentialReference else {
            throw ProviderBalanceClientError.missingCredential(account.providerID)
        }
        let secret = try await self.credentialStore.load(credentialReference)
        return try await self.refresh(provider: provider, account: account, secret: secret)
    }

    public func refresh(
        providerID: ProviderID,
        apiKey: String,
        displayName: String? = nil,
        baseURLOverride: URL? = nil) async throws -> ProviderUsageSnapshot
    {
        guard let provider = self.catalog.provider(id: providerID) else {
            throw ProviderBalanceClientError.providerNotFound(providerID)
        }
        let trimmed = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw ProviderBalanceClientError.missingCredential(providerID)
        }
        let account = ProviderAccount(
            providerID: providerID,
            displayName: displayName ?? "\(provider.shortName) account",
            credentialReference: nil,
            isEnabled: true,
            refreshInterval: .manual,
            baseURLOverride: baseURLOverride,
            notes: nil)
        return try await self.refresh(provider: provider, account: account, secret: trimmed)
    }

    private func refresh(
        provider: ProviderDescriptor,
        account: ProviderAccount,
        secret: String) async throws -> ProviderUsageSnapshot
    {
        guard let endpoint = provider.endpoint else {
            throw ProviderBalanceClientError.liveRefreshUnsupported(account.providerID)
        }
        var request = URLRequest(url: account.baseURLOverride ?? endpoint.url)
        request.httpMethod = endpoint.method
        request.setValue("Bearer \(secret)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("tokenmanager/0.1", forHTTPHeaderField: "User-Agent")

        if account.providerID == .openAI {
            let now = Int(Date().timeIntervalSince1970)
            let start = now - (30 * 24 * 60 * 60)
            var components = URLComponents(url: request.url!, resolvingAgainstBaseURL: false)
            components?.queryItems = [
                URLQueryItem(name: "start_time", value: "\(start)"),
                URLQueryItem(name: "end_time", value: "\(now)"),
                URLQueryItem(name: "limit", value: "30"),
            ]
            request.url = components?.url
        }

        let (data, response) = try await self.httpClient.data(for: request)
        guard (200..<300).contains(response.statusCode) else {
            let body = String(decoding: data.prefix(500), as: UTF8.self)
            throw ProviderBalanceClientError.httpStatus(response.statusCode, body)
        }
        return try ProviderBalanceParser.parse(providerID: account.providerID, data: data)
    }
}
