# Contributing to TidyMac

Thanks for helping! TidyMac is intentionally small, so keeping it simple is the main rule.

## Ground rules

1. **Safety first.** Default-on categories must be regenerable (caches, logs, build output). Anything else must be opt-in and go to Trash, not be permanently deleted.
2. **Stay light.** No third-party dependencies, no network calls, no telemetry.
3. **Stay simple.** One window, one button. New features shouldn't add required steps.

## Setup

```bash
git clone https://github.com/Dhee2211/TidyMac.git
cd TidyMac
make run
```

Requires macOS 13+ and Xcode Command Line Tools. No Xcode project needed.

## Adding a cleanup category

All categories live in the `Kind` enum in `TidyMac.swift`. To add one:

1. Add a `case` (e.g. `case dockerLogs`).
2. Fill in `name` and `detail` (shown in the UI).
3. Return the paths in `items()`. Return the **top-level items** to remove, not every file.
4. Set `defaultOn` — `false` unless it's clearly safe.
5. If it should go to Trash instead of being deleted, handle it in `Model.clean()` like `oldDownloads`.

Example:

```swift
case .yarnBerry:
    return [home.appendingPathComponent(".yarn/berry/cache")].filter { fm.fileExists(atPath: $0.path) }
```

## Pull requests

- Open an issue first for anything bigger than a small category or fix.
- Keep PRs focused; one change per PR.
- Run `make` and try the app on your Mac. Include what you tested.
- For new categories, say **why it's safe to delete** and what regenerates it.

## Reporting bugs and requesting features

Use the [issue templates](../../issues/new/choose). For anything that deletes the wrong thing, please include the path.

## Security

See [SECURITY.md](SECURITY.md).

## Code of conduct

Be kind and constructive. We follow the [Contributor Covenant](https://www.contributor-covenant.org/version/2/1/code_of_conduct/).
