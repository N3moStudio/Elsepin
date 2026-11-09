import Combine
import Foundation

@MainActor
final class TripRecoveryStore: ObservableObject {
    var resumePolicy: TripResumePolicy { TripResumePolicy(defaults: AppDataWorkspace.defaults) }
    @Published private(set) var checkpoint: TripCheckpoint?
    @Published private(set) var error: String?
    @Published var enabled = AppDataWorkspace.defaults.object(forKey: "locus.tripRecovery") as? Bool ?? true {
        didSet {
            guard !reloadingWorkspace else { return }
            AppDataWorkspace.defaults.set(enabled, forKey: "locus.tripRecovery")
            if !enabled { discard() }
        }
    }
    private let queue = DispatchQueue(label: "locus.trip-checkpoint", qos: .utility)
    private var revision = UUID()
    private var lastWrite = Date.distantPast
    private var file: URL { AppDataWorkspace.file("TripCheckpoint.json") }
    private let pending = DispatchGroup()
    private var reloadingWorkspace = false

    init() { reloadWorkspace() }
    func finishPendingWrites() async {
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            pending.notify(queue: queue) { continuation.resume() }
        }
    }
    func reloadWorkspace() {
        revision = UUID(); checkpoint = nil; error = nil; lastWrite = .distantPast
        reloadingWorkspace = true
        enabled = AppDataWorkspace.defaults.object(forKey: "locus.tripRecovery") as? Bool ?? true
        reloadingWorkspace = false
        guard enabled, AppDataWorkspace.defaults.bool(forKey: "locus.checkpointAvailable"), FileManager.default.fileExists(atPath: file.path) else { return }
        do {
            let size = try file.resourceValues(forKeys: [.fileSizeKey]).fileSize ?? 0
            guard size <= LibraryBackup.maximumBytes else { throw BackupError.tooLarge }
            let value = try JSONDecoder().decode(TripCheckpoint.self, from: Data(contentsOf: file))
            guard value.isValid else { throw BackupError.invalid }
            checkpoint = value
        } catch { self.error = "The saved trip checkpoint couldn't be read. Your saved library is unaffected." }
    }

    func shouldSave(force: Bool, now: Date = Date()) -> Bool {
        enabled && (force || now.timeIntervalSince(lastWrite) >= 10)
    }
    func save(_ value: TripCheckpoint, resumeAutomatically: Bool) {
        guard enabled, value.isValid else { return }
        resumePolicy.setAllowed(resumeAutomatically)
        let token = UUID()
        revision = token
        lastWrite = Date()
        let file = file
        let defaults = AppDataWorkspace.defaults
        let pending = pending; pending.enter()
        queue.async { [weak self] in
            do {
                try FileManager.default.createDirectory(at: file.deletingLastPathComponent(), withIntermediateDirectories: true)
                try JSONEncoder().encode(value).write(to: file, options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
                var protected = file
                var values = URLResourceValues(); values.isExcludedFromBackup = true
                try protected.setResourceValues(values)
                Task { @MainActor [weak self] in
                    defer { pending.leave() }
                    guard let self, self.revision == token else { return }
                    defaults.set(true, forKey: "locus.checkpointAvailable")
                    self.checkpoint = value
                    self.error = nil
                }
            } catch {
                Task { @MainActor [weak self] in
                    defer { pending.leave() }
                    guard let self, self.revision == token else { return }
                    self.error = "Couldn't save the latest recovery point. Movement can continue, but recovery may use an older point."
                }
            }
        }
    }
    func discard() {
        resumePolicy.setAllowed(false)
        AppDataWorkspace.defaults.set(false, forKey: "locus.checkpointAvailable")
        revision = UUID()
        checkpoint = nil
        let file = file
        let token = revision
        let pending = pending; pending.enter()
        queue.async { [weak self] in
            do {
                if FileManager.default.fileExists(atPath: file.path) { try FileManager.default.removeItem(at: file) }
                Task { @MainActor [weak self] in
                    defer { pending.leave() }
                    guard self?.revision == token else { return }; self?.error = nil
                }
            } catch {
                Task { @MainActor [weak self] in
                    defer { pending.leave() }
                    guard self?.revision == token else { return }
                    self?.error = "Couldn't remove the saved recovery point. Try again in Trip recovery."
                }
            }
        }
    }

    func resetAll() async throws {
        resumePolicy.setAllowed(false)
        // A barrier on the same queue waits out earlier saves before removing their output.
        revision = UUID()
        let file = file
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            queue.async {
                do {
                    if FileManager.default.fileExists(atPath: file.path) { try FileManager.default.removeItem(at: file) }
                    continuation.resume()
                } catch { continuation.resume(throwing: error) }
            }
        }
        checkpoint = nil; error = nil; lastWrite = .distantPast
        AppDataWorkspace.defaults.removeObject(forKey: "locus.checkpointAvailable")
    }
}
