import SwiftUI
import XieJingCore

struct AppSidebar: View {
    @Environment(LibraryModel.self) private var library

    var body: some View {
        @Bindable var library = library
        VStack(spacing: 0) {
            CategoryFilterBar()
            Divider()
            Group {
            if library.phase == .loading, library.apps.isEmpty {
                ProgressView("正在扫描应用")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if library.apps.isEmpty, library.phase == .ready {
                ContentUnavailableView(
                    "没有找到应用",
                    systemImage: "magnifyingglass",
                    description: Text("macclear 查看了“应用程序”和“系统应用程序”文件夹。")
                )
            } else if library.sidebarIsEmpty, !library.query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                ContentUnavailableView.search
            } else if library.sidebarIsEmpty {
                ContentUnavailableView(
                    "这个分类里没有应用",
                    systemImage: "square.grid.2x2",
                    description: Text("系统应用不能卸载，已单独放在「系统应用」里。")
                )
            } else {
                List(selection: $library.selection) {
                    ForEach(library.sidebarSections) { section in
                        if !section.apps.isEmpty {
                            Section(section.title) {
                                ForEach(section.apps) { app in
                                    AppRow(app: app, isRunning: library.isRunning(app))
                                        .tag(app.id)
                                }
                            }
                        }
                    }
                }
                .listStyle(.sidebar)
            }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .navigationTitle("macclear")
        .navigationSubtitle(library.categoryFilter == "system" ? "\(library.protectedApps.count) 个系统应用" : "\(library.uninstallableCount) 个可卸载")
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
