import Foundation

enum RecordingFileNamer {
    static func fileName(for date: Date, timeZone: TimeZone = .current) -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = timeZone
        formatter.dateFormat = "yyyy-MM-dd 'at' HH.mm.ss"
        return "MacTape \(formatter.string(from: date)).mp4"
    }

    static func availableURL(
        in directory: URL,
        date: Date = Date(),
        fileManager: FileManager = .default
    ) -> URL {
        let initialURL = directory.appendingPathComponent(fileName(for: date))

        guard fileManager.fileExists(atPath: initialURL.path) else {
            return initialURL
        }

        let baseName = initialURL.deletingPathExtension().lastPathComponent

        for index in 2...999 {
            let candidate = directory
                .appendingPathComponent("\(baseName) \(index)")
                .appendingPathExtension("mp4")

            if !fileManager.fileExists(atPath: candidate.path) {
                return candidate
            }
        }

        return directory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("mp4")
    }
}
