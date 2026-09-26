import Foundation

public struct PathPolicy: Sendable, Equatable {
    public var allowedPrefixes: [String]
    public var blockedExact: Set<String>

    public init(allowedPrefixes: [String], blockedExact: Set<String>) {
        self.allowedPrefixes = allowedPrefixes
        self.blockedExact = blockedExact
    }

    /// 要删的路径和符号链接的目标都必须落在允许的目录里，并且不能是这些目录本身。
    /// `trashItem` 对符号链接会移走链接而不是目标；目标若指向用户主目录或系统目录，这里直接拒绝。
    public func isTrashable(_ url: URL) -> Bool {
        let path = url.standardizedFileURL.path
        guard isWithinBounds(path) else { return false }
        if let values = try? url.resourceValues(forKeys: [.isSymbolicLinkKey]), values.isSymbolicLink == true {
            let resolved = url.resolvingSymlinksInPath().standardizedFileURL.path
            guard isWithinBounds(resolved) else { return false }
        }
        return true
    }

    public func isWithinBounds(_ path: String) -> Bool {
        if path.isEmpty || path == "/" || path.contains("..") { return false }
        if blockedExact.contains(path) { return false }
        return allowedPrefixes.contains { path.hasPrefix($0) }
    }

    public static func standard(home: URL) -> PathPolicy {
        let homePath = home.standardizedFileURL.path
        let userLibrary = homePath + "/Library"
        let userApps = homePath + "/Applications"
        let prefixes = [
            "/Applications/",
            userApps + "/",
            userLibrary + "/",
            "/Library/",
            "/private/var/db/receipts/",
            "/opt/homebrew/Caskroom/",
            "/usr/local/Caskroom/",
        ]
        var blocked: Set<String> = [
            "/",
            "/Applications",
            "/Library",
            "/System",
            "/usr",
            "/opt",
            "/opt/homebrew",
            "/opt/homebrew/Caskroom",
            "/usr/local",
            "/usr/local/Caskroom",
            "/private",
            "/private/var",
            "/private/var/db",
            "/private/var/db/receipts",
            "/Users",
            homePath,
            userLibrary,
            userApps,
        ]
        let libraryFolders = [
            "Application Support",
            "Application Scripts",
            "Caches",
            "Cookies",
            "HTTPStorages",
            "Logs",
            "Preferences",
            "Saved Application State",
            "WebKit",
            "Containers",
            "Group Containers",
            "LaunchAgents",
            "PreferencePanes",
            "Input Methods",
            "Services",
            "Internet Plug-Ins",
            "QuickLook",
            "Spotlight",
            "Receipts",
            "Audio",
            "Audio/Plug-Ins",
            "Logs/DiagnosticReports",
            "Logs/CrashReporter",
            "Application Support/CrashReporter",
        ]
        for folder in libraryFolders {
            blocked.insert(userLibrary + "/" + folder)
            blocked.insert("/Library/" + folder)
        }
        blocked.formUnion([
            "/Library/LaunchDaemons",
            "/Library/PrivilegedHelperTools",
            "/Library/LaunchAgents",
        ])
        return PathPolicy(allowedPrefixes: prefixes, blockedExact: blocked)
    }
}
