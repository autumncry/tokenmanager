import Foundation

public struct TokenManagerConfigStore: Sendable {
    public let url: URL

    public init(url: URL) {
        self.url = url
    }

    public static var `default`: TokenManagerConfigStore {
        let home = FileManager.default.homeDirectoryForCurrentUser
        return TokenManagerConfigStore(
            url: home.appendingPathComponent(".config/tokenmanager/config.json"))
    }

    public func load() throws -> TokenManagerConfig {
        guard FileManager.default.fileExists(atPath: self.url.path) else {
            return TokenManagerConfig()
        }
        let data = try Data(contentsOf: self.url)
        return try JSONDecoder.tokenManager.decode(TokenManagerConfig.self, from: data)
    }

    public func save(_ config: TokenManagerConfig) throws {
        let directory = self.url.deletingLastPathComponent()
        try FileManager.default.createDirectory(
            at: directory,
            withIntermediateDirectories: true,
            attributes: [.posixPermissions: 0o700])
        let data = try JSONEncoder.tokenManager.encode(config)
        try data.write(to: self.url, options: [.atomic])
        try FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: self.url.path)
    }
}
