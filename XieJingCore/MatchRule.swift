import Foundation

public enum MatchRule: Sendable, Hashable {
    /// 文件名里要能按组件对上 Bundle ID。容器、偏好设置、收据用这个。
    case bundleIdentifier
    /// Bundle ID 对上是确定项；显示名称完全相同只算可能相关。
    case bundleIdentifierOrExactName
    /// 崩溃报告文件名通常是「应用名_日期」。
    case crashReport
    /// 登录项要读 plist，确认里面写了这个应用的路径或 Bundle ID。
    case launchDefinition
}
