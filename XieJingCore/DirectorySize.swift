import Foundation

public enum DirectorySize {
    /// 选中某个应用后才精确累加。符号链接只算链接本身，不跟进去。
    public static func byteCount(of url: URL) -> Int64? {
        let fileManager = FileManager()
        let values = try? url.resourceValues(forKeys: [.isSymbolicLinkKey, .isDirectoryKey, .fileAllocatedSizeKey, .fileSizeKey])
        guard values != nil || fileManager.fileExists(atPath: url.path) else { return nil }
        if values?.isSymbolicLink == true {
            return Int64(values?.fileAllocatedSize ?? values?.fileSize ?? 0)
        }
        let isDirectory = values?.isDirectory ?? false
        if !isDirectory {
            let size = values?.fileAllocatedSize ?? values?.fileSize
            return size.map(Int64.init)
        }
        guard let enumerator = fileManager.enumerator(
            at: url,
            includingPropertiesForKeys: [.fileAllocatedSizeKey, .isSymbolicLinkKey, .isRegularFileKey],
            options: []
        ) else { return nil }

        var total: Int64 = 0
        var seen = 0
        while let item = enumerator.nextObject() as? URL {
            seen += 1
            if seen.isMultiple(of: 2_048), Task.isCancelled { return nil }
            if seen > 250_000 { return total }
            let itemValues = try? item.resourceValues(forKeys: [.fileAllocatedSizeKey, .isSymbolicLinkKey, .isRegularFileKey])
            if itemValues?.isSymbolicLink == true {
                enumerator.skipDescendants()
                continue
            }
            if itemValues?.isRegularFile == true {
                total += Int64(itemValues?.fileAllocatedSize ?? 0)
            }
        }
        return total
    }
}
