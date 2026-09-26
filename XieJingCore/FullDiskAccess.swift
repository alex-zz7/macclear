import Foundation

public enum FullDiskAccess {
    /// 系统目录里的 TCC.db 即使用完全磁盘访问也打不开。要看用户自己这份，或 Safari 书签这类同样被这项权限挡住的文件。
    public static func isGranted() -> Bool {
        isGranted(probing: defaultProbes)
    }

    static func isGranted(probing urls: [URL], canRead: (URL) -> Bool = canRead) -> Bool {
        let existing = urls.filter { FileManager.default.fileExists(atPath: $0.path) }
        guard !existing.isEmpty else { return false }
        return existing.contains(where: canRead)
    }

    static var defaultProbes: [URL] {
        let home = FileManager.default.homeDirectoryForCurrentUser
        return [
            home.appending(path: "Library/Application Support/com.apple.TCC/TCC.db"),
            home.appending(path: "Library/Safari/Bookmarks.plist"),
        ]
    }

    static func canRead(_ url: URL) -> Bool {
        do {
            let handle = try FileHandle(forReadingFrom: url)
            try handle.close()
            return true
        } catch {
            return false
        }
    }
}
