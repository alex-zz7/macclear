import Foundation

public enum ItemDeduper {
    /// 父目录已经在列表里时，丢掉它里面的子项，避免先删子项再删父目录。
    public static func dedupe(_ items: [RelatedItem]) -> [RelatedItem] {
        let sorted = items.sorted { lhs, rhs in
            let left = lhs.url.standardizedFileURL.path
            let right = rhs.url.standardizedFileURL.path
            if left.count != right.count { return left.count < right.count }
            return left < right
        }
        var kept: [RelatedItem] = []
        for item in sorted {
            let path = item.url.standardizedFileURL.path
            if let index = kept.firstIndex(where: { existing in
                let parent = existing.url.standardizedFileURL.path
                return path == parent || path.hasPrefix(parent + "/")
            }) {
                if path == kept[index].id, item.confidence > kept[index].confidence {
                    kept[index] = item
                }
                continue
            }
            kept.append(item)
        }
        return kept
    }
}
