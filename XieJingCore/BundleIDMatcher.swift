import Foundation

public struct BundleIDMatcher: Sendable, Equatable {
    public var identifiers: [String]

    public init(identifiers: [String]) {
        self.identifiers = identifiers
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }
            .filter { $0.contains(".") }
    }

    /// 文件名按点切开后，必须从开头对上 Bundle ID。
    /// 文件名前面可以连续去掉 `group` 或 10 位带数字的 Team ID。`com.example.demo` 不会命中 `com.example.demolition`。
    public func matches(filename: String) -> Bool {
        var parts = FilenameStem.stem(of: filename).split(separator: ".").map { $0.lowercased() }
        while let first = parts.first, first == "group" || Self.isTeamID(first) {
            parts.removeFirst()
        }
        for identifier in identifiers {
            let idParts = identifier.split(separator: ".").map(String.init)
            guard idParts.count >= 2, parts.count >= idParts.count else { continue }
            if Array(parts.prefix(idParts.count)) == idParts {
                return true
            }
        }
        return false
    }

    public static func isTeamID(_ value: String) -> Bool {
        value.count == 10
            && value.allSatisfy { $0.isLetter || $0.isNumber }
            && value.contains(where: \.isNumber)
    }
}
