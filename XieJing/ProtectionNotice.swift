import SwiftUI
import XieJingCore

struct ProtectionNotice: View {
    let app: InstalledApp

    var body: some View {
        switch app.protection {
        case .itself:
            ContentUnavailableView(
                "这是 macclear 自己",
                systemImage: "lock",
                description: Text("要删除 macclear，在 Finder 里把它移到废纸篓。macclear 不会卸载自己。")
            )
        case .system:
            ContentUnavailableView(
                "系统应用受保护",
                systemImage: "lock",
                description: Text("「\(app.name)」随 macOS 提供。macclear 不会删除它，也不会动它的系统文件。")
            )
        case nil:
            EmptyView()
        }
    }
}
