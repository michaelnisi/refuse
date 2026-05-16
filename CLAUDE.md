# refuse

CLI tool that finds (and optionally deletes) unused visual assets in Xcode projects.

## What it does

Scans `.xcassets` catalogs for image, color, and symbol assets, then parses Swift source files to determine which assets are never referenced. Reports unused assets grouped by catalog. Exits with code `1` when unused assets are found (CI-friendly).

## Architecture

- `AssetScanner` — walks the directory tree, finds `.xcassets` bundles, returns `[Asset]`
- `UsageScanner` — collects Swift source files, parses them concurrently with SwiftSyntax, builds a corpus of string literals and member access identifiers; exposes `collectSwiftFiles()` so `RefuseCLI` can report progress before scanning
- `Models` — `Asset` (name, catalog, kind, url) and `UnusedAsset`
- `RefuseCLI` — `AsyncParsableCommand` entry point; progress to stderr, results to stdout, optional silent mode (`-s`), optional deletion with confirmation (`-d`)
- `String+CamelCase` — converts asset names to lowerCamelCase for identifier matching
- `Exclusions` — vendor directories skipped by both scanners (`Pods`, `Carthage`, `vendor`)

## Usage detection

Two forms are recognised:
- String literals: `UIImage(named: "my_icon")`, `Image("my_icon")`
- Generated resource identifiers: `Image(.myIcon)`, `UIImage(resource: .myIcon)`

Asset names are converted to camelCase for identifier matching (`my_icon` → `myIcon`). Separators are `_`, `-`, `.`, and space — matching Xcode's confirmed algorithm. Edge cases with all-caps sequences (e.g. `URL_icon`) are undocumented by Apple; current behaviour is pinned in `CamelCaseTests`.

## Scope

- Only Swift source files are scanned
- Only visual assets: `.imageset`, `.colorset`, `.symbolset`
- Font assets (`.fontset`) are out of scope — referenced by PostScript name, not asset name
- Storyboards and XIBs are intentionally excluded
- Target membership is not considered — an asset is "used" if referenced anywhere across the whole project
- Designed to run from an app project or workspace root

## Key dependencies

- `swift-argument-parser` — CLI argument and flag parsing
- `swift-syntax` — Swift AST parsing for accurate usage detection
