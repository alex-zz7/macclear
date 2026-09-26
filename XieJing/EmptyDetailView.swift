import SwiftUI

struct EmptyDetailView: View {
    var body: some View {
        ContentUnavailableView(
            "选择一个应用",
            systemImage: "app.dashed",
            description: Text("系统的“移到废纸篓”通常只带走应用本身。macclear 会同时找出偏好设置、支持文件、缓存、容器、登录项和安装收据。默认只勾选 Bundle ID 能对上的文件；仅名称相同的会标成“可能相关”，确认后才会删除。所有内容都进废纸篓，可以恢复。")
        )
    }
}
