import ArgumentParser
import Foundation

@main
struct Refuse: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "refuse",
        abstract: "List unused assets in an Xcode project or workspace."
    )

    @Argument(help: "Path to the Xcode project root (defaults to current directory).")
    var path: String = "."

    @Flag(name: .shortAndLong, help: "Delete unused assets after confirmation.")
    var delete: Bool = false

    mutating func run() async throws {
        let root = URL(filePath: path).standardized

        let assets = try AssetScanner(root: root).assets()
        guard !assets.isEmpty else {
            print("No asset catalogs found under \(root.path).")
            return
        }

        let unused = try await UsageScanner(root: root).unusedAssets(from: assets)
        guard !unused.isEmpty else {
            print("No unused assets found.")
            return
        }

        let byCatalog = Dictionary(grouping: unused) { $0.asset.catalog }
        for (catalog, items) in byCatalog.sorted(by: { $0.key.path < $1.key.path }) {
            let sorted = items.sorted(by: { $0.asset.name < $1.asset.name })
            let longestName = sorted.map(\.asset.name.count).max() ?? 0
            print("\n\(catalog.lastPathComponent) (\(sorted.count))")
            for item in sorted {
                let name = item.asset.name.padding(toLength: longestName + 2, withPad: " ", startingAt: 0)
                print("  \(name)\(item.asset.kind.rawValue)")
            }
        }
        let catalogCount = byCatalog.count
        print("\n\(unused.count) unused assets across \(catalogCount) catalogs")

        guard delete else { return }

        print("\nDelete \(unused.count) unused assets? [y/N] ", terminator: "")
        guard readLine()?.lowercased() == "y" else {
            print("Aborted.")
            return
        }

        let fm = FileManager.default
        var deleted = 0
        for item in unused {
            try fm.removeItem(at: item.asset.url)
            deleted += 1
        }
        print("Deleted \(deleted) assets.")
    }
}
