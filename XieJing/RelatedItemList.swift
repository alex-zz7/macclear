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
                    Label(category.title, systemImage: category.symbolName)
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
