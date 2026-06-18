# Claude

Credential: OAuth session or API key.

Use this provider for Anthropic/Claude account usage and quota tracking. TokenManager currently stores the local credential reference and opens the Anthropic console for verification while a stable usage API adapter is added.

No TokenManager server is involved; secrets stay in macOS Keychain when saved.
