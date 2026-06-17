import Foundation

public enum ProviderID: String, CaseIterable, Codable, Hashable, Identifiable, Sendable {
    case openAI = "openai"
    case anthropic
    case googleGemini = "google-gemini"
    case xAI = "xai"
    case mistral
    case openRouter = "openrouter"
    case groq
    case togetherAI = "together-ai"
    case cohere
    case azureOpenAI = "azure-openai"
    case awsBedrock = "aws-bedrock"

    case deepSeek = "deepseek"
    case alibabaBailian = "alibaba-bailian"
    case volcengineArk = "volcengine-ark"
    case zhipuBigModel = "zhipu-bigmodel"
    case moonshotKimi = "moonshot-kimi"
    case baiduQianfan = "baidu-qianfan"
    case tencentHunyuan = "tencent-hunyuan"
    case siliconFlow = "siliconflow"
    case miniMax = "minimax"
    case stepFun = "stepfun"
    case baichuan = "baichuan"
    case modelScope = "modelscope"

    public var id: String { self.rawValue }
}

public enum MetricKind: String, CaseIterable, Codable, Hashable, Sendable {
    case balance
    case spend
    case usage
    case quota
    case codingPlan
    case rateLimit
}

public enum AuthMethod: String, CaseIterable, Codable, Hashable, Sendable {
    case apiKeyBearer
    case accessKeySecret
    case oauth
    case browserSession
    case manual
}

public struct MoneyAmount: Codable, Equatable, Hashable, Sendable {
    public let amount: Decimal
    public let currency: String

    public init(amount: Decimal, currency: String) {
        self.amount = amount
        self.currency = currency
    }
}

public struct BalanceBreakdown: Codable, Equatable, Hashable, Sendable {
    public let label: String
    public let amount: Decimal
    public let currency: String

    public init(label: String, amount: Decimal, currency: String) {
        self.label = label
        self.amount = amount
        self.currency = currency
    }
}

public struct QuotaWindow: Codable, Equatable, Hashable, Sendable, Identifiable {
    public let id: String
    public let title: String
    public let used: Decimal?
    public let limit: Decimal?
    public let unit: String
    public let resetsAt: Date?

    public init(
        id: String,
        title: String,
        used: Decimal?,
        limit: Decimal?,
        unit: String,
        resetsAt: Date?)
    {
        self.id = id
        self.title = title
        self.used = used
        self.limit = limit
        self.unit = unit
        self.resetsAt = resetsAt
    }

    public var usedPercent: Double? {
        guard
            let used,
            let limit,
            limit > 0
        else {
            return nil
        }
        let usedDouble = NSDecimalNumber(decimal: used).doubleValue
        let limitDouble = NSDecimalNumber(decimal: limit).doubleValue
        return min(100, max(0, (usedDouble / limitDouble) * 100))
    }
}

public struct ProviderUsageSnapshot: Codable, Equatable, Sendable, Identifiable {
    public var id: ProviderID { self.providerID }

    public let providerID: ProviderID
    public let accountName: String?
    public let balance: MoneyAmount?
    public let usage: MoneyAmount?
    public let limit: MoneyAmount?
    public let breakdown: [BalanceBreakdown]
    public let quotaWindows: [QuotaWindow]
    public let isAvailable: Bool
    public let source: String
    public let updatedAt: Date

    public init(
        providerID: ProviderID,
        accountName: String?,
        balance: MoneyAmount?,
        usage: MoneyAmount? = nil,
        limit: MoneyAmount? = nil,
        breakdown: [BalanceBreakdown] = [],
        quotaWindows: [QuotaWindow] = [],
        isAvailable: Bool = true,
        source: String,
        updatedAt: Date = Date())
    {
        self.providerID = providerID
        self.accountName = accountName
        self.balance = balance
        self.usage = usage
        self.limit = limit
        self.breakdown = breakdown
        self.quotaWindows = quotaWindows
        self.isAvailable = isAvailable
        self.source = source
        self.updatedAt = updatedAt
    }
}

public enum RefreshInterval: Codable, Equatable, Hashable, Sendable {
    case manual
    case minutes(Int)

    private enum CodingKeys: String, CodingKey {
        case kind
        case minutes
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let kind = try container.decode(String.self, forKey: .kind)
        switch kind {
        case "manual":
            self = .manual
        case "minutes":
            self = .minutes(try container.decode(Int.self, forKey: .minutes))
        default:
            self = .manual
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .manual:
            try container.encode("manual", forKey: .kind)
        case let .minutes(value):
            try container.encode("minutes", forKey: .kind)
            try container.encode(value, forKey: .minutes)
        }
    }
}

public enum CredentialReference: Codable, Equatable, Hashable, Sendable {
    case keychain(service: String, account: String)

    private enum CodingKeys: String, CodingKey {
        case kind
        case service
        case account
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let kind = try container.decode(String.self, forKey: .kind)
        switch kind {
        case "keychain":
            self = .keychain(
                service: try container.decode(String.self, forKey: .service),
                account: try container.decode(String.self, forKey: .account))
        default:
            throw DecodingError.dataCorruptedError(
                forKey: .kind,
                in: container,
                debugDescription: "Unsupported credential reference kind: \(kind)")
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case let .keychain(service, account):
            try container.encode("keychain", forKey: .kind)
            try container.encode(service, forKey: .service)
            try container.encode(account, forKey: .account)
        }
    }
}

public struct ProviderAccount: Codable, Equatable, Identifiable, Sendable {
    public let id: UUID
    public var providerID: ProviderID
    public var displayName: String
    public var credentialReference: CredentialReference?
    public var isEnabled: Bool
    public var refreshInterval: RefreshInterval
    public var baseURLOverride: URL?
    public var notes: String?

    public init(
        id: UUID = UUID(),
        providerID: ProviderID,
        displayName: String,
        credentialReference: CredentialReference?,
        isEnabled: Bool,
        refreshInterval: RefreshInterval,
        baseURLOverride: URL?,
        notes: String?)
    {
        self.id = id
        self.providerID = providerID
        self.displayName = displayName
        self.credentialReference = credentialReference
        self.isEnabled = isEnabled
        self.refreshInterval = refreshInterval
        self.baseURLOverride = baseURLOverride
        self.notes = notes
    }
}

public struct TokenManagerConfig: Codable, Equatable, Sendable {
    public static let currentVersion = 1

    public var version: Int
    public var accounts: [ProviderAccount]

    public init(version: Int = Self.currentVersion, accounts: [ProviderAccount] = []) {
        self.version = version
        self.accounts = accounts
    }
}

public extension JSONEncoder {
    static var tokenManager: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }
}

public extension JSONDecoder {
    static var tokenManager: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}
