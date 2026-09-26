import AppKit
import SwiftUI

struct ContentView: View {
    @State private var library = LibraryModel()
    @State private var isShowingNotice = false
    @State private var noticeTitle = ""
    @State private var noticeMessage = ""

    var body: some View {
        VStack(spacing: 0) {
            if library.showPermissionBanner {
                PermissionBanner(
                    onOpenSettings: library.openFullDiskAccessSettings,
                    onDismiss: library.dismissPermissionBanner
                )
                .padding(Metrics.regular)
            }
            NavigationSplitView {
                AppSidebar()
                    .navigationSplitViewColumnWidth(min: 260, ideal: 300, max: 420)
            } detail: {
                AppDetailView()
            }
        }
        .environment(library)
        .task {
            library.start()
        }
        .onChange(of: library.selection) {
            library.loadDetails()
        }
        .onChange(of: library.notice?.id) {
            guard let notice = library.notice else { return }
            noticeTitle = notice.title
            noticeMessage = notice.message
            isShowingNotice = true
        }
        .onReceive(NSWorkspace.shared.notificationCenter.publisher(for: NSWorkspace.didLaunchApplicationNotification)) { _ in
            library.refreshRunning()
        }
        .onReceive(NSWorkspace.shared.notificationCenter.publisher(for: NSWorkspace.didTerminateApplicationNotification)) { _ in
            library.refreshRunning()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            library.recheckAccess()
        }
        .alert(noticeTitle, isPresented: $isShowingNotice) {
            Button("好") {}
        } message: {
            Text(noticeMessage)
        }
        .frame(minWidth: 880, minHeight: 540)
    }
}
