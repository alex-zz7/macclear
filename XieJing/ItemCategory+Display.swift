import SwiftUI
import XieJingCore

extension ItemCategory {
    var title: String {
        switch self {
        case .application: "应用"
        case .preferences: "偏好设置"
        case .applicationSupport: "支持文件"
        case .containers: "容器"
        case .groupContainers: "组容器"
        case .caches: "缓存"
        case .savedState: "已保存的状态"
        case .logs: "日志"
        case .launchAgents: "登录项与后台代理"
        case .receipts: "安装收据"
        case .plugIns: "插件"
        case .other: "其他"
        }
    }

    var symbolName: String {
        switch self {
        case .application: "macwindow"
        case .preferences: "gearshape"
        case .applicationSupport: "folder"
        case .containers: "shippingbox"
        case .groupContainers: "square.stack.3d.up"
        case .caches: "internaldrive"
        case .savedState: "arrow.counterclockwise"
        case .logs: "doc.text"
        case .launchAgents: "bolt.horizontal"
        case .receipts: "doc.plaintext"
        case .plugIns: "puzzlepiece.extension"
        case .other: "questionmark.folder"
        }
    }
}
