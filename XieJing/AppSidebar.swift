import SwiftUI
import XieJingCore

struct AppSidebar: View {
    @Environment(LibraryModel.self) private var library

    var body: some View {
        @Bindable var library = library
        Group {
            if library.phase == .loading, library.apps.isEmpty {
                ProgressView("正在扫描应用")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if library.apps.isEmpty, library.phase == .ready {
                ContentUnavailableView(
                    "没有找到应用",
                    systemImage: "magnifyingglass",
                    description: Text("卸净查看了“应用程序”和“系统应用程序”文件夹。")
                )
            } else if library.filteredApps.isEmpty {
                ContentUnavailableView.search
            } else {
                List(selection: $library.selection) {
                    Section("可卸载 \(library.uninstallableApps.count)") {
                        ForEach(library.uninstallableApps) { app in
                            AppRow(app: app, isRunning: library.isRunning(app))
                                .tag(app.id)
                        }
                    }
                    if !library.protectedApps.isEmpty {
                        Section("系统应用 \(library.protectedApps.count)") {
                            ForEach(library.protectedApps) { app in
                                AppRow(app: app, isRunning: library.isRunning(app))
                                    .tag(app.id)
                            }
                        }
                    }
                }
                .listStyle(.sidebar)
            }
        }
        .navigationTitle("卸净")
        .navigationSubtitle("\(library.uninstallableCount) 个可卸载")
        .searchable(text: $library.query, prompt: "搜索名称或 Bundle ID")
        .toolbar {
            ToolbarItem {
                Picker("排序", selection: $library.sort) {
                    ForEach(AppSort.allCases) { sort in
                        Text(sort.title).tag(sort)
                    }
                }
                .pickerStyle(.menu)
                .fixedSize()
            }
            ToolbarItem {
                Button("重新扫描", systemImage: "arrow.clockwise", action: library.refresh)
                    .labelStyle(.iconOnly)
                    .keyboardShortcut("r", modifiers: .command)
                    .disabled(library.phase == .loading)
                    .help("重新扫描")
            }
        }
    }
}
