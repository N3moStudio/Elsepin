import Foundation

/// Library/preferences routing only. Pairing, Keychain, session-clear evidence,
/// diagnostics and device security never use the demo workspace.
/// Capture a Context before queued writes: a later switch must not redirect them.
final class AppDataWorkspace: @unchecked Sendable {
    // Immutable destination metadata; UserDefaults get/set operations are thread-safe.
    // File mutations remain serialized by each owning store. Never swap this capture.
    struct Context: @unchecked Sendable {
        let generation = UUID()
        let id: UUID?
        let defaults: UserDefaults
        let directory: URL
        func file(_ name: String) -> URL { directory.appendingPathComponent(name) }
    }

    static let shared = AppDataWorkspace(personal: .standard, directory:
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Locus", isDirectory: true))
    static var defaults: UserDefaults { shared.context.defaults }
    static func file(_ name: String) -> URL { shared.context.file(name) }

    private let lock = NSLock()
    private let personal: Context
    private let key: String
    private let suitePrefix: String
    private var active: Context
    var context: Context { lock.lock(); defer { lock.unlock() }; return active }
    var isDemo: Bool { context.id != nil }

    init(personal defaults: UserDefaults, directory: URL,
         key: String = "elsepin.devMode.workspace.v1", suitePrefix: String = "com.elsepin.demo") {
        self.key = key
        self.suitePrefix = suitePrefix
        let real = Context(id: nil, defaults: defaults, directory: directory)
        personal = real
        if let raw = defaults.string(forKey: key), let id = UUID(uuidString: raw),
           let demoDefaults = UserDefaults(suiteName: suitePrefix + "." + id.uuidString) {
            active = Context(id: id, defaults: demoDefaults,
                directory: directory.appendingPathComponent("DevMode/" + id.uuidString, isDirectory: true))
        } else { active = real }
    }

    /// Seed a fresh namespace completely before publishing it. A failed seed
    /// leaves the active/personal data untouched, including on the next launch.
    func activateDemo(seed: (Context) throws -> Void) throws {
        guard !isDemo else { return }
        let id = UUID()
        let suite = suitePrefix + "." + id.uuidString
        guard let defaults = UserDefaults(suiteName: suite) else { throw CocoaError(.fileWriteUnknown) }
        let candidate = Context(id: id, defaults: defaults,
            directory: personal.directory.appendingPathComponent("DevMode/" + id.uuidString, isDirectory: true))
        do {
            try FileManager.default.createDirectory(at: candidate.directory, withIntermediateDirectories: true)
            try seed(candidate)
        } catch {
            defaults.removePersistentDomain(forName: suite)
            try? FileManager.default.removeItem(at: candidate.directory)
            throw error
        }
        // Do not copy personal records into the sandbox, or restore by overwriting
        // real files. Only this one routing marker changes in the personal domain.
        personal.defaults.set(id.uuidString, forKey: key)
        lock.lock(); active = candidate; lock.unlock()
    }

    /// Caller must drain queued writes before this. Only the generated demo
    /// directory/domain are removed; original files are never moved or replaced.
    func deactivateDemo() {
        let previous = context
        guard let id = previous.id else { return }
        personal.defaults.removeObject(forKey: key)
        lock.lock()
        active = Context(id: nil, defaults: personal.defaults, directory: personal.directory)
        lock.unlock()
        previous.defaults.removePersistentDomain(forName: suitePrefix + "." + id.uuidString)
        try? FileManager.default.removeItem(at: previous.directory)
    }
}
