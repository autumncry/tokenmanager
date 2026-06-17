<div align="center">
  <h1>tokenmanager</h1>
  <p><strong>AI API balances, usage, quotas, and coding plans in your macOS menu bar.</strong></p>
</div>

<p align="center">
  <a href="https://github.com/autumncry/tokenmanager/actions/workflows/ci.yml"><img src="https://img.shields.io/github/actions/workflow/status/autumncry/tokenmanager/ci.yml?style=flat-square" alt="CI"></a>
  <img src="https://img.shields.io/badge/macOS-14%2B-0a0a0c?style=flat-square" alt="macOS 14+">
  <img src="https://img.shields.io/badge/Swift-6.2-orange?style=flat-square" alt="Swift 6.2">
  <img src="https://img.shields.io/badge/npm-ready-cb3837?style=flat-square" alt="npm ready">
  <a href="LICENSE"><img src="https://img.shields.io/badge/license-MIT-6e5aff?style=flat-square" alt="MIT License"></a>
</p>

tokenmanager is a local-first native macOS menu bar app for tracking AI platform accounts. It records account balances, usage totals, quota windows, spend, and coding-plan style limits across mainstream global and Chinese model providers.

The project is inspired by the practical menu-bar workflow of [CodexBar](https://github.com/steipete/CodexBar), but focuses on API account management and broader Chinese provider coverage from day one.

## What Works Today

- Native macOS 14+ menu bar app built with SwiftUI `MenuBarExtra`.
- Local Provider catalog covering OpenAI, Anthropic, Google Gemini, xAI, Mistral, OpenRouter, Groq, Azure OpenAI, AWS Bedrock, DeepSeek, Alibaba Bailian / Qwen, Volcengine Ark / Doubao, Zhipu BigModel, Moonshot / Kimi API, Baidu Qianfan, Tencent Hunyuan, SiliconFlow, MiniMax, StepFun, Baichuan, and ModelScope.
- Live balance adapters for DeepSeek, Moonshot / Kimi API, SiliconFlow, OpenRouter, and OpenAI organization costs.
- First-class ByteDance / Volcengine Ark catalog entry with coding-plan metadata, aliases, dashboard links, and a clear adapter path for signed OpenAPI refresh.
- API keys stored in macOS Keychain. The JSON config stores only local Keychain references.
- `tokenmanagerctl` CLI for provider discovery, config inspection, and scripted local key setup.
- App bundle, `.pkg`, `.dmg`, and npm wrapper scripts.

## Privacy

There is no tokenmanager server.

- Credentials stay in macOS Keychain.
- Settings stay in `~/.config/tokenmanager/config.json`.
- Refresh requests go directly from your Mac to the provider APIs you enable.
- Unsupported providers can still be tracked locally while live adapters are added behind the same Provider API.

See [docs/privacy.md](docs/privacy.md) for the full storage model.

## Install

### GitHub Releases

The release workflow will publish:

- `tokenmanager.app`
- `tokenmanager-<version>.pkg`
- `tokenmanager-<version>.dmg`

For the current source build:

```sh
git clone https://github.com/autumncry/tokenmanager.git
cd tokenmanager
./script/package_app.sh
open dist/tokenmanager.app
```

### npm

The npm package provides a source-build install path for macOS:

```sh
npm install -g tokenmanager
tokenmanager build
tokenmanager launch
```

For CLI configuration:

```sh
tokenmanagerctl providers
printf '%s' "$DEEPSEEK_API_KEY" | tokenmanagerctl config set-api-key --provider deepseek --stdin
tokenmanagerctl status
```

### Installer Packages

Build local installer artifacts:

```sh
./script/make_pkg.sh
./script/make_dmg.sh
```

The generated files are written to `dist/`.

## Provider Coverage

| Provider | Metrics | Live refresh | Notes |
| --- | --- | --- | --- |
| OpenAI | spend, usage, balance | Yes | Uses organization costs API when the key has usage permissions. |
| DeepSeek | balance | Yes | Parses paid and granted balance breakdowns. |
| Moonshot / Kimi API | balance, usage | Yes | Parses cash and voucher balances. |
| SiliconFlow | balance, usage | Yes | Parses account and balance fields from user info. |
| OpenRouter | credits, usage | Yes | Calculates remaining credits from total credits and usage. |
| Volcengine Ark / Doubao | usage, quota, coding plan | Catalog now | Signed OpenAPI adapter is the next domestic-provider milestone. |
| Alibaba Bailian / Qwen | usage, quota, coding plan | Catalog now | Dashboard and API metadata included. |
| Zhipu, Baidu, Tencent, MiniMax, StepFun, Baichuan, ModelScope | usage, quota, balance | Catalog now | Local/manual tracking now, live adapters planned. |

The Provider layer is descriptor-driven so adding a provider should mean adding one descriptor, one parser/fetcher, tests, and docs.

## Development

Requirements:

- macOS 14+
- Xcode 26 or Swift 6.2+
- Node.js 18+ for npm wrapper validation

Run tests:

```sh
swift test
```

Launch the app from source:

```sh
./script/build_and_run.sh
```

Build release app:

```sh
./script/package_app.sh
```

The Codex desktop Run action is wired to `./script/build_and_run.sh`.

## Project Layout

```text
Sources/TokenManagerCore   Provider catalog, parsers, config, Keychain, API client
Sources/TokenManagerApp    Native macOS menu bar app
Sources/TokenManagerCLI    tokenmanagerctl command-line helper
Tests/TokenManagerCoreTests
script                     Build, run, pkg, dmg scripts
npm                        npm command wrappers
docs                       Privacy, provider, and packaging notes
```

## Roadmap

- [x] Native macOS menu bar app
- [x] Local-only credential/config model
- [x] Provider catalog with global and Chinese mainstream platforms
- [x] Live adapters for DeepSeek, Moonshot, SiliconFlow, OpenRouter, and OpenAI costs
- [x] npm and installer build paths
- [ ] Signed Volcengine Ark / Doubao coding-plan adapter
- [ ] Alibaba Bailian coding-plan live adapter
- [ ] Zhipu, Baidu Qianfan, Tencent Hunyuan, MiniMax, StepFun live adapters
- [ ] Release automation with notarized app, pkg, and dmg artifacts
- [ ] Optional Linux/Windows CLI-first builds
- [ ] Website and visual brand system

## License

MIT. See [LICENSE](LICENSE).
