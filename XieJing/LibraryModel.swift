import AppKit
import SwiftUI
import XieJingCore

@Observable
final class LibraryModel {
    private(set) var apps: [InstalledApp] = []
    private(set) var phase: LoadPhase = .idle
    var selection: InstalledApp.ID?
    var query = ""
    var sort: AppSort = .name
    var categoryFilter = "all"
    private(set) var items: [RelatedItem] = []
    private(set) var dockShortcuts: [DockShortcut] = []
    var checkedIDs: Set<String> = []
    private(set) var detailPhase: LoadPhase = .idle
    private(set) var didTruncate = false
    private(set) var hasFullDiskAccess = true
    var dismissedPermissionBanner = false
    private(set) var notice: LibraryAlert?
    private(set) var isUninstalling = false
    private(set) var runningBundleIDs: Set<String> = []
    private(set) var runningPaths: Set<String> = []

    private var didStart = false
    private var scanToken = 0
    private var detailToken = 0
    private var detailTask: Task<Void, Never>?
    private let locations: ScanLocations
    private let catalog: ApplicationCatalog
    private let finder: LeftoverFinder

    init() {
        let locations = ScanLocations.live()
        self.locations = locations
        catalog = ApplicationCatalog(locations: locations)
        finder = LeftoverFinder(locations: locations)
    }

    var showPermissionBanner: Bool {
        !hasFullDiskAccess && !dismissedPermissionBanner && phase == .ready
    }

    var uninstallableCount: Int {
        apps.filter { !$0.isProtected }.count
    }

    var filteredApps: [InstalledApp] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        let matched: [InstalledApp]
        if trimmed.isEmpty {
            matched = apps
        } else {
            matched = apps.filter { app in
                app.name.localizedStandardContains(trimmed)
                    || app.bundleIdentifier?.localizedStandardContains(trimmed) == true
                    || app.url.path.localizedStandardContains(trimmed)
            }
        }
        return matched.sorted(by: sortApps)
    }

    var uninstallableApps: [InstalledApp] {
        filteredApps.filter { !$0.isProtected }
    }

    var protectedApps: [InstalledApp] {
        filteredApps.filter(\.isProtected)
    }

    var runningApps: [InstalledApp] {
        filteredApps.filter { isRunning($0) }
    }

    var storeGroupsInUse: [StoreCategoryGroup] {
        let present = Set(apps.filter { !$0.isProtected }.map { StoreCategoryGroup.group(for: $0.storeCategory) })
        return StoreCategoryGroup.allCases.filter { present.contains($0) }
    }

    var sidebarSections: [AppListSection] {
        switch categoryFilter {
        case "uninstallable":
            return [AppListSection(title: "可卸载 \(uninstallableApps.count)", apps: uninstallableApps)]
        case "system":
            return [AppListSection(title: "系统应用 \(protectedApps.count)", apps: protectedApps)]
        case "running":
            return [AppListSection(title: "正在运行 \(runningApps.count)", apps: runningApps)]
        case "all":
            var sections = [AppListSection(title: "可卸载 \(uninstallableApps.count)", apps: uninstallableApps)]
            if !protectedApps.isEmpty {
                sections.append(AppListSection(title: "系统应用 \(protectedApps.count)", apps: protectedApps))
            }
            return sections
        default:
            let matched = uninstallableApps.filter {
                StoreCategoryGroup.group(for: $0.storeCategory).rawValue == categoryFilter
            }
            let title = StoreCategoryGroup(rawValue: categoryFilter)?.title ?? "分类"
            return [AppListSection(title: "\(title) \(matched.count)", apps: matched)]
        }
    }

    var sidebarIsEmpty: Bool {
        sidebarSections.allSatisfy { $0.apps.isEmpty }
    }

    var selectedApp: InstalledApp? {
        guard let selection else { return nil }
        return apps.first { $0.id == selection }
    }

    var checkedItems: [RelatedItem] {
        items.filter { checkedIDs.contains($0.id) }
    }

    var uninstallButtonTitle: String {
        let files = checkedItems.count
        let docks = checkedDockShortcuts.count
        if files == 0, docks > 0 { return "移除快捷方式" }
        if docks > 0 { return "删除所选" }
        return "移到废纸篓"
    }

    var canUninstall: Bool {
        guard let app = selectedApp, !app.isProtected else { return false }
        guard detailPhase == .ready, !isUninstalling else { return false }
        return !checkedItems.isEmpty || !checkedDockShortcuts.isEmpty
    }

    var checkedDockShortcuts: [DockShortcut] {
        dockShortcuts.filter { checkedIDs.contains($0.id) }
    }

    var statusLine: String {
        if detailPhase == .loading { return "正在查找残留文件" }
        let selected = checkedItems
        let docks = checkedDockShortcuts
        let size = selected.compactMap(\.byteCount).reduce(0, +)
        var text = "已选 \(selected.count + docks.count) 项"
        if !selected.isEmpty {
            text += "，约 \(Format.bytes(size))"
            if selected.contains(where: { $0.byteCount == nil }) {
                text += "（有的文件没能算出大小）"
            }
        }
        if !docks.isEmpty {
            text += "，含 \(docks.count) 个 Dock 图标"
        }
        let heldBack = items.filter { $0.confidence == .likely && !checkedIDs.contains($0.id) }.count
        if heldBack > 0 {
            text += "。另有 \(heldBack) 项只是名称相同，尚未勾选"
        }
        return text
    }

    var confirmationMessage: String {
        guard let app = selectedApp else { return "" }
        let selected = checkedItems
        let docks = checkedDockShortcuts
        let likely = selected.filter { $0.confidence == .likely }.count
        let size = selected.compactMap(\.byteCount).reduce(0, +)
        var text = selected.isEmpty
            ? ""
            : "将把 \(selected.count) 项移到废纸篓，大约 \(Format.bytes(size))。可以从废纸篓恢复。"
        if !docks.isEmpty {
            text += "程序坞里 \(docks.count) 个对应图标会去掉，程序坞会重新打开一下。"
        }
        if likely > 0 {
            text += " 其中 \(likely) 项只是名称相同，请确认它们属于「\(app.name)」。"
        }
        if isRunning(app) {
            text += " 「\(app.name)」正在运行，会先退出它；普通退出失败时会强制退出。"
        }
        text += " 如果系统询问应用管理权限，需要允许，否则「应用程序」里的软件可能移不走。"
        return text
    }

    func start() {
        guard !didStart else { return }
        didStart = true
        refreshRunning()
        refresh()
    }

    func refresh() {
        scanToken += 1
        let token = scanToken
        phase = .loading
        Task {
            let found = await catalog.scan()
            guard token == scanToken else { return }
            apps = found
            hasFullDiskAccess = FullDiskAccess.isGranted()
            phase = .ready
            if let selection, !found.contains(where: { $0.id == selection }) {
                self.selection = nil
            }
            AppLog.library.info("Scanned \(found.count, privacy: .public) apps")
            loadDetails()
        }
    }

    func refreshRunning() {
        let running = NSWorkspace.shared.runningApplications
        runningBundleIDs = Set(running.compactMap(\.bundleIdentifier).map { $0.lowercased() })
        runningPaths = Set(running.compactMap { $0.bundleURL?.standardizedFileURL.path })
    }

    func recheckAccess() {
        hasFullDiskAccess = FullDiskAccess.isGranted()
    }

    func dismissPermissionBanner() {
        dismissedPermissionBanner = true
    }

    func isRunning(_ app: InstalledApp) -> Bool {
        if let identifier = app.bundleIdentifier, runningBundleIDs.contains(identifier.lowercased()) {
            return true
        }
        return runningPaths.contains(app.url.standardizedFileURL.path)
    }

    func loadDetails() {
        detailTask?.cancel()
        detailToken += 1
        let token = detailToken
        guard let app = selectedApp else {
            items = []
            dockShortcuts = []
            checkedIDs = []
            didTruncate = false
            detailPhase = .idle
            return
        }
        if app.isProtected {
            items = []
            dockShortcuts = []
            checkedIDs = []
            didTruncate = false
            detailPhase = .ready
            return
        }
        detailPhase = .loading
        items = []
        dockShortcuts = []
        checkedIDs = []
        didTruncate = false
        detailTask = Task {
            let report = await finder.find(for: app)
            guard !Task.isCancelled, token == detailToken else { return }
            items = report.items
            dockShortcuts = report.dockShortcuts
            didTruncate = report.didTruncate
            var selected = Set(report.items.filter { $0.confidence == .certain }.map(\.id))
            selected.formUnion(report.dockShortcuts.map(\.id))
            checkedIDs = selected
            detailPhase = .ready
            AppLog.library.info("Found \(report.items.count, privacy: .public) leftovers")
        }
    }

    func setChecked(_ id: String, _ isChecked: Bool) {
        if isChecked {
            checkedIDs.insert(id)
        } else {
            checkedIDs.remove(id)
        }
    }

    func isFullyChecked(_ ids: [String]) -> Bool {
        !ids.isEmpty && ids.allSatisfy { checkedIDs.contains($0) }
    }

    func setChecked(_ ids: [String], _ isChecked: Bool) {
        if isChecked {
            checkedIDs.formUnion(ids)
        } else {
            checkedIDs.subtract(ids)
        }
    }

    func itemIDs(in category: ItemCategory) -> [String] {
        items.filter { $0.category == category }.map(\.id)
    }

    func selectCertain() {
        var selected = Set(items.filter { $0.confidence == .certain }.map(\.id))
        selected.formUnion(dockShortcuts.map(\.id))
        checkedIDs = selected
    }

    func selectAll() {
        checkedIDs = Set(items.map(\.id)).union(dockShortcuts.map(\.id))
    }

    func open(_ app: InstalledApp) {
        NSWorkspace.shared.open(app.url)
    }

    func reveal(_ app: InstalledApp) {
        reveal(app.url)
    }

    func reveal(_ url: URL) {
        NSWorkspace.shared.activateFileViewerSelecting([url])
    }

    func openFullDiskAccessSettings() {
        let candidates = [
            "x-apple.systempreferences:com.apple.settings.PrivacySecurity.extension?Privacy_AllFiles",
            "x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles",
        ]
        for candidate in candidates {
            guard let url = URL(string: candidate) else { continue }
            if NSWorkspace.shared.open(url) { return }
        }
    }

    func uninstallSelected() async {
        guard let app = selectedApp, !app.isProtected, canUninstall else { return }
        let chosen = checkedItems
        let chosenDocks = checkedDockShortcuts
        isUninstalling = true
        defer { isUninstalling = false }
        await quit(app)
        refreshRunning()
        let report: TrashReport
        do {
            if chosen.isEmpty {
                report = TrashReport(moved: [], failures: [])
            } else {
                report = try TrashUninstaller(policy: .standard(home: locations.home)).trash(chosen.map(\.url))
            }
        } catch let error as TrashError {
            switch error {
            case .blocked(let url):
                notice = LibraryAlert(
                    title: "已取消",
                    message: "为防止误删，这次没有移走任何文件。\(Format.path(url)) 不在允许卸载的目录里。"
                )
            }
            AppLog.library.error("Uninstall refused")
            return
        } catch {
            notice = LibraryAlert(title: "没能移走", message: error.localizedDescription)
            return
        }

        let dockNote = removeDockShortcuts(chosenDocks)
        if report.failures.isEmpty {
            var message = report.moved.isEmpty ? "" : "移走了 \(report.moved.count) 项。打开废纸篓可以恢复。"
            if !dockNote.isEmpty {
                message = message.isEmpty ? dockNote : message + dockNote
            }
            notice = LibraryAlert(
                title: report.moved.isEmpty ? "已清理程序坞" : "已移到废纸篓",
                message: message
            )
        } else if report.moved.isEmpty {
            notice = LibraryAlert(
                title: "没能移走",
                message: failureText(report.failures) + " 如果系统弹出了权限请求，允许之后再试一次。" + dockNote
            )
        } else {
            notice = LibraryAlert(
                title: "只移走了一部分",
                message: "已移走 \(report.moved.count) 项，\(report.failures.count) 项失败。\(failureText(report.failures))" + dockNote
            )
        }

        let movedPaths = Set(report.moved.map { $0.standardizedFileURL.path })
        if movedPaths.contains(app.id) || !FileManager.default.fileExists(atPath: app.url.path) {
            apps.removeAll { $0.id == app.id }
            selection = nil
        } else {
            loadDetails()
        }
    }

    private func quit(_ app: InstalledApp) async {
        let identifiers = Set(app.identifiers.map { $0.lowercased() })
        let path = app.url.standardizedFileURL.path
        let matches = NSWorkspace.shared.runningApplications.filter { running in
            if let identifier = running.bundleIdentifier, identifiers.contains(identifier.lowercased()) {
                return true
            }
            return running.bundleURL?.standardizedFileURL.path == path
        }
        guard !matches.isEmpty else { return }
        for running in matches where !running.isTerminated {
            running.terminate()
        }
        for _ in 0..<20 {
            if matches.allSatisfy(\.isTerminated) { return }
            try? await Task.sleep(for: .milliseconds(100))
        }
        for running in matches where !running.isTerminated {
            _ = running.forceTerminate()
        }
        try? await Task.sleep(for: .milliseconds(300))
    }

    private func removeDockShortcuts(_ shortcuts: [DockShortcut]) -> String {
        guard !shortcuts.isEmpty else { return "" }
        do {
            let removed = try DockCleaner.remove(
                Set(shortcuts.map(\.id)),
                plistURL: DockCleaner.plistURL(home: locations.home)
            )
            guard removed > 0 else { return "" }
            return "已去掉 \(removed) 个 Dock 图标。"
        } catch {
            return "Dock 图标没能去掉：\(error.localizedDescription)"
        }
    }

    private func failureText(_ failures: [TrashFailure]) -> String {
        let messages = Array(Set(failures.map(\.message))).prefix(2)
        return messages.joined(separator: " ")
    }

    private func sortApps(_ lhs: InstalledApp, _ rhs: InstalledApp) -> Bool {
        switch sort {
        case .name:
            lhs.name.localizedStandardCompare(rhs.name) == .orderedAscending
        case .size:
            (lhs.byteCount ?? -1) > (rhs.byteCount ?? -1)
        }
    }
}
