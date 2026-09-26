import Foundation
import Testing
@testable import XieJingCore

struct ItemDeduperTests {
    @Test func `keeps a parent directory and a separate symlink`() {
        let parent = URL(fileURLWithPath: "/opt/homebrew/Caskroom/demo/1.0")
        let child = parent.appending(path: "Demo.app")
        let symlink = URL(fileURLWithPath: "/Applications/Demo.app")
        let items = [
            RelatedItem(url: child, category: .application, confidence: .certain, byteCount: nil),
            RelatedItem(url: parent, category: .application, confidence: .certain, byteCount: nil),
            RelatedItem(url: symlink, category: .application, confidence: .certain, byteCount: nil),
        ]
        let kept = Set(ItemDeduper.dedupe(items).map(\.id))
        #expect(kept.contains(parent.standardizedFileURL.path))
        #expect(kept.contains(symlink.standardizedFileURL.path))
        #expect(!kept.contains(child.standardizedFileURL.path))
    }
}
