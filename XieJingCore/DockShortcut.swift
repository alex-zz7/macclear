import Foundation

public struct DockShortcut: Identifiable, Hashable, Sendable {
    public var label: String
    public var bundleIdentifier: String?
    public var filePath: String?
    /// `persistent-apps` 是固定在程序坞上的图标，`recent-apps` 是最近使用。
    public var listKey: String

    public init(label: String, bundleIdentifier: String?, filePath: String?, listKey: String) {
        self.label = label
        self.bundleIdentifier = bundleIdentifier
        self.filePath = filePath
        self.listKey = listKey
    }

    public var id: String {
        "\(listKey)|\(bundleIdentifier?.lowercased() ?? "")|\(filePath ?? "")"
    }
}
