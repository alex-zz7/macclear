import Foundation

public enum FullDiskAccess {
    public static func isGranted() -> Bool {
        FileManager.default.isReadableFile(
            atPath: "/Library/Application Support/com.apple.TCC/TCC.db"
        )
    }
}
