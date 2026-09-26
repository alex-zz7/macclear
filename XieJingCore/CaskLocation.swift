import Foundation

public enum CaskLocation {
    /// Homebrew Cask 的应用经常是 /Applications 里的符号链接，真正的文件在 Caskroom/名称/版本。
    public static func versionDirectory(containing appURL: URL) -> URL? {
        let resolved = appURL.resolvingSymlinksInPath().standardizedFileURL
        let marker = "/Caskroom/"
        let path = resolved.path
        guard let range = path.range(of: marker) else { return nil }
        let pieces = path[range.upperBound...].split(separator: "/", omittingEmptySubsequences: true)
        guard pieces.count >= 2 else { return nil }
        let version = String(path[..<range.upperBound]) + pieces[0] + "/" + pieces[1]
        let versionURL = URL(fileURLWithPath: version, isDirectory: true).standardizedFileURL
        let appPath = resolved.path
        guard appPath == versionURL.path || appPath.hasPrefix(versionURL.path + "/") else { return nil }
        guard versionURL.path != appURL.standardizedFileURL.path else { return nil }
        return versionURL
    }
}
