# refuse

CLI tool that finds (and optionally deletes) unused visual assets in Xcode projects.

## What it does

Scans `.xcassets` catalogs for image, color, and symbol assets, then parses Swift source files to determine which assets are never referenced. Reports unused assets grouped by catalog.

## Architecture

- `AssetScanner` — walks the directory tree, finds `.xcassets` bundles, returns `[Asset]`
- `UsageScanner` — collects all Swift source files, parses them concurrently with SwiftSyntax, builds a corpus of string literals and member access identifiers
- `Models` — `Asset` (name, catalog, kind, url) and `UnusedAsset`
- `RefuseCLI` — `AsyncParsableCommand` entry point, handles output and optional deletion

## Usage detection

Two forms are recognised:
- String literals: `UIImage(named: "my_icon")`, `Image("my_icon")`
- Generated resource identifiers: `Image(.myIcon)`, `UIImage(resource: .myIcon)`

Asset names are converted to camelCase for identifier matching (`my_icon` → `myIcon`).

## Scope

- Only Swift source files are scanned
- Only visual assets: `.imageset`, `.colorset`, `.symbolset`
- Font assets (`.fontset`) are out of scope — referenced by PostScript name, not asset name
- Storyboards and XIBs are intentionally excluded
- Target membership is not considered — an asset is "used" if referenced anywhere across the whole project

## Key dependencies

- `swift-argument-parser` — CLI argument and flag parsing
- `swift-syntax` — Swift AST parsing for accurate usage detection
