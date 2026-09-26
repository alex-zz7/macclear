import Foundation
import Testing
@testable import XieJingCore

struct FullDiskAccessTests {
    @Test func `missing probe files are not treated as permission granted`() {
        let missing = URL(fileURLWithPath: "/tmp/macclear-fda-missing-\(UUID().uuidString)")
        #expect(!FullDiskAccess.isGranted(probing: [missing], canRead: { _ in true }))
    }

    @Test func `an existing file the process cannot read means permission is off`() throws {
        let url = try makeTemporaryDirectory().appending(path: "probe")
        defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }
        try Data("x".utf8).write(to: url)
        #expect(!FullDiskAccess.isGranted(probing: [url], canRead: { _ in false }))
    }

    @Test func `an existing readable file means permission is on`() throws {
        let url = try makeTemporaryDirectory().appending(path: "probe")
        defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }
        try Data("x".utf8).write(to: url)
        #expect(FullDiskAccess.isGranted(probing: [url], canRead: { _ in true }))
    }
}
