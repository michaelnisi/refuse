import Foundation

extension String {
    /// Converts an asset name to the lowerCamelCase identifier Xcode generates
    /// for resource accessors. Separators are `_`, `-`, `.`, and space.
    func camelCased() -> String {
        let parts = components(separatedBy: CharacterSet(charactersIn: "_- .")).filter { !$0.isEmpty }
        guard !parts.isEmpty else { return self }
        let first = parts[0].prefix(1).lowercased() + parts[0].dropFirst()
        let rest = parts.dropFirst().map { $0.prefix(1).uppercased() + $0.dropFirst() }
        return ([first] + rest).joined()
    }
}
