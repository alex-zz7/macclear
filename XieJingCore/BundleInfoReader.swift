import Foundation

public enum BundleInfoReader {
    public static func read(appURL: URL) -> BundleInfo {
        let fileName = appURL.deletingPathExtension().lastPathComponent
        let root = resolvedBundleRoot(for: appURL)
        let plist = dictionary(in: root)
        let bundleName = string(plist?["CFBundleName"])
        let displayName = string(plist?["CFBundleDisplayName"]) ?? bundleName ?? fileName
        let bundleIdentifier = string(plist?["CFBundleIdentifier"])
        let version = string(plist?["CFBundleShortVersionString"]) ?? string(plist?["CFBundleVersion"])
        return BundleInfo(
            displayName: displayName,
            bundleName: bundleName,
            bundleIdentifier: bundleIdentifier,
            version: version,
            nestedIdentifiers: nestedIdentifiers(in: root)
        )
    }

    /// 标准 Mac 应用的 Info.plist 在 Contents 里。有些套壳应用把真正的包放在 Wrapper 下，而且用 iOS 那种根目录 Info.plist。
    static func resolvedBundleRoot(for appURL: URL) -> URL {
        if infoURL(in: appURL) != nil { return appURL }
        let wrapper = appURL.appending(path: "Wrapper")
        guard let children = try? FileManager().contentsOfDirectory(
            at: wrapper,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles]
        ) else { return appURL }
        return children.first { $0.pathExtension == "app" && infoURL(in: $0) != nil } ?? appURL
    }

    static func infoURL(in bundle: URL) -> URL? {
        let fileManager = FileManager()
        let contents = bundle.appending(path: "Contents/Info.plist")
        if fileManager.fileExists(atPath: contents.path) { return contents }
        let direct = bundle.appending(path: "Info.plist")
        if fileManager.fileExists(atPath: direct.path) { return direct }
        return nil
    }

    static func dictionary(in bundle: URL) -> [String: Any]? {
        guard let url = infoURL(in: bundle) else { return nil }
        return dictionary(at: url)
    }

    static func nestedIdentifiers(in bundleRoot: URL) -> [String] {
        let relatives = [
            "Contents/Library/LoginItems",
            "Contents/XPCServices",
            "Contents/PlugIns",
            "Contents/Library/SystemExtensions",
            "PlugIns",
            "Extensions",
        ]
        let packageExtensions: Set<String> = ["app", "xpc", "appex", "bundle", "plugin"]
        var identifiers: [String] = []
        let fileManager = FileManager()
        for relative in relatives {
            let directory = bundleRoot.appending(path: relative)
            guard let children = try? fileManager.contentsOfDirectory(
                at: directory,
                includingPropertiesForKeys: nil,
                options: [.skipsHiddenFiles]
            ) else { continue }
            for child in children where packageExtensions.contains(child.pathExtension) {
                if let identifier = string(dictionary(in: child)?["CFBundleIdentifier"]) {
                    identifiers.append(identifier)
                }
            }
        }
        return identifiers
    }

    static func dictionary(at url: URL) -> [String: Any]? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any]
    }

    static func string(_ value: Any?) -> String? {
        guard let raw = value as? String else { return nil }
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
