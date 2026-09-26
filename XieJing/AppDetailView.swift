import SwiftUI
import XieJingCore

struct AppDetailView: View {
    @Environment(LibraryModel.self) private var library

    var body: some View {
        if let app = library.selectedApp {
            VStack(spacing: 0) {
                DetailHeader(
                    app: app,
                    isRunning: library.isRunning(app),
                    openApp: { library.open(app) },
                    reveal: { library.reveal(app) }
                )
                Divider()
                if app.isProtected {
                    ProtectionNotice(app: app)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if library.detailPhase == .loading, library.items.isEmpty {
                    ProgressView("正在查找残留文件")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if library.items.isEmpty {
                    ContentUnavailableView(
                        "没有找到额外文件",
                        systemImage: "checkmark.circle",
                        description: Text("卸载时只会移走应用本身。")
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    RelatedItemList()
                }
                if !app.isProtected {
                    Divider()
                    UninstallBar()
                }
            }
            .navigationTitle(app.name)
        } else {
            EmptyDetailView()
                .navigationTitle("卸净")
        }
    }
}
