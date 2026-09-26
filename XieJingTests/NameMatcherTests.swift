import Testing
@testable import XieJingCore

struct NameMatcherTests {
    private let matcher = NameMatcher(names: ["Demo", "Go", "Cache"])

    @Test func `matches the full name and known helper suffixes only`() {
        #expect(matcher.matchesExact(filename: "Demo"))
        #expect(matcher.matchesExact(filename: "demo"))
        #expect(matcher.matchesExact(filename: "Demo Helper"))
        #expect(matcher.matchesExact(filename: "Demo Agent"))
        #expect(!matcher.matchesExact(filename: "Demonstration"))
        #expect(!matcher.matchesExact(filename: "DemoHelper"))
        #expect(!matcher.matchesExact(filename: "My Demo"))
    }

    @Test func `ignores short names and generic folder names`() {
        #expect(!NameMatcher.isUsable("Go"))
        #expect(!NameMatcher.isUsable("Cache"))
        #expect(!matcher.matchesExact(filename: "Go"))
        #expect(!matcher.matchesExact(filename: "Cache"))
        #expect(NameMatcher.isUsable("Demo"))
    }

    @Test func `matches crash reports by a bounded prefix`() {
        #expect(matcher.matchesCrashReport(filename: "Demo_2024-01-01.ips"))
        #expect(matcher.matchesCrashReport(filename: "Demo-2024.crash"))
        #expect(!matcher.matchesCrashReport(filename: "Demolition_2024.ips"))
        #expect(!matcher.matchesCrashReport(filename: "Go_2024.ips"))
    }
}
