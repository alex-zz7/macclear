import os
import XieJingCore

enum AppLog {
    static let library = Logger(subsystem: ProductIdentity.bundleIdentifier, category: "library")
}
