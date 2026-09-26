import SwiftUI
import XieJingCore

struct AppDetailView: View {
    @Environment(LibraryModel.self) private var library
    @State private var isConfirming = false

    var body: some View {
        if let app = library.selectedApp {
            GeometryReader { proxy in
                VStack(spacing: 0) {
                    DetailHeader(
                        app: app,
                        isRunning: library.isRunning(app),
                        openApp: { library.open(app) },
                        reveal: { library.reveal(app) }
                    )
                    Divider()
                    detail(for: app)
                    if !app.isProtected {
                        Divider()
                        UninstallBar(isConfirming: $isConfirming)
                    }
                }
                .frame(width: proxy.size.width, height: proxy.size.height, alignment: .top)
            }
            .toolbar {
                if !app.isProtected {
                    ToolbarItem(placement: .primaryAction) {
                        Button(library.uninstallButtonTitle, systemImage: "trash", action: requestUninstall)
                            .labelStyle(.titleAndIcon)
                            .disabled(!library.canUninstall || library.isUninstalling)
                    }
                }
            }
            .navigationTitle(app.name)
        } else {
            EmptyDetailView()
                .navigationTitle("macclear")
        }
    }

    private func requestUninstall() {
        isConfirming = true
    }

    private func detail(for app: InstalledApp) -> some View {
        Group {
            if app.isProtected {
                ProtectionNotice(app: app)
            } else if library.detailPhase == .loading, library.items.isEmpty, library.dockShortcuts.isEmpty {
                ProgressView("正在查找残留文件")
            } else if library.items.isEmpty, library.dockShortcuts.isEmpty {
                ContentUnavailableView(
                    "没有找到额外文件",
                    systemImage: "checkmark.circle",
                    description: Text("卸载时只会移走应用本身。")
                )
            } else {
                RelatedItemList()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
