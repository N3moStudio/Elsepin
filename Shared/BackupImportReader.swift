import Foundation

/// Immutable transfer of a decoded, value-only library snapshot from a worker.
/// LibraryBackup and all nested routes/preferences contain no reference state.
struct BackupImportPreview: Identifiable, @unchecked Sendable {
    let id = UUID()
    let backup: LibraryBackup
}

enum BackupImportReader {
    static func text(_ text: String) throws -> BackupImportPreview {
        // Bound bytes before allocating another full copy of pasted text.
        guard text.utf8.prefix(LibraryBackup.maximumBytes + 1).count <= LibraryBackup.maximumBytes else {
            throw BackupError.tooLarge
        }
        return try decode(Data(text.utf8))
    }

    static func file(_ url: URL) throws -> BackupImportPreview {
        guard url.isFileURL else { throw BackupImportError.notFile }
        #if canImport(Darwin)
        var coordinationError: NSError?
        var result: Result<BackupImportPreview, Error>?
        NSFileCoordinator().coordinate(readingItemAt: url, options: [], error: &coordinationError) { readableURL in
            result = Result { try readLocalFile(readableURL) }
        }
        if let coordinationError { throw coordinationError }
        guard let result else { throw CocoaError(.fileReadUnknown) }
        return try result.get()
        #else
        return try readLocalFile(url)
        #endif
    }

    private static func readLocalFile(_ url: URL) throws -> BackupImportPreview {
        let info = try url.resourceValues(forKeys: [.isRegularFileKey, .fileSizeKey])
        guard info.isRegularFile == true else { throw BackupImportError.notFile }
        if let size = info.fileSize, size > LibraryBackup.maximumBytes { throw BackupError.tooLarge }
        let handle = try FileHandle(forReadingFrom: url)
        defer { try? handle.close() }
        var data = Data()
        // Enforce the cap during reading too: providers can omit or change size metadata.
        while true {
            try Task.checkCancellation()
            let remaining = LibraryBackup.maximumBytes + 1 - data.count
            let chunk = try handle.read(upToCount: min(64 * 1024, remaining)) ?? Data()
            if chunk.isEmpty { break }
            data.append(chunk)
            guard data.count <= LibraryBackup.maximumBytes else { throw BackupError.tooLarge }
        }
        return try decode(data)
    }

    private static func decode(_ data: Data) throws -> BackupImportPreview {
        try Task.checkCancellation()
        do {
            let backup = try LibraryBackup.decode(data)
            try Task.checkCancellation()
            return BackupImportPreview(backup: backup)
        } catch is DecodingError {
            throw BackupImportError.invalidContent
        }
    }
}

enum BackupImportError: LocalizedError {
    case notFile, invalidContent
    var errorDescription: String? {
        switch self {
        case .notFile: return "Choose a backup file, not a folder. Nothing was imported."
        case .invalidContent:
            return "This isn't a complete Elsepin backup. If pasting, copy all of the JSON text, not a file link or just part of the file. Nothing was imported."
        }
    }
}

/// Selection is replaced only by a successful, current operation. A canceled or
/// late provider response must never erase or replace another preview.
struct BackupImportState {
    private(set) var preview: BackupImportPreview?
    private(set) var operation: UUID?
    private(set) var message: String?
    var isLoading: Bool { operation != nil }

    mutating func begin() -> UUID? {
        guard operation == nil else { return nil }
        let id = UUID()
        operation = id
        message = nil
        return id
    }

    mutating func finish(_ id: UUID, result: Result<BackupImportPreview, Error>) {
        guard operation == id else { return }
        operation = nil
        switch result {
        case .success(let value): preview = value; message = nil
        case .failure(let error): message = error.localizedDescription
        }
    }

    mutating func cancel() { operation = nil }
    mutating func clearPreview() { preview = nil; message = nil }
    mutating func notice(_ text: String?) { message = text }
}
