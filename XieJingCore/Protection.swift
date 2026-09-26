import Foundation

public enum Protection: Sendable, Hashable {
    case system
    case itself

    public static func decide(url: URL, bundleIdentifier: String?) -> Protection? {
        let path = url.standardizedFileURL.path
        let resolved = url.resolvingSymlinksInPath().standardizedFileURL.path
        let ownBundle = Bundle.main.bundleURL.standardizedFileURL.path
        if bundleIdentifier?.caseInsensitiveCompare(ProductIdentity.bundleIdentifier) == .orderedSame
            || path == ownBundle
            || resolved == ownBundle
        {
            return .itself
        }
        if path.hasPrefix("/System/") || resolved.hasPrefix("/System/") {
            return .system
        }
        if let bundleIdentifier, bundleIdentifier.lowercased().hasPrefix("com.apple.") {
            return .system
        }
        return nil
    }
}
