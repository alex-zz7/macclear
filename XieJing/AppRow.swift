import AppKit
import SwiftUI
import XieJingCore

struct AppRow: View {
    let app: InstalledApp
    let isRunning: Bool

    var body: some View {
        HStack(spacing: Metrics.compact) {
            Image(nsImage: NSWorkspace.shared.icon(forFile: app.url.path))
                .resizable()
                .frame(width: Metrics.icon, height: Metrics.icon)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(app.name)
                    .lineLimit(1)
                HStack(spacing: Metrics.compact) {
                    Text(secondary)
                        .lineLimit(1)
                    if isRunning {
                        Label("运行中", systemImage: "circle.fill")
                            .labelStyle(.titleAndIcon)
                            .imageScale(.small)
                            .accessibilityLabel("正在运行")
                    }
                }
                .font(.callout)
                .foregroundStyle(.secondary)
            }
        }
        .accessibilityElement(children: .combine)
    }

    private var secondary: String {
        var parts: [String] = []
        if let version = app.version { parts.append(version) }
        if let byteCount = app.byteCount { parts.append(Format.bytes(byteCount)) }
        switch app.protection {
        case .system:
            parts.append("系统保护")
        case .itself:
            parts.append("当前应用")
        case nil:
            break
        }
        return parts.joined(separator: " · ")
    }
}
