import Foundation

public struct BundleInfo: Sendable, Hashable {
    public var displayName: String
    public var bundleName: String?
    public var bundleIdentifier: String?
    public var version: String?
    public var nestedIdentifiers: [String]

    public init(
        displayName: String,
        bundleName: String?,
        bundleIdentifier: String?,
        version: String?,
        nestedIdentifiers: [String]
    ) {
        self.displayName = displayName
        self.bundleName = bundleName
        self.bundleIdentifier = bundleIdentifier
        self.version = version
        self.nestedIdentifiers = nestedIdentifiers
    }
}
