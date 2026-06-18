# Kimi

Credential: Token.

TokenManager can refresh Moonshot/Kimi balance data through:

```text
https://api.moonshot.ai/v1/users/me/balance
```

One-off local test:

```sh
printf '%s' "$KIMI_API_KEY" | tokenmanagerctl balance --provider kimi --stdin
```

The request is sent directly from your Mac to the provider.
