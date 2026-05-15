import Foundation

struct AssetScanner {
    let root: URL

    func assets() throws -> [Asset] {
        var result: [Asset] = []
        let fm = FileManager.default
        guard let enumerator = fm.enumerator(
            at: root,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        ) else { return [] }

        for case let url as URL in enumerator {
            guard url.pathExtension == "xcassets" else { continue }
            result += try assetsInCatalog(url)
            enumerator.skipDescendants()
        }
        return result
    }

    private func assetsInCatalog(_ catalog: URL) throws -> [Asset] {
        var result: [Asset] = []
        let fm = FileManager.default
        guard let enumerator = fm.enumerator(
            at: catalog,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        ) else { return [] }

        for case let url as URL in enumerator {
            guard
                let kind = Asset.Kind(rawValue: url.pathExtension),
                (try? url.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) == true
            else { continue }

            let name = url.deletingPathExtension().lastPathComponent
            result.append(Asset(name: name, catalog: catalog, kind: kind, url: url))
            enumerator.skipDescendants()
        }
        return result
    }
}
