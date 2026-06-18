# OpenAI

Credential: Admin API key.

TokenManager can refresh organization cost data through `https://api.openai.com/v1/organization/costs` when the key has organization usage permissions.

```sh
printf '%s' "$OPENAI_ADMIN_KEY" | tokenmanagerctl balance --provider openai --stdin
```

The key is read locally. TokenManager has no server and does not proxy the request.
