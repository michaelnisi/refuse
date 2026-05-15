import Foundation
import SwiftParser
import SwiftSyntax

struct UsageScanner {
    let root: URL

    func unusedAssets(from assets: [Asset]) async throws -> [UnusedAsset] {
        let (strings, members) = try await swiftCorpus()
        return assets
            .filter { !isUsed($0, strings: strings, members: members) }
            .map { UnusedAsset(asset: $0) }
    }

    private func isUsed(_ asset: Asset, strings: Set<String>, members: Set<String>) -> Bool {
        strings.contains(asset.name) || members.contains(asset.name.camelCased())
    }

    private func swiftCorpus() async throws -> (strings: Set<String>, members: Set<String>) {
        let files = collectSwiftFiles()
        var strings = Set<String>()
        var members = Set<String>()

        try await withThrowingTaskGroup(of: (Set<String>, Set<String>).self) { group in
            for file in files {
                group.addTask {
                    let source = try String(contentsOf: file, encoding: .utf8)
                    let tree = Parser.parse(source: source)
                    let visitor = AssetUsageVisitor(viewMode: .sourceAccurate)
                    visitor.walk(tree)
                    return (visitor.stringLiterals, visitor.memberNames)
                }
            }
            for try await (fileStrings, fileMembers) in group {
                strings.formUnion(fileStrings)
                members.formUnion(fileMembers)
            }
        }
        return (strings, members)
    }

    private func collectSwiftFiles() -> [URL] {
        var files: [URL] = []
        let fm = FileManager.default
        guard let enumerator = fm.enumerator(
            at: root,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles]
        ) else { return [] }

        for case let url as URL in enumerator {
            if excludedDirectories.contains(url.lastPathComponent) {
                enumerator.skipDescendants()
                continue
            }
            if url.pathExtension == "swift" {
                files.append(url)
            }
        }
        return files
    }
}

private final class AssetUsageVisitor: SyntaxVisitor {
    var stringLiterals = Set<String>()
    var memberNames = Set<String>()

    override func visit(_ node: StringLiteralExprSyntax) -> SyntaxVisitorContinueKind {
        for segment in node.segments {
            if let seg = segment.as(StringSegmentSyntax.self) {
                stringLiterals.insert(seg.content.text)
            }
        }
        return .visitChildren
    }

    override func visit(_ node: MemberAccessExprSyntax) -> SyntaxVisitorContinueKind {
        memberNames.insert(node.declName.baseName.text)
        return .visitChildren
    }
}

private extension String {
    func camelCased() -> String {
        let parts = components(separatedBy: CharacterSet(charactersIn: "_-")).filter { !$0.isEmpty }
        guard !parts.isEmpty else { return self }
        let first = parts[0].prefix(1).lowercased() + parts[0].dropFirst()
        let rest = parts.dropFirst().map { $0.prefix(1).uppercased() + $0.dropFirst() }
        return ([first] + rest).joined()
    }
}
