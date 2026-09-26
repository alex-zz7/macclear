import Foundation

public struct AppReferenceMatcher: Sendable {
    public var appPath: String
    public var resolvedAppPath: String
    public var bundleMatcher: BundleIDMatcher

    public init(app: InstalledApp) {
        appPath = app.url.standardizedFileURL.path
        resolvedAppPath = app.url.resolvingSymlinksInPath().standardizedFileURL.path
        bundleMatcher = BundleIDMatcher(identifiers: app.identifiers)
    }

    public func references(_ value: String) -> Bool {
        if pathReferences(value, appPath: appPath) { return true }
        if resolvedAppPath != appPath, pathReferences(value, appPath: resolvedAppPath) { return true }
        for token in identifierTokens(in: value) where bundleMatcher.matches(filename: token) {
            return true
        }
        return false
    }

    public func plistReferences(_ url: URL) -> Bool {
        guard let data = try? Data(contentsOf: url), data.count <= 2_000_000 else { return false }
        guard let object = try? PropertyListSerialization.propertyList(from: data, format: nil) else { return false }
        return strings(in: object).contains(where: references)
    }

    func pathReferences(_ value: String, appPath: String) -> Bool {
        guard appPath.count > 1 else { return false }
        let haystack = value.lowercased()
        let needle = appPath.lowercased()
        var search = Substring(haystack)
        while let range = search.range(of: needle) {
            let beforeOK = range.lowerBound == haystack.startIndex || isPathBoundary(haystack[haystack.index(before: range.lowerBound)])
            let afterOK = range.upperBound == haystack.endIndex || isPathEnding(haystack[range.upperBound])
            if beforeOK && afterOK { return true }
            search = haystack[range.upperBound...]
        }
        return false
    }

    private func isPathBoundary(_ character: Character) -> Bool {
        character == "\"" || character == "'" || character == " " || character == "=" || character == ":"
            || character == "\n" || character == "\t"
    }

    private func isPathEnding(_ character: Character) -> Bool {
        character == "/" || character == "\"" || character == "'" || character == " " || character == "\n"
    }

    func identifierTokens(in value: String) -> [String] {
        var tokens: [String] = []
        var current = ""
        func flush() {
            if current.contains(".") {
                tokens.append(current)
            }
            current = ""
        }
        for character in value {
            if character.isLetter || character.isNumber || character == "." || character == "-" {
                current.append(character)
            } else {
                flush()
            }
        }
        flush()
        return tokens
    }

    private func strings(in object: Any) -> [String] {
        switch object {
        case let string as String:
            [string]
        case let array as [Any]:
            array.flatMap { strings(in: $0) }
        case let dictionary as [String: Any]:
            dictionary.values.flatMap { strings(in: $0) }
        case let dictionary as NSDictionary:
            dictionary.allValues.flatMap { strings(in: $0) }
        default:
            []
        }
    }
}
