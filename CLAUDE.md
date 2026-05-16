# refuse

CLI tool that finds (and optionally deletes) unused visual assets in Xcode projects.

## Usage detection

Two forms are recognised:
- String literals: `UIImage(named: "my_icon")`, `Image("my_icon")`
- Generated resource identifiers: `Image(.myIcon)`, `UIImage(resource: .myIcon)`

Asset names are converted to lowerCamelCase for identifier matching. Separators (`_`, `-`, `.`, space) follow Xcode's confirmed algorithm. All-caps sequences (e.g. `URL_icon`) are undocumented by Apple — current behaviour is pinned in `CamelCaseTests`.

Member access names are only collected when they appear as direct call arguments. This prevents unrelated `.foo` property accesses from shielding assets, at the cost of missing identifiers passed through a variable.

## Scope

- Only Swift source files are scanned
- Only visual assets: `.imageset`, `.colorset`, `.symbolset`
- Font assets (`.fontset`) are out of scope — fonts are referenced by PostScript name, not asset name
- Storyboards and XIBs are intentionally excluded
- Target membership is not considered — an asset is "used" if referenced anywhere in the project
