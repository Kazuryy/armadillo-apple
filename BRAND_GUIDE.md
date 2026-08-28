# Pangolin brand reference

Notes on Pangolin's own brand identity, compiled from the official [pangolin.net](https://pangolin.net) site and the upstream [fosrl/apple](https://github.com/fosrl/apple) client, as a reference for keeping Armadillo's colors and tone in the same family. Each value is sourced so it stays verifiable if the brand changes.

## Brand color

### Primary orange — `#F36118`

This is *the* brand color, confirmed identical in two independent places:

- **Official site logo** (`https://pangolin.net/icons/logo-light.svg`): the stylized pangolin uses `fill="#F36118"`, the "Pangolin" wordmark uses `fill="black"`.
- **macOS/iOS app icon** (in `fosrl/apple`, `Pangolin/pangolin-app-icon.icon/Assets/pangolin_orange.svg`): same artwork, `fill:#f36118`.

### AccentColor (Xcode asset) — `#F36217`

Defined in the upstream app's `Pangolin/Assets.xcassets/AccentColor.colorset/Contents.json`:
- sRGB: R 243, G 98, B 23 → `#F36217`
- **Identical in light and dark mode** (a single value for both appearances) — the brand color doesn't shift with the theme.

This is within 1 unit of the logo's `#F36118` (negligible rounding difference). **Treat both as the same brand color**; use `#F36118` if a single canonical value is needed (it's the one used on both official logos). Armadillo's own accent color follows this same value.

### App icon background — `#18181B` (very dark graphite)

Defined in the upstream icon's `icon.json` (Icon Composer format, Xcode 16+):
```json
"fill-specializations": [
  { "value": { "solid": "display-p3:0.09412,0.09412,0.10588,1.00000" } },
  { "appearance": "dark", "value": { "solid": "srgb:0.09412,0.09412,0.10588,1.00000" } }
]
```
≈ RGB(24, 24, 27) in standard sRGB, nearly identical in light and dark. A warm black/anthracite, not a pure black — roughly Tailwind CSS's "zinc-900". Armadillo's own icon background uses this same value.

## Secondary / neutral palette (website)

Extracted from the site's production CSS (`_next/static/chunks/0uqw0co.jds28.css`):

| Name | Hex | Likely use |
|---|---|---|
| `--color-black` | `#000000` | Text on light background |
| `--color-white` | `#ffffff` | Text on dark background |
| `--color-beige-light-2` | `#faf9f2` | Warm light background (cream) |
| `--color-beige-light-3` | `#f2f0e7` | Warm light background, variant |
| `--color-grey-light-8` | `#bbbbbb` | Light gray (borders, muted text) |
| `--color-grey-light-9` | `#8d8d8d` | Medium gray |
| `--color-grey-light-11` | `#646464` | Dark gray |
| `--color-grey-light-12` | `#202020` | Near-black |
| `--color-red-600` | `#e40014` | Error / danger |

The remaining CSS variables on the site (`--tw-prose-*`) are Tailwind Typography plugin defaults, not Pangolin-specific brand colors.

## Typography

Extracted from the font classes loaded on `pangolin.net`:

- **Headings / display**: **Die Grotesk B** and **Die Grotesk C** (a commercial typeface, geometric grotesque style)
- **Body / technical text**: **IBM Plex Mono** (loaded as a root class on `<html>` — used very visibly, consistent with the "technical network/security tool" positioning)
- Fallback stacks:
  - Sans-serif: `ui-sans-serif, system-ui, sans-serif, "Apple Color Emoji", "Segoe UI Emoji", "Segoe UI Symbol", "Noto Color Emoji"`
  - Mono: `ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, "Liberation Mono", "Courier New", monospace`

**Note for Apple apps**: SwiftUI defaults to the system font (San Francisco), which diverges from the web identity (Die Grotesk + IBM Plex Mono). That's a common, deliberate choice for native Apple apps (consistency with the OS rather than the website). Armadillo's Top Shelf wordmark uses Space Grotesk (Google Fonts, OFL-licensed) as an open-source stand-in for Die Grotesk's geometric-grotesque feel, since the original is a commercial typeface.

## Logo

- Official site file: `https://pangolin.net/icons/logo-light.svg` (486×122, orange pangolin + black wordmark)
- The pangolin symbol alone (no text) is available separately in the upstream app's icon assets: `pangolin_orange.svg`

## Brand tone

- Official tagline: **"The zero trust remote access platform."**
- Positioning: network security (zero trust), technical but accessible, oriented toward self-hosting and deployment
- Stat featured on the site: "1,000,000+ deployments worldwide"
- License: dual AGPLv3 + Fossorial Commercial License (the company behind Pangolin is **Fossorial**, GitHub org `fosrl`)

---
*Compiled 2026-08-27 from the fosrl/apple source and a snapshot of the public pangolin.net site. Revalidate the CSS values if the site's design changes.*
