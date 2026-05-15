import Foundation

struct Asset {
    let name: String
    let catalog: URL
    let kind: Kind
    let url: URL

    enum Kind: String, CaseIterable {
        case imageset
        case colorset
        case symbolset

        var suffix: String { ".\(rawValue)" }
    }
}

struct UnusedAsset {
    let asset: Asset
}
