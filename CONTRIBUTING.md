# Contributing

Thanks for helping make tokenmanager broader and more reliable.

## Development Loop

```sh
swift test
./script/build_and_run.sh
```

Use tests for parser changes and provider metadata changes. Provider additions should include at least one fixture-shaped parser test, even if the live endpoint requires credentials.

## Provider Rules

- Never store raw API keys or session tokens in config JSON.
- Keep provider identity fields siloed per provider.
- Prefer read-only or usage-scoped provider keys.
- Add dashboard and documentation links for every provider.
- Make unsupported live refresh explicit rather than pretending it works.

## Pull Requests

Include:

- What provider or app behavior changed
- How credentials are stored or read
- What tests were run
- Any provider API permissions needed
