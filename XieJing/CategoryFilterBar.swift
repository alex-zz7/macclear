import SwiftUI
import XieJingCore

struct CategoryFilterBar: View {
    @Environment(LibraryModel.self) private var library

    var body: some View {
        @Bindable var library = library
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 76), spacing: Metrics.compact)], alignment: .leading, spacing: Metrics.compact) {
            ForEach(chips) { chip in
                Button(chip.title) {
                    library.categoryFilter = chip.id
                }
                .buttonStyle(.bordered)
                .buttonBorderShape(.capsule)
                .controlSize(.small)
                .tint(library.categoryFilter == chip.id ? Color.accentColor : Color.secondary)
            }
        }
        .padding(Metrics.compact)
    }

    private var chips: [CategoryChip] {
        var items = [
            CategoryChip(id: "all", title: "全部"),
            CategoryChip(id: "uninstallable", title: "可卸载"),
            CategoryChip(id: "system", title: "系统应用"),
            CategoryChip(id: "running", title: "正在运行"),
        ]
        items.append(contentsOf: library.storeGroupsInUse.map { group in
            CategoryChip(id: group.rawValue, title: group.title)
        })
        return items
    }
}
