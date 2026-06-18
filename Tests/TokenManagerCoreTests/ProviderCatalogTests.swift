import XCTest
@testable import TokenManagerCore

final class ProviderCatalogTests: XCTestCase {
    func testCatalogContainsMainstreamInternationalAndChineseProviders() {
        let providers = ProviderCatalog.default.providers
        let ids = Set(providers.map(\.id))

        XCTAssertTrue(ids.isSuperset(of: [
            .openAI,
            .anthropic,
            .googleGemini,
            .xAI,
            .mistral,
            .openRouter,
            .deepSeek,
            .alibabaBailian,
            .volcengineArk,
            .zhipuBigModel,
            .moonshotKimi,
            .baiduQianfan,
            .tencentHunyuan,
            .siliconFlow,
            .miniMax,
            .stepFun,
        ]))
    }

    func testEveryProviderHasLocalOnlyAuthAndDashboardMetadata() {
        for provider in ProviderCatalog.default.providers {
            XCTAssertFalse(provider.displayName.isEmpty, provider.id.rawValue)
            XCTAssertFalse(provider.shortName.isEmpty, provider.id.rawValue)
            XCTAssertNotNil(provider.dashboardURL, provider.id.rawValue)
            XCTAssertFalse(provider.supportedMetrics.isEmpty, provider.id.rawValue)
            XCTAssertTrue(provider.storagePolicy.contains("local"), provider.id.rawValue)
        }
    }

    func testByteDanceVolcengineProviderSupportsCodingPlanTracking() throws {
        let provider = try XCTUnwrap(ProviderCatalog.default.provider(id: .volcengineArk))

        XCTAssertEqual(provider.displayName, "Volcengine Ark / Doubao")
        XCTAssertTrue(provider.aliases.contains("bytedance"))
        XCTAssertTrue(provider.aliases.contains("doubao"))
        XCTAssertTrue(provider.supportedMetrics.contains(.codingPlan))
    }

    func testCodingPlanProvidersHaveGithubGuidesAndCredentialLabels() throws {
        let expected: [ProviderID] = [
            .codex,
            .anthropic,
            .googleGemini,
            .openCode,
            .alibabaBailian,
            .alibabaToken,
            .antigravity,
            .zAI,
            .miniMax,
            .moonshotKimi,
            .kimiK2,
            .kilo,
            .kiro,
            .openRouter,
            .deepSeek,
            .stepFun,
        ]

        for providerID in expected {
            let provider = try XCTUnwrap(ProviderCatalog.default.provider(id: providerID), providerID.rawValue)
            XCTAssertFalse(provider.credentialLabel.isEmpty, providerID.rawValue)
            XCTAssertEqual(provider.guideURL?.host(), "github.com", providerID.rawValue)
        }
    }
}
