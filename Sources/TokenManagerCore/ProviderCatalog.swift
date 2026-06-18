import Foundation

public struct ProviderAPIEndpoint: Equatable, Hashable, Sendable {
    public let url: URL
    public let method: String
    public let sourceLabel: String

    public init(url: URL, method: String = "GET", sourceLabel: String = "api") {
        self.url = url
        self.method = method
        self.sourceLabel = sourceLabel
    }
}

public struct ProviderDescriptor: Equatable, Hashable, Identifiable, Sendable {
    public let id: ProviderID
    public let displayName: String
    public let shortName: String
    public let aliases: [String]
    public let authMethods: [AuthMethod]
    public let credentialLabel: String
    public let supportedMetrics: Set<MetricKind>
    public let dashboardURL: URL?
    public let docsURL: URL?
    public let guideURL: URL?
    public let endpoint: ProviderAPIEndpoint?
    public let storagePolicy: String
    public let implementationNote: String

    public init(
        id: ProviderID,
        displayName: String,
        shortName: String,
        aliases: [String] = [],
        authMethods: [AuthMethod],
        credentialLabel: String? = nil,
        supportedMetrics: Set<MetricKind>,
        dashboardURL: URL?,
        docsURL: URL? = nil,
        guideURL: URL? = nil,
        endpoint: ProviderAPIEndpoint? = nil,
        storagePolicy: String = "local keychain + local config only",
        implementationNote: String = "")
    {
        self.id = id
        self.displayName = displayName
        self.shortName = shortName
        self.aliases = aliases
        self.authMethods = authMethods
        self.credentialLabel = credentialLabel ?? Self.defaultCredentialLabel(for: authMethods)
        self.supportedMetrics = supportedMetrics
        self.dashboardURL = dashboardURL
        self.docsURL = docsURL
        self.guideURL = guideURL
        self.endpoint = endpoint
        self.storagePolicy = storagePolicy
        self.implementationNote = implementationNote
    }

    public var supportsLiveRefresh: Bool {
        self.endpoint != nil
    }

    private static func defaultCredentialLabel(for methods: [AuthMethod]) -> String {
        if methods.contains(.oauth) { return "OAuth" }
        if methods.contains(.browserSession) { return "Cookies / browser session" }
        if methods.contains(.accessKeySecret) { return "Access key / secret" }
        if methods.contains(.apiKeyBearer) { return "API key" }
        return "Manual"
    }
}

public struct ProviderCatalog: Sendable {
    public let providers: [ProviderDescriptor]

    public init(providers: [ProviderDescriptor]) {
        self.providers = providers
    }

    public func provider(id: ProviderID) -> ProviderDescriptor? {
        self.providers.first { $0.id == id }
    }

    public func resolve(_ name: String) -> ProviderDescriptor? {
        let normalized = name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return self.providers.first { provider in
            provider.id.rawValue == normalized
                || provider.shortName.lowercased() == normalized
                || provider.displayName.lowercased() == normalized
                || provider.aliases.contains(normalized)
        }
    }

    public static let `default` = ProviderCatalog(providers: [
        .init(
            id: .openAI,
            displayName: "OpenAI",
            shortName: "OpenAI",
            aliases: ["chatgpt"],
            authMethods: [.apiKeyBearer],
            credentialLabel: "Admin API key",
            supportedMetrics: [.spend, .usage, .balance],
            dashboardURL: url("https://platform.openai.com/usage"),
            docsURL: url("https://developers.openai.com/api/reference/resources/admin/subresources/organization/subresources/usage/methods/costs"),
            guideURL: guide("openai"),
            endpoint: .init(url: url("https://api.openai.com/v1/organization/costs")!),
            implementationNote: "Uses OpenAI Admin usage/cost APIs when the key has organization usage permissions."),
        .init(
            id: .codex,
            displayName: "Codex",
            shortName: "Codex",
            aliases: ["openai-codex", "chatgpt-codex"],
            authMethods: [.oauth, .manual],
            credentialLabel: "OAuth",
            supportedMetrics: [.usage, .quota, .codingPlan],
            dashboardURL: url("https://chatgpt.com/codex"),
            docsURL: url("https://help.openai.com/en/collections/10271793-codex"),
            guideURL: guide("codex"),
            implementationNote: "Codex plan data is catalog-ready; TokenManager keeps the OAuth/session guidance local and will add a live connector once a stable local API contract is available."),
        .init(
            id: .anthropic,
            displayName: "Claude",
            shortName: "Claude",
            aliases: ["anthropic"],
            authMethods: [.oauth, .apiKeyBearer, .manual],
            credentialLabel: "OAuth / API key",
            supportedMetrics: [.usage, .quota],
            dashboardURL: url("https://console.anthropic.com/settings/usage"),
            docsURL: url("https://platform.claude.com/docs"),
            guideURL: guide("claude")),
        .init(
            id: .googleGemini,
            displayName: "Gemini",
            shortName: "Gemini",
            aliases: ["google-ai-studio"],
            authMethods: [.apiKeyBearer, .oauth, .manual],
            credentialLabel: "OAuth / API key",
            supportedMetrics: [.usage, .quota],
            dashboardURL: url("https://aistudio.google.com/usage"),
            docsURL: url("https://ai.google.dev/gemini-api/docs"),
            guideURL: guide("gemini")),
        .init(
            id: .xAI,
            displayName: "xAI Grok",
            shortName: "xAI",
            aliases: ["grok"],
            authMethods: [.apiKeyBearer, .manual],
            supportedMetrics: [.usage, .spend],
            dashboardURL: url("https://console.x.ai")),
        .init(
            id: .mistral,
            displayName: "Mistral AI",
            shortName: "Mistral",
            authMethods: [.apiKeyBearer, .manual],
            supportedMetrics: [.usage, .spend],
            dashboardURL: url("https://console.mistral.ai/usage")),
        .init(
            id: .openRouter,
            displayName: "OpenRouter",
            shortName: "OpenRouter",
            aliases: ["or"],
            authMethods: [.apiKeyBearer],
            credentialLabel: "API key",
            supportedMetrics: [.balance, .usage, .spend],
            dashboardURL: url("https://openrouter.ai/settings/credits"),
            docsURL: url("https://openrouter.ai/docs/api/api-reference/credits/get-credits"),
            guideURL: guide("openrouter"),
            endpoint: .init(url: url("https://openrouter.ai/api/v1/credits")!),
            implementationNote: "Requires an OpenRouter management API key for credit totals."),
        .init(
            id: .openCode,
            displayName: "OpenCode",
            shortName: "OpenCode",
            aliases: ["opencode"],
            authMethods: [.browserSession, .manual],
            credentialLabel: "Cookies + Go",
            supportedMetrics: [.usage, .quota, .codingPlan],
            dashboardURL: url("https://opencode.ai"),
            docsURL: url("https://opencode.ai/docs"),
            guideURL: guide("opencode"),
            implementationNote: "OpenCode usage is catalog-ready. Use the guide to capture the local session shape; no TokenManager server or proxy is involved."),
        .init(
            id: .groq,
            displayName: "GroqCloud",
            shortName: "Groq",
            authMethods: [.apiKeyBearer, .manual],
            supportedMetrics: [.usage, .rateLimit],
            dashboardURL: url("https://console.groq.com/settings/usage")),
        .init(
            id: .togetherAI,
            displayName: "Together AI",
            shortName: "Together",
            authMethods: [.apiKeyBearer, .manual],
            supportedMetrics: [.balance, .usage],
            dashboardURL: url("https://api.together.ai/settings/billing")),
        .init(
            id: .cohere,
            displayName: "Cohere",
            shortName: "Cohere",
            authMethods: [.apiKeyBearer, .manual],
            supportedMetrics: [.usage, .spend],
            dashboardURL: url("https://dashboard.cohere.com/billing")),
        .init(
            id: .azureOpenAI,
            displayName: "Azure OpenAI",
            shortName: "Azure",
            authMethods: [.accessKeySecret, .oauth, .manual],
            supportedMetrics: [.spend, .usage],
            dashboardURL: url("https://portal.azure.com/#view/Microsoft_Azure_CostManagement/Menu/~/costanalysis")),
        .init(
            id: .awsBedrock,
            displayName: "AWS Bedrock",
            shortName: "Bedrock",
            authMethods: [.accessKeySecret, .manual],
            supportedMetrics: [.spend, .usage],
            dashboardURL: url("https://console.aws.amazon.com/costmanagement/home")),

        .init(
            id: .deepSeek,
            displayName: "DeepSeek",
            shortName: "DeepSeek",
            aliases: ["deep-seek"],
            authMethods: [.apiKeyBearer],
            credentialLabel: "API key",
            supportedMetrics: [.balance],
            dashboardURL: url("https://platform.deepseek.com/usage"),
            docsURL: url("https://api-docs.deepseek.com/api/get-user-balance/"),
            guideURL: guide("deepseek"),
            endpoint: .init(url: url("https://api.deepseek.com/user/balance")!)),
        .init(
            id: .alibabaBailian,
            displayName: "Alibaba",
            shortName: "Alibaba",
            aliases: ["aliyun", "dashscope", "qwen", "tongyi", "bailian"],
            authMethods: [.browserSession, .apiKeyBearer, .manual],
            credentialLabel: "Cookies / API key",
            supportedMetrics: [.usage, .quota, .codingPlan],
            dashboardURL: url("https://bailian.console.aliyun.com/"),
            docsURL: url("https://www.alibabacloud.com/help/en/model-studio/qwen-api-reference/"),
            guideURL: guide("alibaba")),
        .init(
            id: .alibabaToken,
            displayName: "Alibaba Token",
            shortName: "Alibaba Token",
            aliases: ["qwen-token", "tongyi-token", "dashscope-token"],
            authMethods: [.browserSession, .manual],
            credentialLabel: "Cookies",
            supportedMetrics: [.usage, .quota, .codingPlan],
            dashboardURL: url("https://bailian.console.aliyun.com/"),
            docsURL: url("https://www.alibabacloud.com/help/en/model-studio/"),
            guideURL: guide("alibaba-token"),
            implementationNote: "Separate Alibaba token-plan entry for accounts where quota is exposed through a browser/session token rather than a standard API key."),
        .init(
            id: .volcengineArk,
            displayName: "Volcengine Ark / Doubao",
            shortName: "Doubao",
            aliases: ["bytedance", "doubao", "ark", "volcengine"],
            authMethods: [.apiKeyBearer, .accessKeySecret, .manual],
            credentialLabel: "API key / AK-SK",
            supportedMetrics: [.usage, .quota, .codingPlan],
            dashboardURL: url("https://console.volcengine.com/ark/"),
            docsURL: url("https://api.volcengine.com/api-docs/view/overview?serviceCode=ark&version=2024-01-01"),
            guideURL: guide("volcengine-ark"),
            implementationNote: "Catalog includes Ark Agent Plan and Coding Plan APIs; signed OpenAPI refresh is tracked for the next provider pass."),
        .init(
            id: .antigravity,
            displayName: "Antigravity",
            shortName: "Antigravity",
            aliases: ["google-antigravity"],
            authMethods: [.manual],
            credentialLabel: "Local",
            supportedMetrics: [.usage, .quota, .codingPlan],
            dashboardURL: url("https://antigravity.google"),
            docsURL: url("https://antigravity.google/docs"),
            guideURL: guide("antigravity"),
            implementationNote: "Local-provider entry for tracking Antigravity plan state on this Mac while stable APIs are investigated."),
        .init(
            id: .zAI,
            displayName: "z.ai",
            shortName: "z.ai",
            aliases: ["zai", "glm-zai"],
            authMethods: [.apiKeyBearer, .manual],
            credentialLabel: "API key",
            supportedMetrics: [.balance, .usage, .codingPlan],
            dashboardURL: url("https://z.ai/manage-apikey/apikey-list"),
            docsURL: url("https://docs.z.ai/guides/llm/glm-coding-plan"),
            guideURL: guide("zai"),
            implementationNote: "z.ai is included as a first-class provider; live balance parsing will be added once the public quota endpoint is stable."),
        .init(
            id: .zhipuBigModel,
            displayName: "Zhipu BigModel",
            shortName: "Zhipu",
            aliases: ["glm", "bigmodel", "zhipuai"],
            authMethods: [.apiKeyBearer, .manual],
            supportedMetrics: [.usage, .quota, .codingPlan],
            dashboardURL: url("https://open.bigmodel.cn/usercenter/apikeys"),
            docsURL: url("https://docs.bigmodel.cn/cn/api/introduction")),
        .init(
            id: .moonshotKimi,
            displayName: "Kimi",
            shortName: "Kimi",
            aliases: ["moonshot", "kimi"],
            authMethods: [.apiKeyBearer],
            credentialLabel: "Token",
            supportedMetrics: [.balance, .usage],
            dashboardURL: url("https://platform.moonshot.ai/console/account"),
            docsURL: url("https://platform.kimi.ai/docs/api/balance"),
            guideURL: guide("kimi"),
            endpoint: .init(url: url("https://api.moonshot.ai/v1/users/me/balance")!)),
        .init(
            id: .kimiK2,
            displayName: "Kimi K2",
            shortName: "Kimi K2",
            aliases: ["kimi-k2", "moonshot-k2"],
            authMethods: [.apiKeyBearer, .manual],
            credentialLabel: "Legacy API",
            supportedMetrics: [.usage, .quota, .codingPlan],
            dashboardURL: url("https://platform.moonshot.ai/console/account"),
            docsURL: url("https://platform.kimi.ai/docs"),
            guideURL: guide("kimi-k2"),
            implementationNote: "Kimi K2 is kept as a separate legacy/API-plan entry so existing coding-plan accounts can be tracked without mixing them with the Moonshot balance API."),
        .init(
            id: .kilo,
            displayName: "Kilo",
            shortName: "Kilo",
            aliases: ["kilocode", "kilo-code"],
            authMethods: [.apiKeyBearer, .manual],
            credentialLabel: "API key",
            supportedMetrics: [.usage, .quota, .codingPlan],
            dashboardURL: url("https://kilocode.ai"),
            docsURL: url("https://kilocode.ai/docs"),
            guideURL: guide("kilo"),
            implementationNote: "Kilo is catalog-ready for local API-key tracking; live quota refresh is pending a documented quota endpoint."),
        .init(
            id: .kiro,
            displayName: "Kiro",
            shortName: "Kiro",
            aliases: ["aws-kiro"],
            authMethods: [.manual],
            credentialLabel: "CLI",
            supportedMetrics: [.usage, .quota, .codingPlan],
            dashboardURL: url("https://kiro.dev"),
            docsURL: url("https://kiro.dev/docs"),
            guideURL: guide("kiro"),
            implementationNote: "Kiro is represented as a CLI/local-session provider; TokenManager stores only local references and notes."),
        .init(
            id: .baiduQianfan,
            displayName: "Baidu Qianfan / ERNIE",
            shortName: "Qianfan",
            aliases: ["baidu", "ernie", "wenxin"],
            authMethods: [.accessKeySecret, .manual],
            supportedMetrics: [.usage, .quota, .spend],
            dashboardURL: url("https://console.bce.baidu.com/qianfan/ais/console/applicationConsole/application")),
        .init(
            id: .tencentHunyuan,
            displayName: "Tencent Hunyuan",
            shortName: "Hunyuan",
            aliases: ["tencent"],
            authMethods: [.accessKeySecret, .manual],
            supportedMetrics: [.usage, .quota, .spend],
            dashboardURL: url("https://console.cloud.tencent.com/hunyuan")),
        .init(
            id: .siliconFlow,
            displayName: "SiliconFlow",
            shortName: "SiliconFlow",
            aliases: ["siliconcloud"],
            authMethods: [.apiKeyBearer],
            supportedMetrics: [.balance, .usage],
            dashboardURL: url("https://cloud.siliconflow.cn/account/ak"),
            docsURL: url("https://docs.siliconflow.com/en/api-reference/userinfo/get-user-info"),
            endpoint: .init(url: url("https://api.siliconflow.com/v1/user/info")!)),
        .init(
            id: .miniMax,
            displayName: "MiniMax",
            shortName: "MiniMax",
            authMethods: [.apiKeyBearer, .browserSession, .manual],
            credentialLabel: "API key",
            supportedMetrics: [.balance, .usage, .codingPlan],
            dashboardURL: url("https://platform.minimaxi.com/user-center/basic-information/interface-key"),
            docsURL: url("https://www.minimaxi.com/document/guides/token-plan"),
            guideURL: guide("minimax"),
            endpoint: .init(url: url("https://api.minimaxi.com/v1/token_plan/remains")!),
            implementationNote: "Uses the MiniMax CN token plan remains endpoint. Its usage-count fields are remaining quota, so TokenManager converts them to used = total - remaining."),
        .init(
            id: .stepFun,
            displayName: "StepFun",
            shortName: "StepFun",
            aliases: ["step"],
            authMethods: [.apiKeyBearer, .manual],
            credentialLabel: "Step Plan API key",
            supportedMetrics: [.balance, .usage, .codingPlan],
            dashboardURL: url("https://platform.stepfun.com/account-info"),
            docsURL: url("https://platform.stepfun.com/step-plan"),
            guideURL: guide("stepfun"),
            implementationNote: "StepFun Step Plan uses OpenAI-compatible base https://api.stepfun.com/step_plan/v1 and Anthropic-compatible base https://api.stepfun.com/step_plan. A public remaining-quota endpoint is not documented yet."),
        .init(
            id: .baichuan,
            displayName: "Baichuan AI",
            shortName: "Baichuan",
            authMethods: [.apiKeyBearer, .manual],
            supportedMetrics: [.balance, .usage],
            dashboardURL: url("https://platform.baichuan-ai.com/console/apikey")),
        .init(
            id: .modelScope,
            displayName: "ModelScope",
            shortName: "ModelScope",
            aliases: ["aliyun-modelscope"],
            authMethods: [.apiKeyBearer, .manual],
            supportedMetrics: [.usage, .quota],
            dashboardURL: url("https://modelscope.cn/my/myaccesstoken")),
    ])
}

private func url(_ string: String) -> URL? {
    URL(string: string)
}

private func guide(_ slug: String) -> URL? {
    URL(string: "https://github.com/autumncry/tokenmanager/blob/main/docs/providers/\(slug).md")
}
