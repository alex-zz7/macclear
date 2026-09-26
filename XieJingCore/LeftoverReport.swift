import Foundation

public struct LeftoverReport: Sendable, Hashable {
    public var items: [RelatedItem]
    public var didTruncate: Bool

    public init(items: [RelatedItem], didTruncate: Bool) {
        self.items = items
        self.didTruncate = didTruncate
    }
}
