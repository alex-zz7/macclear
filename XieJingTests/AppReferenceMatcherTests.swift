import Foundation
import Testing
@testable import XieJingCore

struct AppReferenceMatcherTests {
    private let matcher = AppReferenceMatcher(app: InstalledApp(
        url: URL(fileURLWithPath: "/Applications/Demo.app"),
        name: "Demo",
        bundleName: "Demo",
        bundleIdentifier: "com.example.demo",
        version: "1.0",
        identifiers: ["com.example.demo"],
        matchNames: ["Demo"],
        byteCount: nil,
        protection: nil
    ))

    @Test func `recognizes the app path and bundle id without swallowing lookalikes`() {
        #expect(matcher.references("/Applications/Demo.app/Contents/MacOS/Demo"))
        #expect(!matcher.references("/Applications/Demo.app.backup"))
        #expect(matcher.references("launch com.example.demo now"))
        #expect(matcher.references("com.example.demo.helper"))
        #expect(!matcher.references("com.example.demolition"))
    }
}
