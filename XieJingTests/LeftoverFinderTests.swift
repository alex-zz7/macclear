import Foundation
import Testing
@testable import XieJingCore

struct LeftoverFinderTests {
    @Test func `finds bundle id matches and keeps mere name lookalikes out`() async throws {
        let root = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: root) }
        let appURL = root.appending(path: "Applications/Demo.app", directoryHint: .isDirectory)
        try makeDirectory(appURL)
        let library = root.appending(path: "Library", directoryHint: .isDirectory)

        try makeFile(library.appending(path: "Preferences/com.example.demo.plist"))
        try makeFile(library.appending(path: "Preferences/com.example.demo.helper.plist"))
        try makeFile(library.appending(path: "Preferences/com.example.demolition.plist"))
        try makeDirectory(library.appending(path: "Application Support/Demo"))
        try makeFile(library.appending(path: "Application Support/Demo/nested.txt"))
        try makeDirectory(library.appending(path: "Application Support/Demonstration"))
        try makeDirectory(library.appending(path: "Application Support/Demo Helper"))
        try makeDirectory(library.appending(path: "Containers/com.example.demo"))
        try makeDirectory(library.appending(path: "Containers/com.example.demolition"))
        try makeDirectory(library.appending(path: "Group Containers/AB12CD34EF.com.example.demo"))
        try makeDirectory(library.appending(path: "Group Containers/group.com.example.demo"))
        try makeDirectory(library.appending(path: "Group Containers/AB12CD34EF.com.example.demolition"))
        try makeDirectory(library.appending(path: "Caches/com.example.demo"))
        try makeDirectory(library.appending(path: "Saved Application State/com.example.demo.savedState"))
        try makeDirectory(library.appending(path: "Logs/Demo"))
        try makeFile(library.appending(path: "Logs/DiagnosticReports/Demo_2024-01-01.ips"))
        try makeFile(library.appending(path: "Logs/DiagnosticReports/Demolition_2024-01-01.ips"))
        try writePlist(
            ["Label": "helper", "ProgramArguments": [appURL.path + "/Contents/MacOS/Demo"]],
            to: library.appending(path: "LaunchAgents/helper.plist")
        )
        try writePlist(
            ["Label": "idle", "ProgramArguments": ["/usr/bin/true"]],
            to: library.appending(path: "LaunchAgents/idle.plist")
        )
        try writePlist(
            ["Label": "com.apple.demo", "ProgramArguments": [appURL.path]],
            to: library.appending(path: "LaunchAgents/com.apple.demo.plist")
        )

        let app = InstalledApp(
            url: appURL,
            name: "Demo",
            bundleName: "Demo",
            bundleIdentifier: "com.example.demo",
            version: "1.0",
            identifiers: ["com.example.demo", "com.example.demo.helper"],
            matchNames: ["Demo"],
            byteCount: nil,
            protection: nil
        )
        let finder = LeftoverFinder(
            locations: ScanLocations(home: root, applicationDirectories: [root.appending(path: "Applications")], includeSystemRoots: false)
        )
        let report = await finder.find(for: app)
        let paths = Set(report.items.map { $0.url.standardizedFileURL.path })

        #expect(paths.contains(appURL.standardizedFileURL.path))
        #expect(confidence(report, suffix: "/Preferences/com.example.demo.plist") == .certain)
        #expect(confidence(report, suffix: "/Preferences/com.example.demo.helper.plist") == .certain)
        #expect(confidence(report, suffix: "/Preferences/com.example.demolition.plist") == nil)
        #expect(confidence(report, suffix: "/Application Support/Demo") == .likely)
        #expect(confidence(report, suffix: "/Application Support/Demo Helper") == .likely)
        #expect(confidence(report, suffix: "/Application Support/Demonstration") == nil)
        #expect(!paths.contains(library.appending(path: "Application Support/Demo/nested.txt").standardizedFileURL.path))
        #expect(confidence(report, suffix: "/Containers/com.example.demo") == .certain)
        #expect(confidence(report, suffix: "/Containers/com.example.demolition") == nil)
        #expect(confidence(report, suffix: "/Group Containers/AB12CD34EF.com.example.demo") == .certain)
        #expect(confidence(report, suffix: "/Group Containers/group.com.example.demo") == .certain)
        #expect(confidence(report, suffix: "/Group Containers/AB12CD34EF.com.example.demolition") == nil)
        #expect(confidence(report, suffix: "/Caches/com.example.demo") == .certain)
        #expect(confidence(report, suffix: "/Saved Application State/com.example.demo.savedState") == .certain)
        #expect(confidence(report, suffix: "/Logs/Demo") == .likely)
        #expect(confidence(report, suffix: "/Logs/DiagnosticReports/Demo_2024-01-01.ips") == .likely)
        #expect(confidence(report, suffix: "/Logs/DiagnosticReports/Demolition_2024-01-01.ips") == nil)
        #expect(confidence(report, suffix: "/LaunchAgents/helper.plist") == .certain)
        #expect(confidence(report, suffix: "/LaunchAgents/idle.plist") == nil)
        #expect(confidence(report, suffix: "/LaunchAgents/com.apple.demo.plist") == nil)
        #expect(!report.didTruncate)
    }

    private func confidence(_ report: LeftoverReport, suffix: String) -> MatchConfidence? {
        report.items.first { $0.url.standardizedFileURL.path.hasSuffix(suffix) }?.confidence
    }
}
