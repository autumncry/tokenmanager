# OpenRouter

Credential: API key.

TokenManager can refresh credits through:

```text
https://openrouter.ai/api/v1/credits
```

One-off local test:

```sh
printf '%s' "$OPENROUTER_API_KEY" | tokenmanagerctl balance --provider openrouter --stdin
```

Remaining balance is calculated as total credits minus total usage.
