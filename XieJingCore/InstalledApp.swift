import Foundation

public struct InstalledApp: Identifiable, Hashable, Sendable {
    public var url: URL
    public var name: String
    public var bundleName: String?
    public var bundleIdentifier: String?
    public var version: String?
    public var identifiers: [String]
    public var matchNames: [String]
    public var byteCount: Int64?
    public var protection: Protection?
    public var storeCategory: String?

    public init(
        url: URL,
        name: String,
        bundleName: String?,
        bundleIdentifier: String?,
        version: String?,
        identifiers: [String],
        matchNames: [String],
        byteCount: Int64?,
        protection: Protection?,
        storeCategory: String? = nil
    ) {
        self.url = url
        self.name = name
        self.bundleName = bundleName
        self.bundleIdentifier = bundleIdentifier
        self.version = version
        self.identifiers = identifiers
        self.matchNames = matchNames
        self.byteCount = byteCount
        self.protection = protection
        self.storeCategory = storeCategory
    }

    public var id: String { url.standardizedFileURL.path }
    public var isProtected: Bool { protection != nil }

    public static func make(from url: URL) -> InstalledApp {
        let info = BundleInfoReader.read(appURL: url)
        let fileName = url.deletingPathExtension().lastPathComponent
        var rawIDs: [String] = []
        if let bundleIdentifier = info.bundleIdentifier {
            rawIDs.append(bundleIdentifier)
        }
        rawIDs.append(contentsOf: info.nestedIdentifiers)
        return InstalledApp(
            url: url,
            name: info.displayName,
            bundleName: info.bundleName,
            bundleIdentifier: info.bundleIdentifier,
            version: info.version,
            identifiers: uniqueIdentifiers(rawIDs),
            matchNames: matchNames(displayName: info.displayName, bundleName: info.bundleName, fileName: fileName),
            byteCount: SpotlightSize.byteCount(of: url),
            protection: Protection.decide(url: url, bundleIdentifier: info.bundleIdentifier),
            storeCategory: info.storeCategory
        )
    }

    public static func uniqueIdentifiers(_ raw: [String]) -> [String] {
        var seen = Set<String>()
        var result: [String] = []
        for id in raw {
            let trimmed = id.trimmingCharacters(in: .whitespacesAndNewlines)
            let key = trimmed.lowercased()
            guard !trimmed.isEmpty, seen.insert(key).inserted else { continue }
            result.append(trimmed)
        }
        return result
    }

    public static func matchNames(displayName: String, bundleName: String?, fileName: String) -> [String] {
        var seen = Set<String>()
        var result: [String] = []
        for raw in [displayName, bundleName ?? "", fileName] {
            let name = raw.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !name.isEmpty, seen.insert(name.lowercased()).inserted else { continue }
            result.append(name)
        }
        return result
    }
}
