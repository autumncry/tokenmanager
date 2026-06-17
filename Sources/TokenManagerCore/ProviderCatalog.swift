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
    public let supportedMetrics: Set<MetricKind>
    public let dashboardURL: URL?
    public let docsURL: URL?
    public let endpoint: ProviderAPIEndpoint?
    public let storagePolicy: String
    public let implementationNote: String

    public init(
        id: ProviderID,
        displayName: String,
        shortName: String,
        aliases: [String] = [],
        authMethods: [AuthMethod],
        supportedMetrics: Set<MetricKind>,
        dashboardURL: URL?,
        docsURL: URL? = nil,
        endpoint: ProviderAPIEndpoint? = nil,
        storagePolicy: String = "local keychain + local config only",
        implementationNote: String = "")
    {
        self.id = id
        self.displayName = displayName
        self.shortName = shortName
        self.aliases = aliases
        self.authMethods = authMethods
        self.supportedMetrics = supportedMetrics
        self.dashboardURL = dashboardURL
        self.docsURL = docsURL
        self.endpoint = endpoint
        self.storagePolicy = storagePolicy
        self.implementationNote = implementationNote
    }

    public var supportsLiveRefresh: Bool {
        self.endpoint != nil
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
            aliases: ["chatgpt", "codex"],
            authMethods: [.apiKeyBearer],
            supportedMetrics: [.spend, .usage, .balance],
            dashboardURL: url("https://platform.openai.com/usage"),
            docsURL: url("https://developers.openai.com/api/reference/resources/admin/subresources/organization/subresources/usage/methods/costs"),
            endpoint: .init(url: url("https://api.openai.com/v1/organization/costs")!),
            implementationNote: "Uses OpenAI Admin usage/cost APIs when the key has organization usage permissions."),
        .init(
            id: .anthropic,
            displayName: "Anthropic Claude",
            shortName: "Claude",
            aliases: ["claude"],
            authMethods: [.apiKeyBearer, .manual],
            supportedMetrics: [.usage, .quota],
            dashboardURL: url("https://console.anthropic.com/settings/usage"),
            docsURL: url("https://platform.claude.com/docs")),
        .init(
            id: .googleGemini,
            displayName: "Google Gemini",
            shortName: "Gemini",
            aliases: ["google-ai-studio"],
            authMethods: [.apiKeyBearer, .oauth, .manual],
            supportedMetrics: [.usage, .quota],
            dashboardURL: url("https://aistudio.google.com/usage"),
            docsURL: url("https://ai.google.dev/gemini-api/docs")),
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
            supportedMetrics: [.balance, .usage, .spend],
            dashboardURL: url("https://openrouter.ai/settings/credits"),
            docsURL: url("https://openrouter.ai/docs/api/api-reference/credits/get-credits"),
            endpoint: .init(url: url("https://openrouter.ai/api/v1/credits")!),
            implementationNote: "Requires an OpenRouter management API key for credit totals."),
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
            supportedMetrics: [.balance],
            dashboardURL: url("https://platform.deepseek.com/usage"),
            docsURL: url("https://api-docs.deepseek.com/api/get-user-balance/"),
            endpoint: .init(url: url("https://api.deepseek.com/user/balance")!)),
        .init(
            id: .alibabaBailian,
            displayName: "Alibaba Bailian / Qwen",
            shortName: "Qwen",
            aliases: ["aliyun", "dashscope", "qwen", "tongyi"],
            authMethods: [.apiKeyBearer, .manual],
            supportedMetrics: [.usage, .quota, .codingPlan],
            dashboardURL: url("https://bailian.console.aliyun.com/"),
            docsURL: url("https://www.alibabacloud.com/help/en/model-studio/qwen-api-reference/")),
        .init(
            id: .volcengineArk,
            displayName: "Volcengine Ark / Doubao",
            shortName: "Doubao",
            aliases: ["bytedance", "doubao", "ark", "volcengine"],
            authMethods: [.apiKeyBearer, .accessKeySecret, .manual],
            supportedMetrics: [.usage, .quota, .codingPlan],
            dashboardURL: url("https://console.volcengine.com/ark/"),
            docsURL: url("https://api.volcengine.com/api-docs/view/overview?serviceCode=ark&version=2024-01-01"),
            implementationNote: "Catalog includes Ark Agent Plan and Coding Plan APIs; signed OpenAPI refresh is tracked for the next provider pass."),
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
            displayName: "Moonshot / Kimi API",
            shortName: "Kimi",
            aliases: ["moonshot", "kimi"],
            authMethods: [.apiKeyBearer],
            supportedMetrics: [.balance, .usage],
            dashboardURL: url("https://platform.moonshot.ai/console/account"),
            docsURL: url("https://platform.kimi.ai/docs/api/balance"),
            endpoint: .init(url: url("https://api.moonshot.ai/v1/users/me/balance")!)),
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
            supportedMetrics: [.balance, .usage, .codingPlan],
            dashboardURL: url("https://platform.minimaxi.com/user-center/basic-information/interface-key")),
        .init(
            id: .stepFun,
            displayName: "StepFun",
            shortName: "StepFun",
            aliases: ["step"],
            authMethods: [.apiKeyBearer, .manual],
            supportedMetrics: [.balance, .usage, .codingPlan],
            dashboardURL: url("https://platform.stepfun.com/account-info")),
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
