import Foundation

public enum DemoDataFactory {
    public static func config() -> TokenManagerConfig {
        TokenManagerConfig(accounts: self.snapshots().map { snapshot in
            ProviderAccount(
                id: UUID(),
                providerID: snapshot.providerID,
                displayName: snapshot.accountName ?? snapshot.providerID.rawValue,
                credentialReference: nil,
                isEnabled: true,
                refreshInterval: .minutes(15),
                baseURLOverride: nil,
                notes: "Demo account")
        })
    }

    public static func snapshots(now: Date = Date()) -> [ProviderUsageSnapshot] {
        [
            ProviderUsageSnapshot(
                providerID: .volcengineArk,
                accountName: "ByteDance Ark Workspace",
                balance: MoneyAmount(amount: Decimal(string: "268.40")!, currency: "CNY"),
                usage: MoneyAmount(amount: Decimal(string: "7.14")!, currency: "M tokens"),
                limit: MoneyAmount(amount: Decimal(string: "12.00")!, currency: "M tokens"),
                breakdown: [
                    BalanceBreakdown(label: "Included credits", amount: Decimal(string: "180.00")!, currency: "CNY"),
                    BalanceBreakdown(label: "Pay-as-you-go", amount: Decimal(string: "88.40")!, currency: "CNY"),
                ],
                quotaWindows: [
                    QuotaWindow(
                        id: "coding-plan-monthly",
                        title: "Monthly coding tokens",
                        used: Decimal(string: "7140000"),
                        limit: Decimal(string: "12000000"),
                        unit: "tokens",
                        resetsAt: Calendar(identifier: .gregorian).date(from: DateComponents(year: 2026, month: 7, day: 1))),
                    QuotaWindow(
                        id: "agent-requests",
                        title: "Agent requests",
                        used: Decimal(184),
                        limit: Decimal(500),
                        unit: "requests",
                        resetsAt: nil),
                ],
                source: "Demo: Volcengine Ark Coding Plan",
                updatedAt: now),
            ProviderUsageSnapshot(
                providerID: .deepSeek,
                accountName: "DeepSeek Platform",
                balance: MoneyAmount(amount: Decimal(string: "128.50")!, currency: "CNY"),
                breakdown: [
                    BalanceBreakdown(label: "Granted", amount: Decimal(string: "28.50")!, currency: "CNY"),
                    BalanceBreakdown(label: "Topped up", amount: Decimal(string: "100.00")!, currency: "CNY"),
                ],
                source: "Demo: DeepSeek balance",
                updatedAt: now),
            ProviderUsageSnapshot(
                providerID: .openRouter,
                accountName: "OpenRouter Team",
                balance: MoneyAmount(amount: Decimal(string: "62.58")!, currency: "USD"),
                usage: MoneyAmount(amount: Decimal(string: "37.42")!, currency: "USD"),
                limit: MoneyAmount(amount: Decimal(string: "100.00")!, currency: "USD"),
                source: "Demo: OpenRouter credits",
                updatedAt: now),
            ProviderUsageSnapshot(
                providerID: .miniMax,
                accountName: "MiniMax-M2.7",
                balance: nil,
                quotaWindows: [
                    QuotaWindow(
                        id: "current-interval",
                        title: "Current interval",
                        used: Decimal(180),
                        limit: Decimal(500),
                        unit: "requests",
                        resetsAt: nil),
                    QuotaWindow(
                        id: "current-week",
                        title: "Current week",
                        used: Decimal(900),
                        limit: Decimal(5000),
                        unit: "requests",
                        resetsAt: nil),
                ],
                source: "Demo: MiniMax token plan remains",
                updatedAt: now),
            ProviderUsageSnapshot(
                providerID: .siliconFlow,
                accountName: "SiliconFlow Cloud",
                balance: MoneyAmount(amount: Decimal(string: "88.88")!, currency: "CNY"),
                breakdown: [
                    BalanceBreakdown(label: "Free balance", amount: Decimal(string: "0.88")!, currency: "CNY"),
                    BalanceBreakdown(label: "Charged balance", amount: Decimal(string: "88.00")!, currency: "CNY"),
                ],
                source: "Demo: SiliconFlow user info",
                updatedAt: now),
            ProviderUsageSnapshot(
                providerID: .moonshotKimi,
                accountName: "Moonshot Kimi API",
                balance: MoneyAmount(amount: Decimal(string: "42.75")!, currency: "CNY"),
                breakdown: [
                    BalanceBreakdown(label: "Voucher", amount: Decimal(string: "12.25")!, currency: "CNY"),
                    BalanceBreakdown(label: "Cash", amount: Decimal(string: "30.50")!, currency: "CNY"),
                ],
                source: "Demo: Moonshot balance",
                updatedAt: now),
        ]
    }
}
