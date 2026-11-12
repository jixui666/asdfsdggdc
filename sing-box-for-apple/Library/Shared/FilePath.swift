import Foundation

public enum FilePath {
    public static let packageName = AppConfiguration.packageName
    public static let groupName = AppConfiguration.appGroupID

    // The App Group container only exists when the app is signed with a profile
    // that carries com.apple.security.application-groups. Sideloaded builds
    // (free Apple ID, AltStore/Sideloadly re-sign) do not, and
    // containerURL(forSecurityApplicationGroupIdentifier:) then returns nil.
    // Upstream force-unwraps it, which traps in this initializer and kills the
    // app ~80 ms after launch. Fall back to the app's own sandbox instead so the
    // UI can start; the tunnel still needs the NetworkExtension entitlement.
    private static let defaultSharedDirectory: URL! = {
        if let groupContainer = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: groupName) {
            return groupContainer
        }
        NSLog("App Group \(groupName) is unavailable, falling back to the app sandbox")
        let sandbox = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        try? FileManager.default.createDirectory(at: sandbox, withIntermediateDirectories: true)
        return URL(fileURLWithPath: sandbox.path)
    }()

    #if os(iOS)
        public static let sharedDirectory = defaultSharedDirectory!
    #elseif os(tvOS)
        public static let sharedDirectory = defaultSharedDirectory
            .appendingPathComponent("Library", isDirectory: true)
            .appendingPathComponent("Caches", isDirectory: true)
    #elseif os(macOS)
        public static var sharedDirectory: URL! = defaultSharedDirectory
    #endif

    #if os(iOS)
        public static let cacheDirectory = sharedDirectory
            .appendingPathComponent("Library", isDirectory: true)
            .appendingPathComponent("Caches", isDirectory: true)
    #elseif os(tvOS)
        public static let cacheDirectory = sharedDirectory
    #elseif os(macOS)
        public static var cacheDirectory: URL {
            sharedDirectory
                .appendingPathComponent("Library", isDirectory: true)
                .appendingPathComponent("Caches", isDirectory: true)
        }
    #endif

    #if os(macOS)
        public static var workingDirectory: URL {
            cacheDirectory.appendingPathComponent("Working", isDirectory: true)
        }
    #else
        public static let workingDirectory = cacheDirectory.appendingPathComponent("Working", isDirectory: true)

    #endif

    public static var iCloudDirectory = FileManager.default.url(forUbiquityContainerIdentifier: nil)?.appendingPathComponent("Documents", isDirectory: true) ?? URL(string: "stub")!
}

public extension URL {
    var fileName: String {
        var path = relativePath
        if let index = path.lastIndex(of: "/") {
            path = String(path[path.index(index, offsetBy: 1)...])
        }
        return path
    }
}
