import Foundation
import Testing
@testable import XieJingCore

struct BundleIDMatcherTests {
    private let matcher = BundleIDMatcher(identifiers: ["com.example.demo"])

    @Test func `matches the bundle id, its plist, and a helper id`() {
        #expect(matcher.matches(filename: "com.example.demo"))
        #expect(matcher.matches(filename: "com.example.demo.plist"))
        #expect(matcher.matches(filename: "com.example.demo.savedState"))
        #expect(matcher.matches(filename: "com.example.demo.helper"))
        #expect(matcher.matches(filename: "com.example.demo.helper.plist"))
    }

    @Test func `does not match a longer lookalike id`() {
        #expect(!matcher.matches(filename: "com.example.demolition"))
        #expect(!matcher.matches(filename: "com.example.demolition.plist"))
        #expect(!matcher.matches(filename: "com.example.demo2"))
        #expect(!matcher.matches(filename: "other.com.example.demo"))
    }

    @Test func `matches group containers and team containers only with a real prefix`() {
        #expect(matcher.matches(filename: "group.com.example.demo"))
        #expect(matcher.matches(filename: "AB12CD34EF.com.example.demo"))
        #expect(matcher.matches(filename: "group.AB12CD34EF.com.example.demo.helper"))
        #expect(!matcher.matches(filename: "AB12CD34EF.com.example.demolition"))
        #expect(!BundleIDMatcher.isTeamID("application"))
        #expect(BundleIDMatcher.isTeamID("AB12CD34EF"))
    }
}
