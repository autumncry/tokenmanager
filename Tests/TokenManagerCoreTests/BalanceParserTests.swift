import XCTest
@testable import TokenManagerCore

final class BalanceParserTests: XCTestCase {
    func testParsesDeepSeekBalanceResponse() throws {
        let data = """
        {
          "is_available": true,
          "balance_infos": [
            {
              "currency": "CNY",
              "total_balance": "128.50",
              "granted_balance": "28.50",
              "topped_up_balance": "100.00"
            }
          ]
        }
        """.data(using: .utf8)!

        let snapshot = try ProviderBalanceParser.parse(
            providerID: .deepSeek,
            data: data,
            receivedAt: Date(timeIntervalSince1970: 1_700_000_000))

        XCTAssertEqual(snapshot.providerID, .deepSeek)
        XCTAssertEqual(snapshot.balance?.amount, Decimal(string: "128.50"))
        XCTAssertEqual(snapshot.balance?.currency, "CNY")
        XCTAssertEqual(snapshot.breakdown.first?.label, "Granted")
        XCTAssertEqual(snapshot.breakdown.first?.amount, Decimal(string: "28.50"))
        XCTAssertTrue(snapshot.isAvailable)
    }

    func testParsesMoonshotBalanceResponse() throws {
        let data = """
        {
          "data": {
            "available_balance": 42.75,
            "voucher_balance": 12.25,
            "cash_balance": 30.5
          }
        }
        """.data(using: .utf8)!

        let snapshot = try ProviderBalanceParser.parse(providerID: .moonshotKimi, data: data)

        XCTAssertEqual(snapshot.balance?.amount, Decimal(string: "42.75"))
        XCTAssertEqual(snapshot.balance?.currency, "CNY")
        XCTAssertEqual(snapshot.breakdown.map(\.label), ["Voucher", "Cash"])
    }

    func testParsesSiliconFlowUserInfoResponse() throws {
        let data = """
        {
          "code": 20000,
          "message": "OK",
          "status": true,
          "data": {
            "name": "demo",
            "email": "demo@example.com",
            "balance": "0.88",
            "chargeBalance": "88.00",
            "totalBalance": "88.88"
          }
        }
        """.data(using: .utf8)!

        let snapshot = try ProviderBalanceParser.parse(providerID: .siliconFlow, data: data)

        XCTAssertEqual(snapshot.accountName, "demo@example.com")
        XCTAssertEqual(snapshot.balance?.amount, Decimal(string: "88.88"))
        XCTAssertEqual(snapshot.breakdown.map(\.label), ["Free balance", "Charged balance"])
    }

    func testParsesOpenRouterCreditsResponse() throws {
        let data = """
        {
          "data": {
            "total_credits": 100,
            "total_usage": 37.42
          }
        }
        """.data(using: .utf8)!

        let snapshot = try ProviderBalanceParser.parse(providerID: .openRouter, data: data)

        XCTAssertEqual(snapshot.balance?.amount, Decimal(string: "62.58"))
        XCTAssertEqual(snapshot.usage?.amount, Decimal(string: "37.42"))
        XCTAssertEqual(snapshot.limit?.amount, Decimal(string: "100"))
        XCTAssertEqual(snapshot.balance?.currency, "USD")
    }
}
