# Privacy

tokenmanager is local-first by design. It does not require, run, or contact a tokenmanager-owned server. Account data, provider responses, and configuration stay on the user's Mac.

## Local Storage

- App configuration: `~/.config/tokenmanager/config.json`
- API keys and provider secrets: macOS Keychain service `app.tokenmanager.credentials`
- Build artifacts: `dist/`

The config file stores provider IDs, account display names, refresh preferences, and Keychain references. It must not store API key values, access tokens, or provider passwords.

## No Project Server

tokenmanager has no hosted backend, database, proxy, telemetry upload, or user-account system. From the tokenmanager project side, there is no server-side privacy collection surface.

## Network Model

When a provider has live refresh support, tokenmanager calls that provider directly from the user's Mac. The app does not proxy requests through project infrastructure.

Current live adapters:

- DeepSeek balance API
- Moonshot / Kimi balance API
- SiliconFlow user info API
- OpenRouter credits API
- OpenAI organization costs API

Providers without live adapters can be enabled as local/manual trackers while provider-specific signed API support is added.

## Permissions

The first version does not ask for Screen Recording, Accessibility, or Full Disk Access. Keychain prompts may appear when saving or reading provider credentials.

## Security Notes

- Prefer provider API keys scoped to usage or billing reads when the provider supports scoped keys.
- Avoid pasting production admin keys into shells with persistent history; use `--stdin` with `tokenmanagerctl`.
- Delete credentials from Keychain Access.app or through future `tokenmanagerctl config delete-key` support.
