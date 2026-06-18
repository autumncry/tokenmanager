# DeepSeek

Credential: API key.

TokenManager can refresh DeepSeek balance through:

```text
https://api.deepseek.com/user/balance
```

Model/API configuration:

```text
OpenAI-compatible base:    https://api.deepseek.com
Anthropic-compatible base: https://api.deepseek.com/anthropic
Models: deepseek-v4-flash, deepseek-v4-pro
Legacy models: deepseek-chat, deepseek-reasoner
```

One-off local test:

```sh
printf '%s' "$DEEPSEEK_API_KEY" | tokenmanagerctl balance --provider deepseek --stdin
```

The parser shows total balance plus granted and topped-up breakdowns.
