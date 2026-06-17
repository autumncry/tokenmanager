import Foundation

public enum ProviderBalanceParserError: LocalizedError, Equatable, Sendable {
    case invalidJSON
    case unsupportedProvider(ProviderID)
    case missingExpectedFields(ProviderID)

    public var errorDescription: String? {
        switch self {
        case .invalidJSON:
            "The provider returned invalid JSON."
        case let .unsupportedProvider(providerID):
            "No parser is available for \(providerID.rawValue)."
        case let .missingExpectedFields(providerID):
            "The response did not contain the expected \(providerID.rawValue) balance fields."
        }
    }
}

public enum ProviderBalanceParser {
    public static func parse(
        providerID: ProviderID,
        data: Data,
        receivedAt: Date = Date()) throws -> ProviderUsageSnapshot
    {
        let json = try self.object(from: data)
        switch providerID {
        case .deepSeek:
            return try self.parseDeepSeek(json, receivedAt: receivedAt)
        case .moonshotKimi:
            return try self.parseMoonshot(json, receivedAt: receivedAt)
        case .siliconFlow:
            return try self.parseSiliconFlow(json, receivedAt: receivedAt)
        case .openRouter:
            return try self.parseOpenRouter(json, receivedAt: receivedAt)
        case .openAI:
            return try self.parseOpenAICosts(json, receivedAt: receivedAt)
        case .volcengineArk:
            return try self.parseVolcengineCodingPlan(json, receivedAt: receivedAt)
        default:
            return try self.parseGeneric(providerID: providerID, json: json, receivedAt: receivedAt)
        }
    }

    private static func object(from data: Data) throws -> [String: Any] {
        guard
            let object = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        else {
            throw ProviderBalanceParserError.invalidJSON
        }
        return object
    }

    private static func parseDeepSeek(_ json: [String: Any], receivedAt: Date) throws -> ProviderUsageSnapshot {
        guard
            let infos = json["balance_infos"] as? [[String: Any]],
            let first = infos.first,
            let total = decimal(first["total_balance"])
        else {
            throw ProviderBalanceParserError.missingExpectedFields(.deepSeek)
        }
        let currency = string(first["currency"]) ?? "CNY"
        var breakdown: [BalanceBreakdown] = []
        if let granted = decimal(first["granted_balance"]) {
            breakdown.append(.init(label: "Granted", amount: granted, currency: currency))
        }
        if let toppedUp = decimal(first["topped_up_balance"]) {
            breakdown.append(.init(label: "Topped up", amount: toppedUp, currency: currency))
        }
        return ProviderUsageSnapshot(
            providerID: .deepSeek,
            accountName: nil,
            balance: .init(amount: total, currency: currency),
            breakdown: breakdown,
            isAvailable: (json["is_available"] as? Bool) ?? (total > 0),
            source: "DeepSeek balance API",
            updatedAt: receivedAt)
    }

    private static func parseMoonshot(_ json: [String: Any], receivedAt: Date) throws -> ProviderUsageSnapshot {
        let data = dictionary(json["data"]) ?? json
        guard let available = decimal(data["available_balance"] ?? data["availableBalance"] ?? data["balance"]) else {
            throw ProviderBalanceParserError.missingExpectedFields(.moonshotKimi)
        }
        let currency = string(data["currency"]) ?? "CNY"
        var breakdown: [BalanceBreakdown] = []
        if let voucher = decimal(data["voucher_balance"] ?? data["voucherBalance"]) {
            breakdown.append(.init(label: "Voucher", amount: voucher, currency: currency))
        }
        if let cash = decimal(data["cash_balance"] ?? data["cashBalance"]) {
            breakdown.append(.init(label: "Cash", amount: cash, currency: currency))
        }
        return ProviderUsageSnapshot(
            providerID: .moonshotKimi,
            accountName: string(data["email"] ?? data["name"]),
            balance: .init(amount: available, currency: currency),
            breakdown: breakdown,
            source: "Moonshot balance API",
            updatedAt: receivedAt)
    }

    private static func parseSiliconFlow(_ json: [String: Any], receivedAt: Date) throws -> ProviderUsageSnapshot {
        guard let data = dictionary(json["data"]) else {
            throw ProviderBalanceParserError.missingExpectedFields(.siliconFlow)
        }
        guard let total = decimal(data["totalBalance"] ?? data["balance"]) else {
            throw ProviderBalanceParserError.missingExpectedFields(.siliconFlow)
        }
        let currency = string(data["currency"]) ?? "CNY"
        var breakdown: [BalanceBreakdown] = []
        if let free = decimal(data["balance"]) {
            breakdown.append(.init(label: "Free balance", amount: free, currency: currency))
        }
        if let charged = decimal(data["chargeBalance"]) {
            breakdown.append(.init(label: "Charged balance", amount: charged, currency: currency))
        }
        return ProviderUsageSnapshot(
            providerID: .siliconFlow,
            accountName: string(data["email"]) ?? string(data["name"]),
            balance: .init(amount: total, currency: currency),
            breakdown: breakdown,
            isAvailable: (json["status"] as? Bool) ?? true,
            source: "SiliconFlow user info API",
            updatedAt: receivedAt)
    }

    private static func parseOpenRouter(_ json: [String: Any], receivedAt: Date) throws -> ProviderUsageSnapshot {
        let data = dictionary(json["data"]) ?? json
        guard
            let total = decimal(data["total_credits"] ?? data["totalCredits"]),
            let usage = decimal(data["total_usage"] ?? data["totalUsage"])
        else {
            throw ProviderBalanceParserError.missingExpectedFields(.openRouter)
        }
        let remaining = total - usage
        return ProviderUsageSnapshot(
            providerID: .openRouter,
            accountName: string(data["label"] ?? data["name"]),
            balance: .init(amount: remaining, currency: "USD"),
            usage: .init(amount: usage, currency: "USD"),
            limit: .init(amount: total, currency: "USD"),
            source: "OpenRouter credits API",
            updatedAt: receivedAt)
    }

    private static func parseOpenAICosts(_ json: [String: Any], receivedAt: Date) throws -> ProviderUsageSnapshot {
        let buckets = (json["data"] as? [[String: Any]]) ?? []
        var total = Decimal(0)
        for bucket in buckets {
            let results = (bucket["results"] as? [[String: Any]]) ?? []
            for result in results {
                if let amount = dictionary(result["amount"]),
                   let value = decimal(amount["value"])
                {
                    total += value
                } else if let value = decimal(result["amount"]) {
                    total += value
                }
            }
        }
        return ProviderUsageSnapshot(
            providerID: .openAI,
            accountName: nil,
            balance: nil,
            usage: .init(amount: total, currency: "USD"),
            source: "OpenAI organization costs API",
            updatedAt: receivedAt)
    }

    private static func parseVolcengineCodingPlan(_ json: [String: Any], receivedAt: Date) throws -> ProviderUsageSnapshot {
        let result = dictionary(json["Result"]) ?? dictionary(json["result"]) ?? dictionary(json["data"]) ?? json
        let currency = string(result["Currency"] ?? result["currency"]) ?? "CNY"
        let balance = decimal(result["Balance"] ?? result["balance"])
        let rawWindows = (result["Windows"] as? [[String: Any]])
            ?? (result["windows"] as? [[String: Any]])
            ?? (result["QuotaWindows"] as? [[String: Any]])
            ?? []
        let windows = rawWindows.compactMap { window -> QuotaWindow? in
            guard
                let id = string(window["Id"] ?? window["id"]),
                let title = string(window["Title"] ?? window["title"])
            else { return nil }
            return QuotaWindow(
                id: id,
                title: title,
                used: decimal(window["Used"] ?? window["used"]),
                limit: decimal(window["Limit"] ?? window["limit"]),
                unit: string(window["Unit"] ?? window["unit"]) ?? "tokens",
                resetsAt: date(window["ResetAt"] ?? window["resetAt"] ?? window["reset_at"]))
        }
        guard balance != nil || !windows.isEmpty else {
            throw ProviderBalanceParserError.missingExpectedFields(.volcengineArk)
        }
        return ProviderUsageSnapshot(
            providerID: .volcengineArk,
            accountName: string(result["AccountName"] ?? result["accountName"] ?? result["Name"] ?? result["name"]),
            balance: balance.map { MoneyAmount(amount: $0, currency: currency) },
            quotaWindows: windows,
            source: "Volcengine Ark Coding Plan API",
            updatedAt: receivedAt)
    }

    private static func parseGeneric(
        providerID: ProviderID,
        json: [String: Any],
        receivedAt: Date) throws -> ProviderUsageSnapshot
    {
        let data = dictionary(json["data"]) ?? json
        let value = decimal(data["balance"] ?? data["available_balance"] ?? data["remaining"] ?? data["totalBalance"])
        guard let value else {
            throw ProviderBalanceParserError.unsupportedProvider(providerID)
        }
        return ProviderUsageSnapshot(
            providerID: providerID,
            accountName: string(data["email"] ?? data["name"]),
            balance: .init(amount: value, currency: string(data["currency"]) ?? "USD"),
            source: "Generic balance parser",
            updatedAt: receivedAt)
    }

    private static func dictionary(_ value: Any?) -> [String: Any]? {
        value as? [String: Any]
    }

    private static func string(_ value: Any?) -> String? {
        switch value {
        case let value as String:
            value
        case let value as NSNumber:
            value.stringValue
        default:
            nil
        }
    }

    private static func decimal(_ value: Any?) -> Decimal? {
        switch value {
        case let value as Decimal:
            value
        case let value as NSDecimalNumber:
            value.decimalValue
        case let value as NSNumber:
            value.decimalValue
        case let value as String:
            Decimal(string: value.trimmingCharacters(in: .whitespacesAndNewlines))
        default:
            nil
        }
    }

    private static func date(_ value: Any?) -> Date? {
        guard let value = string(value) else { return nil }
        let formatter = ISO8601DateFormatter()
        return formatter.date(from: value)
    }
}
