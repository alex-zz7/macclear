import Foundation
import Testing
@testable import XieJingCore

struct DockCleanerTests {
    private let app = InstalledApp(
        url: URL(fileURLWithPath: "/Applications/Demo.app"),
        name: "Demo",
        bundleName: "Demo",
        bundleIdentifier: "com.example.demo",
        version: "1.0",
        identifiers: ["com.example.demo"],
        matchNames: ["Demo"],
        byteCount: nil,
        protection: nil
    )

    @Test func `finds the dock icon for this app and ignores lookalikes`() throws {
        let plistURL = try writeDockPlist()
        defer { try? FileManager.default.removeItem(at: plistURL.deletingLastPathComponent()) }
        let found = DockCleaner.shortcuts(matching: app, plistURL: plistURL)
        #expect(found.count == 2)
        #expect(found.allSatisfy { $0.bundleIdentifier == "com.example.demo" })
        #expect(found.contains { $0.label == "Demo" && $0.listKey == "persistent-apps" })
    }

    @Test func `rewriting a real dock plist without a match keeps every icon`() throws {
        let source = DockCleaner.plistURL(home: FileManager.default.homeDirectoryForCurrentUser)
        guard FileManager.default.fileExists(atPath: source.path) else { return }
        let root = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: root) }
        let copy = root.appending(path: "com.apple.dock.plist")
        try FileManager.default.copyItem(at: source, to: copy)
        let before = try DockCleaner.load(copy)
        let removed = try DockCleaner.remove(["missing"], plistURL: copy, restartDock: false)
        let after = try DockCleaner.load(copy)
        #expect(removed == 0)
        #expect(count(before, "persistent-apps") == count(after, "persistent-apps"))
        #expect(count(before, "recent-apps") == count(after, "recent-apps"))
    }

    @Test func `removes an injected icon from a copy of the real dock plist`() throws {
        let source = DockCleaner.plistURL(home: FileManager.default.homeDirectoryForCurrentUser)
        guard FileManager.default.fileExists(atPath: source.path) else { return }
        let root = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: root) }
        let copy = root.appending(path: "com.apple.dock.plist")
        try FileManager.default.copyItem(at: source, to: copy)
        var plist = try DockCleaner.load(copy)
        var apps = plist["persistent-apps"] as? [[String: Any]] ?? []
        let before = apps.count
        apps.append([
            "tile-type": "file-tile",
            "tile-data": [
                "file-label": "Macclear Dock Test",
                "bundle-identifier": "app.macclear.dock-test",
                "file-data": [
                    "_CFURLString": "file:///Applications/MacclearDockTest.app/",
                    "_CFURLStringType": 15,
                ],
            ],
        ])
        plist["persistent-apps"] = apps
        let data = try PropertyListSerialization.data(fromPropertyList: plist, format: .binary, options: 0)
        try data.write(to: copy)

        let shortcut = DockShortcut(
            label: "Macclear Dock Test",
            bundleIdentifier: "app.macclear.dock-test",
            filePath: "/Applications/MacclearDockTest.app",
            listKey: "persistent-apps"
        )
        let removed = try DockCleaner.remove([shortcut.id], plistURL: copy, restartDock: false)
        let after = try DockCleaner.load(copy)
        #expect(removed == 1)
        #expect(count(after, "persistent-apps") == before)
    }

    @Test func `removes only the matching dock icon`() throws {
        let plistURL = try writeDockPlist()
        defer { try? FileManager.default.removeItem(at: plistURL.deletingLastPathComponent()) }
        let found = DockCleaner.shortcuts(matching: app, plistURL: plistURL)
        let removed = try DockCleaner.remove(Set(found.map(\.id)), plistURL: plistURL, restartDock: false)
        #expect(removed == 2)

        let plist = try DockCleaner.load(plistURL)
        let apps = try #require(plist["persistent-apps"] as? [[String: Any]])
        #expect(apps.count == 2)
        let identifiers = apps.compactMap { ($0["tile-data"] as? [String: Any])?["bundle-identifier"] as? String }
        #expect(identifiers == ["com.example.other", "com.example.demolition"])
        #expect(plist["tilesize"] as? Int == 48)
    }

    private func count(_ plist: [String: Any], _ key: String) -> Int {
        (plist[key] as? [Any])?.count ?? 0
    }

    private func writeDockPlist() throws -> URL {
        let root = try makeTemporaryDirectory()
        let url = root.appending(path: "com.apple.dock.plist")
        let plist: [String: Any] = [
            "tilesize": 48,
            "persistent-apps": [
                tile(label: "Demo", identifier: "com.example.demo", path: "/Applications/Demo.app"),
                tile(label: "Other", identifier: "com.example.other", path: "/Applications/Other.app"),
                tile(label: "Demolition", identifier: "com.example.demolition", path: "/Applications/Demolition.app"),
            ],
            "recent-apps": [
                tile(label: "Demo", identifier: "com.example.demo", path: "/Applications/Demo.app"),
            ],
        ]
        let data = try PropertyListSerialization.data(fromPropertyList: plist, format: .binary, options: 0)
        try data.write(to: url)
        return url
    }

    private func tile(label: String, identifier: String, path: String) -> [String: Any] {
        [
            "tile-type": "file-tile",
            "tile-data": [
                "file-label": label,
                "bundle-identifier": identifier,
                "file-data": [
                    "_CFURLString": "file://\(path)/",
                    "_CFURLStringType": 15,
                ],
            ],
        ]
    }
}
