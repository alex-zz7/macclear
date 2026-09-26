import Foundation
import Testing
@testable import XieJingCore

struct ApplicationCatalogTests {
    @Test func `reads the bundle id, helper id, and protects Apple apps`() async throws {
        let root = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: root) }
        let applications = root.appending(path: "Applications", directoryHint: .isDirectory)
        let demo = applications.appending(path: "Demo.app")
        try writePlist(
            [
                "CFBundleIdentifier": "com.example.demo",
                "CFBundleName": "Demo",
                "CFBundleDisplayName": "Demo",
                "CFBundleShortVersionString": "1.2",
                "CFBundleExecutable": "Demo",
                "CFBundlePackageType": "APPL",
            ],
            to: demo.appending(path: "Contents/Info.plist")
        )
        try writePlist(
            [
                "CFBundleIdentifier": "com.example.demo.helper",
                "CFBundleName": "Demo Helper",
                "CFBundleExecutable": "Helper",
                "CFBundlePackageType": "APPL",
            ],
            to: demo.appending(path: "Contents/Library/LoginItems/Helper.app/Contents/Info.plist")
        )
        let apple = applications.appending(path: "AppleLike.app")
        try writePlist(
            [
                "CFBundleIdentifier": "com.apple.fake",
                "CFBundleName": "AppleLike",
                "CFBundleExecutable": "AppleLike",
                "CFBundlePackageType": "APPL",
            ],
            to: apple.appending(path: "Contents/Info.plist")
        )

        let catalog = ApplicationCatalog(
            locations: ScanLocations(home: root, applicationDirectories: [applications], includeSystemRoots: false)
        )
        let apps = await catalog.scan()
        #expect(apps.count == 2)
        let demoApp = try #require(apps.first { $0.bundleIdentifier == "com.example.demo" })
        #expect(demoApp.version == "1.2")
        #expect(demoApp.identifiers.contains("com.example.demo.helper"))
        #expect(demoApp.protection == nil)
        let appleApp = try #require(apps.first { $0.bundleIdentifier == "com.apple.fake" })
        #expect(appleApp.protection == .system)
    }

    @Test func `reads a wrapped app whose Info plist is not in Contents`() throws {
        let root = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: root) }
        let wrapped = root.appending(path: "Wrapped.app/Wrapper/Inner.app/Info.plist")
        try writePlist(
            [
                "CFBundleIdentifier": "com.example.wrapped",
                "CFBundleName": "Inner",
                "CFBundleDisplayName": "套壳",
                "CFBundleShortVersionString": "3.2",
            ],
            to: wrapped
        )
        try writePlist(
            [
                "CFBundleIdentifier": "com.example.wrapped.share",
                "CFBundleName": "Share",
                "CFBundlePackageType": "XPC!",
            ],
            to: wrapped.deletingLastPathComponent().appending(path: "PlugIns/Share.appex/Info.plist")
        )
        let app = InstalledApp.make(from: root.appending(path: "Wrapped.app"))
        #expect(app.bundleIdentifier == "com.example.wrapped")
        #expect(app.name == "套壳")
        #expect(app.version == "3.2")
        #expect(app.identifiers.contains("com.example.wrapped.share"))
    }
}
