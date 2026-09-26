import Testing
@testable import XieJingCore

struct StoreCategoryGroupTests {
    @Test func `groups app store categories into the sidebar filters`() {
        #expect(StoreCategoryGroup.group(for: "public.app-category.developer-tools") == .developer)
        #expect(StoreCategoryGroup.group(for: "public.app-category.utilities") == .utilities)
        #expect(StoreCategoryGroup.group(for: "public.app-category.social-networking") == .social)
        #expect(StoreCategoryGroup.group(for: "public.app-category.finance") == .finance)
        #expect(StoreCategoryGroup.group(for: "public.app-category.puzzle-games") == .entertainment)
        #expect(StoreCategoryGroup.group(for: nil) == .other)
        #expect(StoreCategoryGroup.group(for: "public.app-category.unknown") == .other)
    }
}
