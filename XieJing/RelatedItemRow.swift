import SwiftUI
import XieJingCore

struct RelatedItemRow: View {
    let item: RelatedItem
    let isChecked: Bool
    let onToggle: (Bool) -> Void
    let reveal: () -> Void

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: Metrics.compact) {
            Toggle(isOn: Binding {
                isChecked
            } set: { newValue in
                onToggle(newValue)
            }) {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: Metrics.compact) {
                        Text(item.url.lastPathComponent)
                            .lineLimit(1)
                        if item.confidence == .likely {
                            Label("可能相关", systemImage: "questionmark.circle")
                                .font(.callout)
                                .foregroundStyle(.secondary)
                                .labelStyle(.titleAndIcon)
                        }
                    }
                    Text(Format.path(item.url))
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .textSelection(.enabled)
                }
            }
            .toggleStyle(.checkbox)
            Spacer(minLength: Metrics.compact)
            Text(item.byteCount.map(Format.bytes) ?? "大小未知")
                .font(.callout)
                .foregroundStyle(.secondary)
                .monospacedDigit()
        }
        .contextMenu {
            Button("在 Finder 中显示", action: reveal)
        }
    }
}
