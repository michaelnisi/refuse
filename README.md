# refuse

A Swift CLI tool that finds unused visual assets in Xcode projects.

## What it does

`refuse` scans an Xcode project or workspace for `.xcassets` catalogs, collects all image, color, and symbol assets, then parses Swift source files to find which assets are never referenced anywhere. It understands both string literal references (`UIImage(named: "my_icon")`) and generated resource identifier references (`Image(.myIcon)`).

Built for large multi-target apps — the Swift source corpus is parsed concurrently.

## Installation

```sh
git clone https://github.com/michaelnisi/refuse
cd refuse
swift build -c release
cp .build/release/refuse /usr/local/bin/refuse
```

## Usage

Run from your project root:

```sh
refuse
```

Or pass a path explicitly:

```sh
refuse /path/to/MyApp
```

To delete unused assets after confirmation:

```sh
refuse -d
```

## Output

Progress is written to stderr, results to stdout:

```
Found 1247 assets across 8 catalogs
Scanning 342 Swift files...

Colors.xcassets (1)
  deprecated_red    colorset

Icons.xcassets (2)
  another_unused    imageset
  unused_symbol     symbolset

5 unused assets across 2 catalogs
```

## CI

`refuse` exits with code `1` when unused assets are found, `0` when the project is clean. To suppress progress output:

```sh
refuse 2>/dev/null
```

## Limitations

- Only Swift source files are scanned. Objective-C and Interface Builder files are not.
- Font assets (`.fontset`) are not supported — fonts are referenced by PostScript name, not asset name.
- Assets referenced via computed strings or loaded from remote config will be reported as unused.
