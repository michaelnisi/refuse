# refuse

A Swift CLI tool that finds unused visual assets in Xcode projects.

## What it does

`refuse` scans an Xcode project or workspace for `.xcassets` catalogs, collects all image, color, symbol, and font assets, then parses Swift source files to find which assets are never referenced anywhere. It understands both string literal references (`UIImage(named: "my_icon")`) and generated resource identifier references (`Image(.myIcon)`).

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

Unused assets are printed grouped by catalog:

```
Icons.xcassets
  imageset  arrow_back
  imageset  placeholder_avatar
  symbolset old_custom_symbol

Colors.xcassets
  colorset  legacy_tint
```

## Limitations

- Only Swift source files are scanned. Objective-C and Interface Builder files are not.
- Assets referenced via computed strings or loaded from remote config will be reported as unused.
