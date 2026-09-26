import Foundation

public struct NameMatcher: Sendable, Equatable {
    public var names: [String]

    public init(names: [String]) {
        self.names = names
    }

    public var usableNames: [String] {
        names.filter(Self.isUsable)
    }

    /// 只接受完整文件名相同，或名称后面跟着 Helper / Agent 这类固定后缀。不做子串匹配。
    public func matchesExact(filename: String) -> Bool {
        let stem = FilenameStem.stem(of: filename)
        for name in usableNames {
            if stem.compare(name, options: [.caseInsensitive, .diacriticInsensitive]) == .orderedSame {
                return true
            }
            for suffix in Self.suffixes {
                let candidate = name + suffix
                if stem.compare(candidate, options: [.caseInsensitive, .diacriticInsensitive]) == .orderedSame {
                    return true
                }
            }
        }
        return false
    }

    public func matchesCrashReport(filename: String) -> Bool {
        let stem = FilenameStem.stem(of: filename)
        for name in usableNames {
            let lowerStem = stem.lowercased()
            let lowerName = name.lowercased()
            if lowerStem == lowerName { return true }
            if lowerStem.hasPrefix(lowerName + "_")
                || lowerStem.hasPrefix(lowerName + "-")
                || lowerStem.hasPrefix(lowerName + " ")
            {
                return true
            }
        }
        return false
    }

    public static func isUsable(_ name: String) -> Bool {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 4 else { return false }
        guard trimmed.contains(where: \.isLetter) else { return false }
        return !blocklist.contains(trimmed.lowercased())
    }

    public static let suffixes = [" Helper", " Agent", " Launcher", " Updater", " Uninstaller"]

    public static let blocklist: Set<String> = [
        "cache", "caches", "data", "temp", "test", "user", "users", "apps", "docs",
        "logs", "library", "support", "shared", "common", "local", "default", "config",
        "plugin", "plugins", "helper", "agent", "service", "crash", "crashes", "reports",
        "metadata", "preferences", "containers", "saved", "state", "application",
        "applications", "macos", "system", "private", "public", "desktop", "documents",
        "downloads", "movies", "music", "pictures", "untitled", "launcher", "updater",
    ]
}
