#!/usr/bin/env bash
#
# Generates a test fixture under TestFixture/ with a known set of used and
# unused assets so you can verify refuse output manually.
#
# Expected unused assets after running refuse against TestFixture/:
#   Images.xcassets  — old_banner, legacy_splash
#   Colors.xcassets  — deprecated_red
#   Icons.xcassets   — unused_symbol, another_unused
#
# Run from the repo root:
#   ./Scripts/generate-test-fixture.sh

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
FIXTURE="$ROOT/TestFixture"

if [[ -d "$FIXTURE" ]]; then
    echo "Removing existing TestFixture..."
    rm -rf "$FIXTURE"
fi

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

catalog_json() {
    cat <<'JSON'
{
  "info" : { "author" : "xcode", "version" : 1 }
}
JSON
}

imageset_json() {
    cat <<'JSON'
{
  "images" : [ { "idiom" : "universal" } ],
  "info" : { "author" : "xcode", "version" : 1 }
}
JSON
}

colorset_json() {
    cat <<'JSON'
{
  "colors" : [ { "idiom" : "universal" } ],
  "info" : { "author" : "xcode", "version" : 1 }
}
JSON
}

symbolset_json() {
    cat <<'JSON'
{
  "info" : { "author" : "xcode", "version" : 1 },
  "symbols" : [ { "idiom" : "universal" } ]
}
JSON
}

make_imageset() {
    local dir="$1"
    mkdir -p "$dir"
    imageset_json > "$dir/Contents.json"
}

make_colorset() {
    local dir="$1"
    mkdir -p "$dir"
    colorset_json > "$dir/Contents.json"
}

make_symbolset() {
    local dir="$1"
    mkdir -p "$dir"
    symbolset_json > "$dir/Contents.json"
}

make_catalog() {
    local dir="$1"
    mkdir -p "$dir"
    catalog_json > "$dir/Contents.json"
}

# ---------------------------------------------------------------------------
# Asset catalogs
# ---------------------------------------------------------------------------

IMAGES="$FIXTURE/Resources/Images.xcassets"
COLORS="$FIXTURE/Resources/Colors.xcassets"
ICONS="$FIXTURE/Resources/Icons.xcassets"

make_catalog "$IMAGES"
make_imageset "$IMAGES/arrow_back.imageset"        # used — string literal
make_imageset "$IMAGES/placeholder_avatar.imageset" # used — member access
make_imageset "$IMAGES/old_banner.imageset"         # UNUSED
make_imageset "$IMAGES/legacy_splash.imageset"      # UNUSED

make_catalog "$COLORS"
make_colorset "$COLORS/primary_blue.colorset"       # used — string literal
make_colorset "$COLORS/accent_green.colorset"       # used — member access
make_colorset "$COLORS/deprecated_red.colorset"     # UNUSED

make_catalog "$ICONS"
make_symbolset "$ICONS/app_icon.symbolset"          # used — member access
make_symbolset "$ICONS/unused_symbol.symbolset"     # UNUSED
make_imageset  "$ICONS/another_unused.imageset"     # UNUSED

# ---------------------------------------------------------------------------
# Swift sources
# ---------------------------------------------------------------------------

mkdir -p "$FIXTURE/Sources/App"
mkdir -p "$FIXTURE/Sources/Core"

cat > "$FIXTURE/Sources/App/HomeView.swift" <<'SWIFT'
import SwiftUI

struct HomeView: View {
    var body: some View {
        Image("arrow_back")
    }
}
SWIFT

cat > "$FIXTURE/Sources/App/ProfileView.swift" <<'SWIFT'
import SwiftUI

struct ProfileView: View {
    var body: some View {
        Image(.placeholderAvatar)
    }
}
SWIFT

cat > "$FIXTURE/Sources/App/ThemeManager.swift" <<'SWIFT'
import SwiftUI

struct ThemeManager {
    let background = Color("primary_blue")
    let accent = Color(.accentGreen)
}
SWIFT

cat > "$FIXTURE/Sources/Core/AppDelegate.swift" <<'SWIFT'
import SwiftUI

@main
struct MyApp: App {
    var body: some Scene {
        WindowGroup {
            Image(.appIcon)
        }
    }
}
SWIFT

# ---------------------------------------------------------------------------

echo "Generated TestFixture at $FIXTURE"
echo ""
echo "Used assets (should NOT appear in refuse output):"
echo "  arrow_back, placeholder_avatar, primary_blue, accent_green, app_icon"
echo ""
echo "Unused assets (SHOULD appear in refuse output):"
echo "  old_banner, legacy_splash, deprecated_red, unused_symbol, another_unused"
