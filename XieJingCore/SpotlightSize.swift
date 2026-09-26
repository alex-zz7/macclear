import CoreServices
import Foundation

public enum SpotlightSize {
    /// Spotlight 已经索引过的体积，用来给列表一个估计值，避免启动时遍历每个应用。
    public static func byteCount(of url: URL) -> Int64? {
        guard let item = MDItemCreateWithURL(kCFAllocatorDefault, url as CFURL) else { return nil }
        guard let raw = MDItemCopyAttribute(item, "kMDItemPhysicalSize" as CFString) else { return nil }
        return (raw as? NSNumber)?.int64Value
    }
}
