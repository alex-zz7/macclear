import Foundation

public enum DockCleaner {
    private static let listKeys = ["persistent-apps", "recent-apps"]

    public static func plistURL(home: URL) -> URL {
        home.appending(path: "Library/Preferences/com.apple.dock.plist")
    }

    /// 只认 Bundle ID 完全一致，或图标指向的路径就是这个应用。不按名称删除，避免弄掉别的程序坞图标。
    public static func shortcuts(matching app: InstalledApp, plistURL: URL) -> [DockShortcut] {
        guard let plist = try? load(plistURL) else { return [] }
        let identifiers = Set(app.identifiers.map { $0.lowercased() })
        let paths = targetPaths(for: app)
        var found: [DockShortcut] = []
        for key in listKeys {
            for tile in tiles(in: plist, key: key) where matches(tile, identifiers: identifiers, paths: paths) {
                guard let shortcut = shortcut(from: tile, listKey: key), !shortcut.id.hasSuffix("||") else { continue }
                found.append(shortcut)
            }
        }
        return found
    }

    /// 从程序坞列表里去掉指定图标。`restartDock` 为真时会重新打开程序坞，图标才会马上消失。
    public static func remove(_ ids: Set<String>, plistURL: URL, restartDock: Bool = true) throws -> Int {
        guard !ids.isEmpty, FileManager.default.fileExists(atPath: plistURL.path) else { return 0 }
        var plist = try load(plistURL)
        var removed = 0
        for key in listKeys {
            guard let entries = plist[key] as? [[String: Any]] else { continue }
            let kept = entries.filter { entry in
                guard let tile = entry["tile-data"] as? [String: Any],
                      let shortcut = shortcut(from: tile, listKey: key),
                      ids.contains(shortcut.id)
                else { return true }
                removed += 1
                return false
            }
            plist[key] = kept
        }
        guard removed > 0 else { return 0 }
        let data = try PropertyListSerialization.data(fromPropertyList: plist, format: .binary, options: 0)
        try data.write(to: plistURL, options: .atomic)
        if restartDock {
            relaunchDock()
        }
        return removed
    }

    static func load(_ url: URL) throws -> [String: Any] {
        let data = try Data(contentsOf: url)
        var format = PropertyListSerialization.PropertyListFormat.binary
        guard let plist = try PropertyListSerialization.propertyList(from: data, options: [], format: &format) as? [String: Any] else {
            throw DockError.unreadable
        }
        return plist
    }

    private static func tiles(in plist: [String: Any], key: String) -> [[String: Any]] {
        guard let entries = plist[key] as? [[String: Any]] else { return [] }
        return entries.compactMap { $0["tile-data"] as? [String: Any] }
    }

    private static func matches(_ tile: [String: Any], identifiers: Set<String>, paths: Set<String>) -> Bool {
        if let identifier = tile["bundle-identifier"] as? String, identifiers.contains(identifier.lowercased()) {
            return true
        }
        guard let fileURL = fileURL(in: tile) else { return false }
        return paths.contains(normalizedPath(fileURL))
    }

    private static func shortcut(from tile: [String: Any], listKey: String) -> DockShortcut? {
        let label = (tile["file-label"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)
        let identifier = tile["bundle-identifier"] as? String
        let path = fileURL(in: tile).map(normalizedPath)
        guard identifier?.isEmpty == false || path?.isEmpty == false else { return nil }
        return DockShortcut(
            label: (label?.isEmpty == false ? label! : nil) ?? identifier ?? "Dock 图标",
            bundleIdentifier: identifier,
            filePath: path,
            listKey: listKey
        )
    }

    private static func fileURL(in tile: [String: Any]) -> URL? {
        guard let fileData = tile["file-data"] as? [String: Any],
              let string = fileData["_CFURLString"] as? String
        else { return nil }
        return URL(string: string)
    }

    private static func targetPaths(for app: InstalledApp) -> Set<String> {
        [
            normalizedPath(app.url),
            normalizedPath(app.url.resolvingSymlinksInPath()),
        ]
    }

    private static func normalizedPath(_ url: URL) -> String {
        var path = url.standardizedFileURL.path
        while path.count > 1, path.hasSuffix("/") {
            path.removeLast()
        }
        return path
    }

    private static func relaunchDock() {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/killall")
        process.arguments = ["Dock"]
        try? process.run()
    }
}
