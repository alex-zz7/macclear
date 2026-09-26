import Foundation
import Testing
@testable import XieJingCore

struct TrashUninstallerTests {
    @Test func `refuses the whole batch when one path is outside the allowed directories`() throws {
        let root = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: root) }
        let kept = root.appending(path: "kept.txt")
        try Data("keep".utf8).write(to: kept)
        let policy = PathPolicy(allowedPrefixes: ["/Applications/"], blockedExact: ["/Applications"])
        let uninstaller = TrashUninstaller(policy: policy)

        #expect(throws: TrashError.self) {
            try uninstaller.trash([kept])
        }
        #expect(FileManager.default.fileExists(atPath: kept.path))
    }

    @Test func `moves an allowed file to the trash and leaves a symlink target in place`() throws {
        let root = try makeTemporaryDirectory().standardizedFileURL
        defer { try? FileManager.default.removeItem(at: root) }
        let file = root.appending(path: "XieJing-unit-test-file.txt")
        try Data("bye".utf8).write(to: file)
        let target = root.appending(path: "XieJing-unit-test-target.txt")
        try Data("stay".utf8).write(to: target)
        let link = root.appending(path: "XieJing-unit-test-link")
        try FileManager.default.createSymbolicLink(at: link, withDestinationURL: target)

        let resolved = root.resolvingSymlinksInPath().standardizedFileURL.path
        var prefixes = [root.path + "/"]
        if resolved != root.path {
            prefixes.append(resolved + "/")
        }
        let uninstaller = TrashUninstaller(policy: PathPolicy(allowedPrefixes: prefixes, blockedExact: [root.path, resolved]))
        let report = try uninstaller.trash([file, link])
        #expect(report.failures.isEmpty)
        #expect(!FileManager.default.fileExists(atPath: file.path))
        #expect(FileManager.default.fileExists(atPath: target.path))
        removeTrashArtifacts()
    }

    private func removeTrashArtifacts() {
        let trash = FileManager.default.homeDirectoryForCurrentUser.appending(path: ".Trash")
        guard let children = try? FileManager.default.contentsOfDirectory(at: trash, includingPropertiesForKeys: nil) else { return }
        for child in children where child.lastPathComponent.contains("XieJing-unit-test") {
            try? FileManager.default.removeItem(at: child)
        }
    }
}
