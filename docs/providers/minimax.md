# MiniMax

Credential: API key.

TokenManager can query the China token-plan remains endpoint:

```text
https://api.minimaxi.com/v1/token_plan/remains
```

Model/API configuration:

```text
OpenAI-compatible base:    https://api.minimaxi.com/v1
Anthropic-compatible base: https://api.minimaxi.com/anthropic
Model: MiniMax-M2.7
```

One-off local test:

```sh
printf '%s' "$MINIMAX_API_KEY" | tokenmanagerctl balance --provider minimax --stdin
```

MiniMax labels the remaining request count as `*_usage_count` on this endpoint. TokenManager converts it to displayed usage with `used = total - remaining`.
