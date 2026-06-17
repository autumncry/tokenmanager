import Foundation
#if os(macOS)
import Security
#endif

public enum CredentialStoreError: LocalizedError, Sendable, Equatable {
    case unsupportedReference
    case missingCredential
    case keychainFailure(Int32)

    public var errorDescription: String? {
        switch self {
        case .unsupportedReference:
            "Unsupported credential reference."
        case .missingCredential:
            "No credential is stored for this account."
        case let .keychainFailure(status):
            "Keychain operation failed with status \(status)."
        }
    }
}

public protocol CredentialStore: Sendable {
    func save(_ secret: String, for reference: CredentialReference) async throws
    func load(_ reference: CredentialReference) async throws -> String
    func delete(_ reference: CredentialReference) async throws
}

public actor InMemoryCredentialStore: CredentialStore {
    private var secrets: [CredentialReference: String] = [:]

    public init() {}

    public func save(_ secret: String, for reference: CredentialReference) async throws {
        self.secrets[reference] = secret
    }

    public func load(_ reference: CredentialReference) async throws -> String {
        guard let secret = self.secrets[reference] else {
            throw CredentialStoreError.missingCredential
        }
        return secret
    }

    public func delete(_ reference: CredentialReference) async throws {
        self.secrets.removeValue(forKey: reference)
    }
}

public struct KeychainCredentialStore: CredentialStore {
    public init() {}

    public func save(_ secret: String, for reference: CredentialReference) async throws {
        #if os(macOS)
        let parts = try Self.keychainParts(reference)
        let data = Data(secret.utf8)
        let query = Self.query(service: parts.service, account: parts.account)
        let updateStatus = SecItemUpdate(query as CFDictionary, [kSecValueData as String: data] as CFDictionary)
        if updateStatus == errSecSuccess {
            return
        }
        if updateStatus != errSecItemNotFound {
            throw CredentialStoreError.keychainFailure(updateStatus)
        }
        var addQuery = query
        addQuery[kSecValueData as String] = data
        addQuery[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        let addStatus = SecItemAdd(addQuery as CFDictionary, nil)
        guard addStatus == errSecSuccess else {
            throw CredentialStoreError.keychainFailure(addStatus)
        }
        #else
        throw CredentialStoreError.unsupportedReference
        #endif
    }

    public func load(_ reference: CredentialReference) async throws -> String {
        #if os(macOS)
        let parts = try Self.keychainParts(reference)
        var query = Self.query(service: parts.service, account: parts.account)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess else {
            if status == errSecItemNotFound {
                throw CredentialStoreError.missingCredential
            }
            throw CredentialStoreError.keychainFailure(status)
        }
        guard
            let data = result as? Data,
            let secret = String(data: data, encoding: .utf8)
        else {
            throw CredentialStoreError.missingCredential
        }
        return secret
        #else
        throw CredentialStoreError.unsupportedReference
        #endif
    }

    public func delete(_ reference: CredentialReference) async throws {
        #if os(macOS)
        let parts = try Self.keychainParts(reference)
        let status = SecItemDelete(Self.query(service: parts.service, account: parts.account) as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw CredentialStoreError.keychainFailure(status)
        }
        #else
        throw CredentialStoreError.unsupportedReference
        #endif
    }

    #if os(macOS)
    private static func keychainParts(_ reference: CredentialReference) throws -> (service: String, account: String) {
        switch reference {
        case let .keychain(service, account):
            (service, account)
        }
    }

    private static func query(service: String, account: String) -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]
    }
    #endif
}
