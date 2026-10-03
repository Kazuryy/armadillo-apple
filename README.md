# Armadillo (Apple)

An independent tvOS client for [Pangolin](https://github.com/fosrl/pangolin), the open-source zero-trust remote access platform.

This repo covers the Apple platforms (tvOS today). Other Armadillo clients — Android TV, webOS — may live in their own repos alongside this one.

Armadillo lets you sign in and connect to a Pangolin network — Pangolin Cloud or your own self-hosted instance — directly from your Apple TV.

> **Armadillo is an independent, community-built project.** It is not affiliated with, endorsed by, or sponsored by Fossorial, Inc., the makers of Pangolin.

## Try it

Public beta via TestFlight: [testflight.apple.com/join/aA1tWJm7](https://testflight.apple.com/join/aA1tWJm7)

## Features

- Sign in via QR code or device code — no typing passwords with the Siri Remote
- Connect to Pangolin Cloud or any self-hosted Pangolin server
- One-tap connect / disconnect from the Apple TV
- View account, organization, and server at a glance
- Switch between several accounts and organizations
- Route all traffic through an exit node
- See the live status of your sites
- Connect automatically on the Wi-Fi or Ethernet networks you choose
- DNS, MTU and routing settings

## Building

Armadillo embeds Pangolin's Go core (`olm`) as a static library, built separately from the Xcode project.

1. Build the Go core for tvOS, from the repository root:
   ```bash
   make build-tvos-all
   ```
   This produces `PangolinGo/libpangolin_tvos_arm64.a` (device) and `PangolinGo/libpangolin_tvos_sim_arm64.a` (simulator), which are not committed to the repo.

   The Makefile builds with a patched copy of your Go toolchain (kept in `.tmp/goroot`) so that tunnel timers keep counting while the Apple TV sleeps. It stops with an error if that patch cannot be applied to your Go version.

2. Open `Pangolin.xcodeproj` in Xcode 16+.

3. Select the **PangolinTvOS** scheme and a tvOS 17+ device or simulator, then build and run.

## Requirements

- Xcode 16 or later
- tvOS 17.0+
- Go 1.26 or later, to build the core library (see `PangolinGo/.go-version`)

## Project origin

Armadillo started as a fork of [fosrl/apple](https://github.com/fosrl/apple) (Pangolin's official Apple client), extended with tvOS support, then extracted into its own repository focused solely on tvOS.

## License

AGPL-3.0 — see [LICENSE](LICENSE). Portions of this codebase originate from `pangolin-apple` and are used under its default AGPL-3 license grant.

---

Developed with [Claude Code](https://claude.com/claude-code).
