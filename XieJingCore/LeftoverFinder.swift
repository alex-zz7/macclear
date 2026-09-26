import Foundation

public struct LeftoverFinder: Sendable {
    public var locations: ScanLocations
    public var policy: PathPolicy

    public init(locations: ScanLocations, policy: PathPolicy? = nil) {
        self.locations = locations
        self.policy = policy ?? .standard(home: locations.home)
    }

    @concurrent
    public func find(for app: InstalledApp) async -> LeftoverReport {
        var items = [appBundleItem(app)]
        if let cask = caskItem(for: app) {
            items.append(cask)
        }
        let reference = AppReferenceMatcher(app: app)
        let bundleMatcher = BundleIDMatcher(identifiers: app.identifiers)
        let nameMatcher = NameMatcher(names: app.matchNames)
        for root in locations.searchRoots() {
            if Task.isCancelled { return LeftoverReport(items: [], didTruncate: false) }
            items.append(contentsOf: matches(in: root, app: app, bundleMatcher: bundleMatcher, nameMatcher: nameMatcher, reference: reference))
        }
        items.removeAll { isForeignAppleFile($0.url, app: app) || !policy.isTrashable($0.url) }
        items = ItemDeduper.dedupe(items)
        var didTruncate = false
        if items.count > 300 {
            let certain = items.filter { $0.confidence == .certain }
            if certain.count < items.count {
                items = certain
                didTruncate = true
            }
        }
        if items.count > 400 {
            items = Array(items.prefix(400))
            didTruncate = true
        }
        let sized = items.map { item in
            var copy = item
            copy.byteCount = DirectorySize.byteCount(of: item.url)
            return copy
        }
        let sorted = sized.sorted { lhs, rhs in
            if lhs.category.sortIndex != rhs.category.sortIndex {
                return lhs.category.sortIndex < rhs.category.sortIndex
            }
            if lhs.confidence != rhs.confidence {
                return lhs.confidence > rhs.confidence
            }
            return lhs.url.lastPathComponent.localizedStandardCompare(rhs.url.lastPathComponent) == .orderedAscending
        }
        return LeftoverReport(items: sorted, didTruncate: didTruncate)
    }

    private func appBundleItem(_ app: InstalledApp) -> RelatedItem {
        RelatedItem(url: app.url, category: .application, confidence: .certain, byteCount: nil)
    }

    private func caskItem(for app: InstalledApp) -> RelatedItem? {
        guard let directory = CaskLocation.versionDirectory(containing: app.url) else { return nil }
        return RelatedItem(url: directory, category: .application, confidence: .certain, byteCount: nil)
    }

    private func matches(
        in root: SearchRoot,
        app: InstalledApp,
        bundleMatcher: BundleIDMatcher,
        nameMatcher: NameMatcher,
        reference: AppReferenceMatcher
    ) -> [RelatedItem] {
        var found: [RelatedItem] = []
        for url in candidateURLs(in: root) {
            if Task.isCancelled { break }
            guard let confidence = confidence(for: url, rule: root.rule, bundleMatcher: bundleMatcher, nameMatcher: nameMatcher, reference: reference) else {
                continue
            }
            found.append(RelatedItem(url: url, category: root.category, confidence: confidence, byteCount: nil))
        }
        return found
    }

    private func confidence(
        for url: URL,
        rule: MatchRule,
        bundleMatcher: BundleIDMatcher,
        nameMatcher: NameMatcher,
        reference: AppReferenceMatcher
    ) -> MatchConfidence? {
        let filename = url.lastPathComponent
        switch rule {
        case .bundleIdentifier:
            return bundleMatcher.matches(filename: filename) ? .certain : nil
        case .bundleIdentifierOrExactName:
            if bundleMatcher.matches(filename: filename) { return .certain }
            return nameMatcher.matchesExact(filename: filename) ? .likely : nil
        case .crashReport:
            if bundleMatcher.matches(filename: filename) { return .certain }
            return nameMatcher.matchesCrashReport(filename: filename) ? .likely : nil
        case .launchDefinition:
            if bundleMatcher.matches(filename: filename) { return .certain }
            return reference.plistReferences(url) ? .certain : nil
        }
    }

    private func isForeignAppleFile(_ url: URL, app: InstalledApp) -> Bool {
        if app.protection == .system { return false }
        return url.standardizedFileURL.pathComponents.contains { $0.lowercased().hasPrefix("com.apple.") }
    }

    private func candidateURLs(in root: SearchRoot) -> [URL] {
        collect(root.url, remainingDepth: max(root.depth, 1), matching: root.depth <= 1)
    }

    /// `matching` 为 true 时，这一层的条目就是候选；为 false 时继续往下走，但不把中间目录本身当成残留。
    private func collect(_ directory: URL, remainingDepth: Int, matching: Bool) -> [URL] {
        guard remainingDepth > 0 else { return [] }
        let fileManager = FileManager()
        guard let children = try? fileManager.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: [.isSymbolicLinkKey, .isDirectoryKey],
            options: [.skipsHiddenFiles]
        ) else { return [] }
        let limited = children.prefix(20_000)
        if matching {
            return Array(limited)
        }
        var urls: [URL] = []
        for child in limited {
            let values = try? child.resourceValues(forKeys: [.isSymbolicLinkKey, .isDirectoryKey])
            if values?.isSymbolicLink == true { continue }
            guard values?.isDirectory == true else { continue }
            urls.append(contentsOf: collect(child, remainingDepth: remainingDepth - 1, matching: remainingDepth - 1 == 1))
        }
        return urls
    }
}
