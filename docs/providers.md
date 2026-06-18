# Providers

Provider support is descriptor-driven. Each provider entry declares:

- Stable provider ID
- Display name and aliases
- Authentication methods
- Supported metrics
- Dashboard and documentation links
- Optional live API endpoint

## Live Adapters

| Provider | Endpoint | Parser |
| --- | --- | --- |
| DeepSeek | `https://api.deepseek.com/user/balance` | `balance_infos` with total, granted, and topped-up balances |
| Moonshot / Kimi API | `https://api.moonshot.ai/v1/users/me/balance` | available, voucher, and cash balances |
| SiliconFlow | `https://api.siliconflow.com/v1/user/info` | account identity, free balance, charged balance, total balance |
| OpenRouter | `https://openrouter.ai/api/v1/credits` | total credits minus total usage |
| OpenAI | `https://api.openai.com/v1/organization/costs` | organization cost buckets |

## Testing A Key

The app Settings window now exposes the live adapter path directly: select a provider, paste the API key, then choose **Save & Refresh**. The key is stored in macOS Keychain and the balance request is sent directly from the user's Mac to the provider endpoint.

For one-off checks without saving a key:

```sh
printf '%s' "$DEEPSEEK_API_KEY" | tokenmanagerctl balance --provider deepseek --stdin
```

Prefer `--stdin` over `--api-key` so the secret is not left in shell history.

## Catalog-First Providers

These providers are represented in the app and config model now, with live adapters planned:

- Anthropic Claude
- Google Gemini
- xAI Grok
- Mistral AI
- GroqCloud
- Together AI
- Cohere
- Azure OpenAI
- AWS Bedrock
- Alibaba Bailian / Qwen
- Volcengine Ark / Doubao / ByteDance
- Zhipu BigModel
- Baidu Qianfan / ERNIE
- Tencent Hunyuan
- MiniMax
- StepFun
- Baichuan AI
- ModelScope

## Adding A Provider

1. Add a `ProviderDescriptor` in `ProviderCatalog.default`.
2. Add a parser in `ProviderBalanceParser`.
3. Add tests for response mapping and catalog metadata.
4. Update this document and the README provider table.

Provider code should not persist secrets in config files. Store credentials through `CredentialStore`.
