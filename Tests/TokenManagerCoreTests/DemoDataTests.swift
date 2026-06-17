import XCTest
@testable import TokenManagerCore

final class DemoDataTests: XCTestCase {
    func testDemoSnapshotsIncludeDoubaoCodingPlan() throws {
        let demo = DemoDataFactory.snapshots(now: Date(timeIntervalSince1970: 1_800_000_000))
        let doubao = try XCTUnwrap(demo.first { $0.providerID == .volcengineArk })

        XCTAssertEqual(doubao.accountName, "ByteDance Ark Workspace")
        XCTAssertTrue(doubao.quotaWindows.contains { $0.id == "coding-plan-monthly" })
        XCTAssertEqual(doubao.quotaWindows.first { $0.id == "coding-plan-monthly" }?.unit, "tokens")
        XCTAssertEqual(doubao.source, "Demo: Volcengine Ark Coding Plan")
    }

    func testVolcengineCodingPlanParserMapsQuotaWindows() throws {
        let data = """
        {
          "ResponseMetadata": { "RequestId": "20260617-demo" },
          "Result": {
            "AccountName": "team-tokenmanager",
            "PlanName": "Doubao Coding Plan Pro",
            "Currency": "CNY",
            "Balance": "268.40",
            "Windows": [
              {
                "Id": "coding-plan-monthly",
                "Title": "Monthly coding tokens",
                "Used": "7140000",
                "Limit": "12000000",
                "Unit": "tokens",
                "ResetAt": "2026-07-01T00:00:00Z"
              },
              {
                "Id": "agent-requests",
                "Title": "Agent requests",
                "Used": 184,
                "Limit": 500,
                "Unit": "requests"
              }
            ]
          }
        }
        """.data(using: .utf8)!

        let snapshot = try ProviderBalanceParser.parse(
            providerID: .volcengineArk,
            data: data,
            receivedAt: Date(timeIntervalSince1970: 1_800_000_000))

        XCTAssertEqual(snapshot.providerID, .volcengineArk)
        XCTAssertEqual(snapshot.accountName, "team-tokenmanager")
        XCTAssertEqual(snapshot.balance?.amount, Decimal(string: "268.40"))
        XCTAssertEqual(snapshot.balance?.currency, "CNY")
        XCTAssertEqual(snapshot.quotaWindows.count, 2)
        XCTAssertEqual(snapshot.quotaWindows[0].title, "Monthly coding tokens")
        XCTAssertEqual(snapshot.quotaWindows[0].usedPercent?.rounded(), 60)
    }
}
