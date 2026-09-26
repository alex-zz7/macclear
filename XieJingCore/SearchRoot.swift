import Foundation

public struct SearchRoot: Sendable, Hashable {
    public var url: URL
    public var category: ItemCategory
    public var rule: MatchRule
    /// 1 表示只看这一层；2 表示看下一层（音频插件这类目录）。
    public var depth: Int

    public init(url: URL, category: ItemCategory, rule: MatchRule, depth: Int = 1) {
        self.url = url
        self.category = category
        self.rule = rule
        self.depth = depth
    }
}
