import Foundation

public struct TrashUninstaller: Sendable {
    public var policy: PathPolicy

    public init(policy: PathPolicy) {
        self.policy = policy
    }

    /// 只要有一条路径不在允许范围内，就整批取消，不会先删掉其中一部分。
    public func trash(_ urls: [URL]) throws -> TrashReport {
        var seen = Set<String>()
        var unique: [URL] = []
        for url in urls {
            let path = url.standardizedFileURL.path
            guard seen.insert(path).inserted else { continue }
            guard policy.isTrashable(url) else { throw TrashError.blocked(url) }
            unique.append(url)
        }
        let ordered = unique.sorted { $0.standardizedFileURL.path.count > $1.standardizedFileURL.path.count }
        var moved: [URL] = []
        var failures: [TrashFailure] = []
        let fileManager = FileManager.default
        for url in ordered {
            if !itemExists(url, fileManager: fileManager) {
                moved.append(url)
                continue
            }
            do {
                try fileManager.trashItem(at: url, resultingItemURL: nil)
                moved.append(url)
            } catch {
                failures.append(TrashFailure(url: url, message: error.localizedDescription))
            }
        }
        return TrashReport(moved: moved, failures: failures)
    }

    /// `fileExists` 会跟着符号链接走，断掉的链接会被误判成“已经不在”。这里先看链接本身在不在。
    private func itemExists(_ url: URL, fileManager: FileManager) -> Bool {
        if let values = try? url.resourceValues(forKeys: [.isSymbolicLinkKey, .fileResourceIdentifierKey]) {
            if values.isSymbolicLink == true { return true }
            if values.fileResourceIdentifier != nil { return true }
        }
        return fileManager.fileExists(atPath: url.path)
    }
}
