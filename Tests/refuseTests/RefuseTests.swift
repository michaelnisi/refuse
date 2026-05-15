import Testing
import Foundation
@testable import refuse

@Suite("Integration")
struct RefuseTests {

    @Test func totalAssetCount() throws {
        let fixture = try Fixture()
        defer { fixture.cleanup() }
        let assets = try AssetScanner(root: fixture.url).assets()
        #expect(assets.count == 10)
    }

    @Test func unusedAssetsAreDetected() async throws {
        let fixture = try Fixture()
        defer { fixture.cleanup() }
        let scanner = UsageScanner(root: fixture.url)
        let assets = try AssetScanner(root: fixture.url).assets()
        let sources = scanner.collectSwiftFiles()
        let unused = try await scanner.unusedAssets(from: assets, sources: sources)
        let names = Set(unused.map(\.name))
        #expect(names == ["old_banner", "legacy_splash", "deprecated_red", "unused_symbol", "another_unused"])
    }
}

// MARK: - Fixture

private struct Fixture {
    let url: URL

    init() throws {
        url = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        try build()
    }

    func cleanup() {
        try? FileManager.default.removeItem(at: url)
    }

    private func build() throws {
        let fm = FileManager.default
        let resources = url.appending(path: "Resources")

        // Images.xcassets — arrow_back and placeholder_avatar used, old_banner and legacy_splash unused
        let images = resources.appending(path: "Images.xcassets")
        try fm.createDirectory(at: images.appending(path: "arrow_back.imageset"), withIntermediateDirectories: true)
        try fm.createDirectory(at: images.appending(path: "placeholder_avatar.imageset"), withIntermediateDirectories: true)
        try fm.createDirectory(at: images.appending(path: "old_banner.imageset"), withIntermediateDirectories: true)
        try fm.createDirectory(at: images.appending(path: "legacy_splash.imageset"), withIntermediateDirectories: true)

        // Colors.xcassets — primary_blue and accent_green used, deprecated_red unused
        let colors = resources.appending(path: "Colors.xcassets")
        try fm.createDirectory(at: colors.appending(path: "primary_blue.colorset"), withIntermediateDirectories: true)
        try fm.createDirectory(at: colors.appending(path: "accent_green.colorset"), withIntermediateDirectories: true)
        try fm.createDirectory(at: colors.appending(path: "deprecated_red.colorset"), withIntermediateDirectories: true)

        // Icons.xcassets — app_icon used, unused_symbol and another_unused unused
        let icons = resources.appending(path: "Icons.xcassets")
        try fm.createDirectory(at: icons.appending(path: "app_icon.symbolset"), withIntermediateDirectories: true)
        try fm.createDirectory(at: icons.appending(path: "unused_symbol.symbolset"), withIntermediateDirectories: true)
        try fm.createDirectory(at: icons.appending(path: "another_unused.imageset"), withIntermediateDirectories: true)

        // Swift sources
        let app = url.appending(path: "Sources/App")
        let core = url.appending(path: "Sources/Core")
        try fm.createDirectory(at: app, withIntermediateDirectories: true)
        try fm.createDirectory(at: core, withIntermediateDirectories: true)

        // String literal references
        try write(to: app.appending(path: "HomeView.swift"), content: """
        import SwiftUI
        struct HomeView: View {
            var body: some View { Image("arrow_back") }
        }
        """)
        try write(to: app.appending(path: "ThemeManager.swift"), content: """
        import SwiftUI
        struct ThemeManager {
            let background = Color("primary_blue")
        }
        """)

        // Member access references
        try write(to: app.appending(path: "ProfileView.swift"), content: """
        import SwiftUI
        struct ProfileView: View {
            var body: some View { Image(.placeholderAvatar) }
        }
        """)
        try write(to: app.appending(path: "ColorPalette.swift"), content: """
        import SwiftUI
        struct ColorPalette {
            let accent = Color(.accentGreen)
        }
        """)
        try write(to: core.appending(path: "AppDelegate.swift"), content: """
        import SwiftUI
        @main struct MyApp: App {
            var body: some Scene { WindowGroup { Image(.appIcon) } }
        }
        """)
    }

    private func write(to url: URL, content: String) throws {
        try content.write(to: url, atomically: true, encoding: .utf8)
    }
}
