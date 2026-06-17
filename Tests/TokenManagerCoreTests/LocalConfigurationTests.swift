import XCTest
@testable import TokenManagerCore

final class LocalConfigurationTests: XCTestCase {
    func testConfigEncodingDoesNotPersistSecretValues() throws {
        let account = ProviderAccount(
            id: UUID(uuidString: "11111111-1111-1111-1111-111111111111")!,
            providerID: .deepSeek,
            displayName: "DeepSeek personal",
            credentialReference: .keychain(service: "app.tokenmanager.credentials", account: "deepseek.personal"),
            isEnabled: true,
            refreshInterval: .minutes(15),
            baseURLOverride: nil,
            notes: "primary key")

        let config = TokenManagerConfig(accounts: [account])
        let data = try JSONEncoder.tokenManager.encode(config)
        let json = String(decoding: data, as: UTF8.self)

        XCTAssertTrue(json.contains("deepseek.personal"))
        XCTAssertFalse(json.contains("sk-"))
        XCTAssertFalse(json.localizedCaseInsensitiveContains("apiKey"))
        XCTAssertFalse(json.localizedCaseInsensitiveContains("secret"))
    }

    func testInMemoryCredentialStoreRoundTripsSecretsOutsideConfig() async throws {
        let store = InMemoryCredentialStore()
        let reference = CredentialReference.keychain(
            service: "app.tokenmanager.credentials",
            account: "moonshot.personal")

        try await store.save("sk-local-secret", for: reference)

        let loaded = try await store.load(reference)
        XCTAssertEqual(loaded, "sk-local-secret")
    }
}
