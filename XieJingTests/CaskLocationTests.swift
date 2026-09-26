import Foundation
import Testing
@testable import XieJingCore

struct CaskLocationTests {
    @Test func `finds the Homebrew version directory behind an Applications symlink`() throws {
        let root = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: root) }
        let target = root.appending(path: "Caskroom/demo/1.0/Demo.app/Contents", directoryHint: .isDirectory)
        try makeDirectory(target)
        let applications = root.appending(path: "Applications", directoryHint: .isDirectory)
        try makeDirectory(applications)
        let link = applications.appending(path: "Demo.app")
        try FileManager.default.createSymbolicLink(
            at: link,
            withDestinationURL: root.appending(path: "Caskroom/demo/1.0/Demo.app")
        )
        let version = CaskLocation.versionDirectory(containing: link)
        #expect(version?.lastPathComponent == "1.0")
    }
}
