import SwiftUI
import XieJingCore

struct ProtectionNotice: View {
    let app: InstalledApp

    var body: some View {
        switch app.protection {
        case .itself:
            ContentUnavailableView(
                "这是卸净自己",
                systemImage: "lock",
                description: Text("要删除卸净，在 Finder 里把它移到废纸篓。卸净不会卸载自己。")
            )
        case .system:
            ContentUnavailableView(
                "系统应用受保护",
                systemImage: "lock",
                description: Text("「\(app.name)」随 macOS 提供。卸净不会删除它，也不会动它的系统文件。")
            )
        case nil:
            EmptyView()
        }
    }
}
