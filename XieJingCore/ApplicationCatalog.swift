import Foundation

public struct ApplicationCatalog: Sendable {
    public var locations: ScanLocations

    public init(locations: ScanLocations) {
        self.locations = locations
    }

    @concurrent
    public func scan() async -> [InstalledApp] {
        var found: [InstalledApp] = []
        for directory in locations.applicationDirectories {
            if Task.isCancelled { break }
            for url in Self.bundleURLs(in: directory, depth: 0) {
                found.append(InstalledApp.make(from: url))
            }
        }
        return Self.collapse(found)
    }

    static func bundleURLs(in directory: URL, depth: Int) -> [URL] {
        guard depth < 3 else { return [] }
        let fileManager = FileManager()
        guard let children = try? fileManager.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: [.isDirectoryKey, .isSymbolicLinkKey],
            options: [.skipsHiddenFiles]
        ) else { return [] }

        var urls: [URL] = []
        for child in children {
            if child.pathExtension == "app" {
                urls.append(child)
                continue
            }
            let values = try? child.resourceValues(forKeys: [.isDirectoryKey, .isSymbolicLinkKey])
            if values?.isSymbolicLink == true { continue }
            if values?.isDirectory == true, depth < 2, child.pathExtension.isEmpty {
                urls.append(contentsOf: bundleURLs(in: child, depth: depth + 1))
            }
        }
        return urls
    }

    /// 同一个应用若同时出现在 /Applications 的符号链接和 Caskroom 里，只保留用户看得到的那一个。
    static func collapse(_ apps: [InstalledApp]) -> [InstalledApp] {
        var groups: [String: [InstalledApp]] = [:]
        for app in apps {
            let key = app.url.resolvingSymlinksInPath().standardizedFileURL.path
            groups[key, default: []].append(app)
        }
        var unique: [InstalledApp] = []
        var seen = Set<String>()
        for group in groups.values {
            guard let chosen = group.min(by: prefer) else { continue }
            if seen.insert(chosen.id).inserted {
                unique.append(chosen)
            }
        }
        return unique.sorted {
            $0.name.localizedStandardCompare($1.name) == .orderedAscending
        }
    }

    private static func prefer(_ lhs: InstalledApp, _ rhs: InstalledApp) -> Bool {
        let left = rank(lhs)
        let right = rank(rhs)
        if left != right { return left < right }
        return lhs.url.path.count < rhs.url.path.count
    }

    private static func rank(_ app: InstalledApp) -> Int {
        let path = app.url.standardizedFileURL.path
        if path.hasPrefix("/Applications/") { return 0 }
        if path.contains("/Applications/") { return 1 }
        if path.contains("/Caskroom/") { return 3 }
        return 2
    }
}
