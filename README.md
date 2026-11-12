<div align="center">

# 🦔 Armadillo — tvOS

**Independent tvOS client for Pangolin**
Zero-trust remote access · Apple TV

---

![Swift](https://img.shields.io/badge/Swift-5-F05138?style=for-the-badge&logo=swift&logoColor=white)
![tvOS](https://img.shields.io/badge/tvOS-17%2B-black?style=for-the-badge&logo=apple&logoColor=white)
![Xcode](https://img.shields.io/badge/Xcode-16%2B-147EFB?style=for-the-badge&logo=xcode&logoColor=white)
![Go](https://img.shields.io/badge/Go-1.26-00ADD8?style=for-the-badge&logo=go&logoColor=white)
![License](https://img.shields.io/badge/License-AGPL--3.0-blue?style=for-the-badge)

</div>

---

## ✨ Overview

Armadillo lets you sign in and connect to a [Pangolin](https://github.com/fosrl/pangolin) network — Pangolin Cloud or your own self-hosted instance — directly from your Apple TV.

This repo covers the Apple platforms (tvOS today). Other Armadillo clients — Android TV, webOS — may live in their own repos alongside this one.

> **Armadillo is an independent, community-built project.** It is not affiliated with, endorsed by, or sponsored by Fossorial, Inc., the makers of Pangolin.

---

## 🛠️ Tech stack

| Technology | Usage |
|---|---|
| [Swift](https://www.swift.org) / [SwiftUI](https://developer.apple.com/xcode/swiftui/) | tvOS app and UI |
| [NetworkExtension](https://developer.apple.com/documentation/networkextension) | Packet tunnel provider (VPN) |
| [Go](https://go.dev) (`olm`) | Pangolin's tunneling core, embedded as a static library |
| Keychain | Local, on-device secret storage |

---

## 📁 Project structure

```
📦 armadillo-apple
├── 📂 Pangolin/                # Main app target
│   ├── 📂 Shared/              # Auth, API client, tunnel & account managers
│   └── 📂 tvOS/                # SwiftUI screens, assets, entitlements
│
├── 📂 PacketTunnel/             # Network Extension target (the VPN tunnel)
│   ├── 📂 Shared/              # PacketTunnelProvider, tunnel adapter
│   └── 📂 tvOS/                # Extension entitlements
│
├── 📂 PangolinGo/               # Go core (olm), built as a static lib
│
├── Pangolin.xcodeproj
├── Makefile                    # make build-tvos-all
└── flake.nix
```

---

## 🚀 Getting started

### Requirements

- [Xcode](https://developer.apple.com/xcode/) 16+
- tvOS 17.0+
- [Go](https://go.dev) 1.26+ (see `PangolinGo/.go-version`)

### Build

```bash
# 1. Build the Go core for tvOS, from the repo root
make build-tvos-all

# 2. Open the Xcode project
open Pangolin.xcodeproj
```

Then select the **PangolinTvOS** scheme and a tvOS 17+ device or simulator, and build and run.

> `make build-tvos-all` produces `PangolinGo/libpangolin_tvos_arm64.a` (device) and `PangolinGo/libpangolin_tvos_sim_arm64.a` (simulator) — not committed to the repo. It also patches your local Go toolchain (kept in `.tmp/goroot`) so tunnel timers keep counting while the Apple TV sleeps.

---

## 📱 Try it

Public beta via TestFlight: **[testflight.apple.com/join/aA1tWJm7](https://testflight.apple.com/join/aA1tWJm7)**

---

## 🌱 Project origin

Armadillo started as a fork of [fosrl/apple](https://github.com/fosrl/apple) (Pangolin's official Apple client), extended with tvOS support, then extracted into its own repository focused solely on tvOS.

---

## 🤝 Contributing

Contributions are welcome — open an issue or pull request. See [CONTRIBUTING.md](CONTRIBUTING.md).

Found a security issue? Please don't open a public issue — see [SECURITY.md](SECURITY.md). For what Armadillo stores and where, see [PRIVACY.md](PRIVACY.md).

---

## 📝 License

AGPL-3.0 — see [LICENSE](LICENSE). Portions of this codebase originate from `pangolin-apple` and are used under its default AGPL-3 license grant.

---

<div align="center">

Developed with [Claude Code](https://claude.com/claude-code)

</div>
