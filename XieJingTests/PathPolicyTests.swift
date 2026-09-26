import Foundation
import Testing
@testable import XieJingCore

struct PathPolicyTests {
    private let policy = PathPolicy.standard(home: URL(fileURLWithPath: "/Users/tester"))

    @Test func `allows leftovers under library and applications, and refuses the folders themselves`() {
        #expect(policy.isTrashable(URL(fileURLWithPath: "/Users/tester/Library/Preferences/com.foo.bar.plist")))
        #expect(!policy.isTrashable(URL(fileURLWithPath: "/Users/tester/Library/Preferences")))
        #expect(!policy.isTrashable(URL(fileURLWithPath: "/Users/tester/Library")))
        #expect(!policy.isTrashable(URL(fileURLWithPath: "/Users/tester")))
        #expect(policy.isTrashable(URL(fileURLWithPath: "/Applications/Foo.app")))
        #expect(!policy.isTrashable(URL(fileURLWithPath: "/Applications")))
        #expect(!policy.isTrashable(URL(fileURLWithPath: "/System/Applications/Foo.app")))
        #expect(policy.isTrashable(URL(fileURLWithPath: "/opt/homebrew/Caskroom/foo/1.0")))
        #expect(!policy.isTrashable(URL(fileURLWithPath: "/opt/homebrew/Caskroom")))
        #expect(!policy.isTrashable(URL(fileURLWithPath: "/tmp/foo")))
        #expect(policy.isTrashable(URL(fileURLWithPath: "/Library/LaunchAgents/com.foo.bar.plist")))
        #expect(!policy.isTrashable(URL(fileURLWithPath: "/Library/LaunchAgents")))
        #expect(!policy.isTrashable(URL(fileURLWithPath: "/Applications/../Library")))
    }

    @Test func `refuses a symlink that escapes the allowed directories`() throws {
        let root = try makeTemporaryDirectory().standardizedFileURL
        defer { try? FileManager.default.removeItem(at: root) }
        let file = root.appending(path: "ok.txt")
        try Data("ok".utf8).write(to: file)
        let escaped = root.appending(path: "escaped")
        try FileManager.default.createSymbolicLink(at: escaped, withDestinationURL: URL(fileURLWithPath: "/"))
        let inner = root.appending(path: "inner.txt")
        try Data("in".utf8).write(to: inner)
        let localLink = root.appending(path: "local")
        try FileManager.default.createSymbolicLink(at: localLink, withDestinationURL: inner)

        let resolved = root.resolvingSymlinksInPath().standardizedFileURL.path
        var prefixes = [root.path + "/"]
        var blocked: Set<String> = [root.path]
        if resolved != root.path {
            prefixes.append(resolved + "/")
            blocked.insert(resolved)
        }
        let localPolicy = PathPolicy(allowedPrefixes: prefixes, blockedExact: blocked)

        #expect(localPolicy.isTrashable(file))
        #expect(localPolicy.isTrashable(localLink))
        #expect(!localPolicy.isTrashable(escaped))
        #expect(!localPolicy.isTrashable(root))
    }
}
