import SwiftUI

struct UninstallBar: View {
    @Environment(LibraryModel.self) private var library
    @State private var isConfirming = false

    var body: some View {
        HStack(alignment: .center, spacing: Metrics.regular) {
            Text(library.statusLine)
                .font(.callout)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: Metrics.compact)
            Button("只选确定项", action: library.selectCertain)
                .disabled(library.detailPhase != .ready || library.isUninstalling)
            Button("全选", action: library.selectAll)
                .disabled(library.items.isEmpty || library.isUninstalling)
            Button(role: .destructive, action: requestUninstall) {
                if library.isUninstalling {
                    ProgressView()
                        .controlSize(.small)
                } else {
                    Label("移到废纸篓", systemImage: "trash")
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(!library.canUninstall)
            .keyboardShortcut(.delete, modifiers: .command)
            .help("把勾选的文件移到废纸篓")
            .confirmationDialog(
                "移到废纸篓？",
                isPresented: $isConfirming,
                titleVisibility: .visible
            ) {
                Button("移到废纸篓", role: .destructive, action: uninstall)
                Button("取消", role: .cancel) {}
            } message: {
                Text(library.confirmationMessage)
            }
        }
        .padding(Metrics.section)
        .background(.bar)
    }

    private func requestUninstall() {
        isConfirming = true
    }

    private func uninstall() {
        Task {
            await library.uninstallSelected()
        }
    }
}
