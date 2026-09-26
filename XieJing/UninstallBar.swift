import SwiftUI

struct UninstallBar: View {
    @Environment(LibraryModel.self) private var library
    @Binding var isConfirming: Bool

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
                .disabled((library.items.isEmpty && library.dockShortcuts.isEmpty) || library.isUninstalling)
            deleteButton
        }
        .padding(Metrics.section)
        .background(.bar)
    }

    private var deleteButton: some View {
        Button(role: .destructive, action: requestUninstall) {
            if library.isUninstalling {
                ProgressView()
                    .controlSize(.small)
            } else {
                Label(library.uninstallButtonTitle, systemImage: "trash")
            }
        }
        .buttonStyle(.borderedProminent)
        .disabled(!library.canUninstall)
        .keyboardShortcut(.delete, modifiers: .command)
        .help(library.uninstallButtonTitle)
        .confirmationDialog(
            "\(library.uninstallButtonTitle)？",
            isPresented: $isConfirming,
            titleVisibility: .visible
        ) {
            Button(library.uninstallButtonTitle, role: .destructive, action: uninstall)
            Button("取消", role: .cancel) {}
        } message: {
            Text(library.confirmationMessage)
        }
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
