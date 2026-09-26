import SwiftUI
import XieJingCore

struct DockShortcutRow: View {
    let shortcut: DockShortcut
    let isChecked: Bool
    let onToggle: (Bool) -> Void

    var body: some View {
        Toggle(isOn: Binding {
            isChecked
        } set: { newValue in
            onToggle(newValue)
        }) {
            VStack(alignment: .leading, spacing: 2) {
                Text(shortcut.label)
                    .lineLimit(1)
                Text(detail)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
        }
        .toggleStyle(.checkbox)
    }

    private var detail: String {
        if let identifier = shortcut.bundleIdentifier, !identifier.isEmpty {
            return identifier
        }
        return shortcut.filePath ?? "程序坞图标"
    }
}
