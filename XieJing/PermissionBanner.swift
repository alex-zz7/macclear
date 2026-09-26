import SwiftUI

struct PermissionBanner: View {
    let onOpenSettings: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: Metrics.regular) {
            Image(systemName: "externaldrive.badge.exclamationmark")
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 4) {
                Text("完全磁盘访问权限未开启")
                    .font(.headline)
                Text("没有这项权限时，其他应用的容器、组容器和部分系统目录里的残留可能扫不出来。如果刚刚打开了开关，退出 macclear 再打开一次才会生效。")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: Metrics.compact)
            Button("前往系统设置", action: onOpenSettings)
            Button("关闭", action: onDismiss)
        }
        .padding(Metrics.regular)
        .background(.quaternary, in: RoundedRectangle(cornerRadius: Metrics.bannerCorner))
        .accessibilityElement(children: .contain)
    }
}
