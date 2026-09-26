import Foundation

public struct LeftoverReport: Sendable, Hashable {
    public var items: [RelatedItem]
    public var dockShortcuts: [DockShortcut]
    public var didTruncate: Bool

    public init(items: [RelatedItem], dockShortcuts: [DockShortcut] = [], didTruncate: Bool) {
        self.items = items
        self.dockShortcuts = dockShortcuts
        self.didTruncate = didTruncate
    }
}
