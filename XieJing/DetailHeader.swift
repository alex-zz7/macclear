import AppKit
import SwiftUI
import XieJingCore

struct DetailHeader: View {
    let app: InstalledApp
    let isRunning: Bool
    let openApp: () -> Void
    let reveal: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: Metrics.section) {
            Image(nsImage: NSWorkspace.shared.icon(forFile: app.url.path))
                .resizable()
                .frame(width: Metrics.heroIcon, height: Metrics.heroIcon)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: Metrics.compact) {
                HStack(alignment: .firstTextBaseline, spacing: Metrics.compact) {
                    Text(app.name)
                        .font(.title2)
                        .bold()
                    if isRunning {
                        Label("运行中", systemImage: "circle.fill")
                            .font(.callout)
                            .foregroundStyle(.orange)
                            .imageScale(.small)
                            .accessibilityLabel("正在运行")
                    }
                }
                Text(meta)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                Text(app.bundleIdentifier ?? "无 Bundle ID")
                    .font(.callout.monospaced())
                    .foregroundStyle(.secondary)
                    .textSelection(.enabled)
                Text(Format.path(app.url))
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .textSelection(.enabled)
                    .lineLimit(2)
                    .truncationMode(.middle)
                HStack(spacing: Metrics.compact) {
                    Button("打开", systemImage: "arrow.up.forward.app", action: openApp)
                    Button("在 Finder 中显示", systemImage: "folder", action: reveal)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(Metrics.section)
    }

    private var meta: String {
        var parts: [String] = []
        if let version = app.version { parts.append("版本 \(version)") }
        if let byteCount = app.byteCount { parts.append(Format.bytes(byteCount)) }
        return parts.joined(separator: " · ")
    }
}
