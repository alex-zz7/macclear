import SwiftUI
import XieJingCore

struct RelatedItemList: View {
    @Environment(LibraryModel.self) private var library

    var body: some View {
        List {
            if library.didTruncate {
                Text("匹配到的文件异常地多，只列出了一部分，避免误删。")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
            if !library.dockShortcuts.isEmpty {
                Section {
                    ForEach(library.dockShortcuts) { shortcut in
                        DockShortcutRow(
                            shortcut: shortcut,
                            isChecked: library.checkedIDs.contains(shortcut.id),
                            onToggle: { library.setChecked(shortcut.id, $0) }
                        )
                    }
                } header: {
                    Toggle(isOn: Binding(
                        get: { library.isFullyChecked(library.dockShortcuts.map(\.id)) },
                        set: { library.setChecked(library.dockShortcuts.map(\.id), $0) }
                    )) {
                        Label("Dock 快捷方式", systemImage: "dock.rectangle")
                    }
                    .toggleStyle(.checkbox)
                }
            }
            ForEach(grouped, id: \.0) { category, rows in
                Section {
                    ForEach(rows) { item in
                        RelatedItemRow(
                            item: item,
                            isChecked: library.checkedIDs.contains(item.id),
                            onToggle: { library.setChecked(item.id, $0) },
                            reveal: { library.reveal(item.url) }
                        )
                    }
                } header: {
                    Toggle(isOn: Binding(
                        get: { library.isFullyChecked(library.itemIDs(in: category)) },
                        set: { library.setChecked(library.itemIDs(in: category), $0) }
                    )) {
                        Label(category.title, systemImage: category.symbolName)
                    }
                    .toggleStyle(.checkbox)
                }
            }
        }
        .listStyle(.inset)
    }

    private var grouped: [(ItemCategory, [RelatedItem])] {
        ItemCategory.allCases.compactMap { category in
            let rows = library.items.filter { $0.category == category }
            return rows.isEmpty ? nil : (category, rows)
        }
    }
}
