import Foundation

public enum FilenameStem {
    /// 只去掉真正的文件后缀。Bundle ID 本身含有点号，不能用 `deletingPathExtension` 把最后一节裁掉。
    public static func stem(of filename: String) -> String {
        let name = filename as NSString
        let ext = name.pathExtension.lowercased()
        guard strippedExtensions.contains(ext) else { return filename }
        return name.deletingPathExtension
    }

    public static let strippedExtensions: Set<String> = [
        "plist", "savedstate", "bom", "log", "ips", "crash", "diag", "txt", "strings", "lockfile",
    ]
}
