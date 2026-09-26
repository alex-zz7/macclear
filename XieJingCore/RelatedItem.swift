import Foundation

public struct RelatedItem: Identifiable, Hashable, Sendable {
    public var url: URL
    public var category: ItemCategory
    public var confidence: MatchConfidence
    public var byteCount: Int64?

    public init(url: URL, category: ItemCategory, confidence: MatchConfidence, byteCount: Int64?) {
        self.url = url
        self.category = category
        self.confidence = confidence
        self.byteCount = byteCount
    }

    public var id: String { url.standardizedFileURL.path }
}
