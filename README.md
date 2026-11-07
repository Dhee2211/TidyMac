<div align="center">

# TidyMac

**Free up disk space on your Mac in one click.**

A minimal, open-source cleaner built with SwiftUI. Everything runs on your device.

[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
![Platform](https://img.shields.io/badge/platform-macOS%2013%2B-lightgrey)
![Swift](https://img.shields.io/badge/Swift-5-orange)
[![PRs welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](CONTRIBUTING.md)

<img src="docs/screenshot.png" alt="TidyMac" width="320">

</div>

## Features

- **One-click cleanup.** Scan, review, clean.
- **Safe by design.** Targets only files that regenerate automatically. Your documents and system files are never touched.
- **Private.** No network access, no telemetry, no account.
- **Native and lightweight.** A single Swift file with no third-party dependencies.

## What it cleans

| Category | Location | Default |
| --- | --- | :---: |
| App caches | `~/Library/Caches` | On |
| Logs | `~/Library/Logs` | On |
| Trash | `~/.Trash` (permanent) | On |
| Xcode build files | DerivedData, simulator caches | On |
| Developer caches | Homebrew, pip, npm, yarn, pnpm, Gradle | On |
| Old downloads | `~/Downloads` items untouched for 90+ days, moved to Trash | Off |

## Installation

Requires macOS 13 or later and the Xcode Command Line Tools (`xcode-select --install`).

```bash
git clone https://github.com/Dhee2211/TidyMac.git
cd TidyMac
make install
```

This builds the app and copies it to `/Applications`. To build without installing, run `make`, then `open TidyMac.app`.

> TidyMac is ad-hoc signed and not notarized. On first launch, right-click the app, choose **Open**, then confirm.

## Usage

1. Open TidyMac. It scans automatically.
2. Untick anything you want to keep.
3. Click **Clean** and confirm.

### Permissions

macOS protects the Trash and Downloads folders. If either shows no data when you know it has files, grant TidyMac **Full Disk Access** in *System Settings → Privacy & Security*, then relaunch. Emptying the Trash may also ask for permission to control Finder.

## Development

```bash
make              # build TidyMac.app
make run          # build and launch
make screenshot   # regenerate docs/screenshot.png
make clean        # remove build output
```

The whole app is in [`TidyMac.swift`](TidyMac.swift):

| Component | Role |
| --- | --- |
| `Kind` | Cleanup categories. Add new ones here. |
| `size(of:)` | Disk usage calculation |
| `Model` | Scan and clean logic |
| `ContentView` | User interface |

## Contributing

Contributions are welcome, from a single new cache path to larger features.

- [Request a feature](../../issues/new?template=feature_request.yml)
- [Report a bug](../../issues/new?template=bug_report.yml)
- [Read the contributing guide](CONTRIBUTING.md) to add a cleanup category or open a pull request

Ideas open for contributors: large-file finder, menu bar mode, scheduled cleaning, preview of files before deleting, localization.

## Safety

Anything TidyMac removes by default must be regenerable. Anything else must be opt-in and moved to Trash. Found a case where it deletes something it shouldn't? See [SECURITY.md](SECURITY.md).

## License

Released under the [MIT License](LICENSE).
