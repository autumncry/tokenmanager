import Foundation
import XCTest
@testable import TokenManagerCore

final class ProviderBalanceClientTests: XCTestCase {
    func testRefreshesDeepSeekBalanceFromInlineAPIKey() async throws {
        let loader = RecordingHTTPDataLoader(data: """
        {
          "is_available": true,
          "balance_infos": [
            {
              "currency": "CNY",
              "total_balance": "66.60",
              "granted_balance": "6.60",
              "topped_up_balance": "60.00"
            }
          ]
        }
        """.data(using: .utf8)!)
        let client = ProviderBalanceClient(
            credentialStore: InMemoryCredentialStore(),
            httpClient: loader)

        let snapshot = try await client.refresh(
            providerID: .deepSeek,
            apiKey: "sk-test-inline",
            displayName: "DeepSeek test")

        XCTAssertEqual(snapshot.balance?.amount, Decimal(string: "66.60"))
        XCTAssertEqual(snapshot.balance?.currency, "CNY")
        XCTAssertEqual(loader.requests.count, 1)
        XCTAssertEqual(loader.requests.first?.url?.absoluteString, "https://api.deepseek.com/user/balance")
        XCTAssertEqual(loader.requests.first?.value(forHTTPHeaderField: "Authorization"), "Bearer sk-test-inline")
    }

    func testRefreshesMiniMaxCodingPlanFromInlineAPIKey() async throws {
        let loader = RecordingHTTPDataLoader(data: """
        {
          "data": {
            "model": "MiniMax-M2.7",
            "current_interval_total_count": 100,
            "current_interval_usage_count": 75
          }
        }
        """.data(using: .utf8)!)
        let client = ProviderBalanceClient(
            credentialStore: InMemoryCredentialStore(),
            httpClient: loader)

        let snapshot = try await client.refresh(
            providerID: .miniMax,
            apiKey: "sk-test-minimax",
            displayName: "MiniMax test")

        XCTAssertEqual(snapshot.quotaWindows.first?.used, Decimal(25))
        XCTAssertEqual(loader.requests.count, 1)
        XCTAssertEqual(loader.requests.first?.url?.absoluteString, "https://api.minimaxi.com/v1/token_plan/remains")
        XCTAssertEqual(loader.requests.first?.value(forHTTPHeaderField: "Authorization"), "Bearer sk-test-minimax")
    }
}

private final class RecordingHTTPDataLoader: HTTPDataLoading, @unchecked Sendable {
    private let data: Data
    private(set) var requests: [URLRequest] = []

    init(data: Data) {
        self.data = data
    }

    func data(for request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        self.requests.append(request)
        let response = HTTPURLResponse(
            url: request.url!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil)!
        return (self.data, response)
    }
}
