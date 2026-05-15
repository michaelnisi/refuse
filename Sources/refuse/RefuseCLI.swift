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

    @Flag(name: .shortAndLong, help: "Suppress progress output (errors are always shown).")
    var silent: Bool = false

    mutating func run() async throws {
        let root = URL(filePath: path).standardized
        let scanner = UsageScanner(root: root)

        let assets = try AssetScanner(root: root).assets()
        guard !assets.isEmpty else {
            fputs("No asset catalogs found under \(root.path).\n", stderr)
            return
        }
        let catalogCount = Set(assets.map(\.catalog)).count
        printErr("Found \(assets.count) assets across \(catalogCount) catalogs")

        let sources = scanner.collectSwiftFiles()
        printErr("Scanning \(sources.count) Swift files...")

        let unused = try await scanner.unusedAssets(from: assets, sources: sources)
        guard !unused.isEmpty else {
            printErr("No unused assets found.")
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
        print("\n\(unused.count) unused assets across \(byCatalog.count) catalogs")

        if delete {
            print("\nDelete \(unused.count) unused assets? [y/N] ", terminator: "")
            guard readLine()?.lowercased() == "y" else {
                print("Aborted.")
                return
            }
            let fm = FileManager.default
            for item in unused {
                try fm.removeItem(at: item.asset.url)
            }
            print("Deleted \(unused.count) assets.")
        }

        throw ExitCode(1)
    }

    private func printErr(_ message: String) {
        guard !silent else { return }
        fputs(message + "\n", stderr)
    }
}
