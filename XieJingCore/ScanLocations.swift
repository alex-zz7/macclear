import Foundation

public struct ScanLocations: Sendable {
    public var home: URL
    public var applicationDirectories: [URL]
    public var includeSystemRoots: Bool

    public init(home: URL, applicationDirectories: [URL]? = nil, includeSystemRoots: Bool = true) {
        self.home = home
        self.applicationDirectories = applicationDirectories ?? Self.defaultApplicationDirectories(home: home)
        self.includeSystemRoots = includeSystemRoots
    }

    public static func live() -> ScanLocations {
        ScanLocations(home: FileManager.default.homeDirectoryForCurrentUser)
    }

    public static func defaultApplicationDirectories(home: URL) -> [URL] {
        [
            URL(fileURLWithPath: "/Applications", isDirectory: true),
            URL(fileURLWithPath: "/System/Applications", isDirectory: true),
            home.appending(path: "Applications", directoryHint: .isDirectory),
        ]
    }

    public func searchRoots() -> [SearchRoot] {
        var roots = userRoots()
        if includeSystemRoots {
            roots.append(contentsOf: systemRoots())
        }
        return roots
    }

    private func user(_ relative: String) -> URL {
        home.appending(path: "Library/" + relative, directoryHint: .isDirectory)
    }

    private func userRoots() -> [SearchRoot] {
        [
            SearchRoot(url: user("Preferences"), category: .preferences, rule: .bundleIdentifier),
            SearchRoot(url: user("Application Support"), category: .applicationSupport, rule: .bundleIdentifierOrExactName),
            SearchRoot(url: user("Application Scripts"), category: .applicationSupport, rule: .bundleIdentifier),
            SearchRoot(url: user("Caches"), category: .caches, rule: .bundleIdentifierOrExactName),
            SearchRoot(url: user("Cookies"), category: .other, rule: .bundleIdentifier),
            SearchRoot(url: user("HTTPStorages"), category: .caches, rule: .bundleIdentifier),
            SearchRoot(url: user("Logs"), category: .logs, rule: .bundleIdentifierOrExactName),
            SearchRoot(url: user("Logs/DiagnosticReports"), category: .logs, rule: .crashReport),
            SearchRoot(url: user("Logs/CrashReporter"), category: .logs, rule: .crashReport),
            SearchRoot(url: user("Application Support/CrashReporter"), category: .logs, rule: .crashReport),
            SearchRoot(url: user("Saved Application State"), category: .savedState, rule: .bundleIdentifier),
            SearchRoot(url: user("WebKit"), category: .caches, rule: .bundleIdentifier),
            SearchRoot(url: user("Containers"), category: .containers, rule: .bundleIdentifier),
            SearchRoot(url: user("Group Containers"), category: .groupContainers, rule: .bundleIdentifier),
            SearchRoot(url: user("LaunchAgents"), category: .launchAgents, rule: .launchDefinition),
            SearchRoot(url: user("PreferencePanes"), category: .plugIns, rule: .bundleIdentifierOrExactName),
            SearchRoot(url: user("Input Methods"), category: .plugIns, rule: .bundleIdentifierOrExactName),
            SearchRoot(url: user("Services"), category: .plugIns, rule: .bundleIdentifierOrExactName),
            SearchRoot(url: user("Internet Plug-Ins"), category: .plugIns, rule: .bundleIdentifierOrExactName),
            SearchRoot(url: user("QuickLook"), category: .plugIns, rule: .bundleIdentifierOrExactName),
            SearchRoot(url: user("Spotlight"), category: .plugIns, rule: .bundleIdentifier),
            SearchRoot(url: user("Receipts"), category: .receipts, rule: .bundleIdentifier),
            SearchRoot(url: user("Audio/Plug-Ins"), category: .plugIns, rule: .bundleIdentifierOrExactName, depth: 2),
        ]
    }

    private func systemRoots() -> [SearchRoot] {
        let library = URL(fileURLWithPath: "/Library", isDirectory: true)
        func system(_ relative: String) -> URL {
            library.appending(path: relative, directoryHint: .isDirectory)
        }
        return [
            SearchRoot(url: system("Application Support"), category: .applicationSupport, rule: .bundleIdentifier),
            SearchRoot(url: system("Caches"), category: .caches, rule: .bundleIdentifier),
            SearchRoot(url: system("Preferences"), category: .preferences, rule: .bundleIdentifier),
            SearchRoot(url: system("Logs"), category: .logs, rule: .bundleIdentifier),
            SearchRoot(url: system("Logs/DiagnosticReports"), category: .logs, rule: .crashReport),
            SearchRoot(url: system("LaunchAgents"), category: .launchAgents, rule: .launchDefinition),
            SearchRoot(url: system("LaunchDaemons"), category: .launchAgents, rule: .launchDefinition),
            SearchRoot(url: system("PrivilegedHelperTools"), category: .launchAgents, rule: .bundleIdentifier),
            SearchRoot(url: system("PreferencePanes"), category: .plugIns, rule: .bundleIdentifier),
            SearchRoot(url: system("Internet Plug-Ins"), category: .plugIns, rule: .bundleIdentifier),
            SearchRoot(url: system("Input Methods"), category: .plugIns, rule: .bundleIdentifier),
            SearchRoot(url: system("Receipts"), category: .receipts, rule: .bundleIdentifier),
            SearchRoot(
                url: URL(fileURLWithPath: "/private/var/db/receipts", isDirectory: true),
                category: .receipts,
                rule: .bundleIdentifier
            ),
        ]
    }
}
