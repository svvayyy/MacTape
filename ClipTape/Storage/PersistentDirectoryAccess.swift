import Foundation

final class PersistentDirectoryAccess {
    let url: URL
    let bookmarkData: Data

    private let isAccessing: Bool

    init(selectedURL: URL) throws {
        url = selectedURL
        bookmarkData = try selectedURL.bookmarkData(
            options: .withSecurityScope,
            includingResourceValuesForKeys: nil,
            relativeTo: nil
        )
        isAccessing = selectedURL.startAccessingSecurityScopedResource()
    }

    init(bookmarkData: Data) throws {
        var isStale = false
        let resolvedURL = try URL(
            resolvingBookmarkData: bookmarkData,
            options: .withSecurityScope,
            relativeTo: nil,
            bookmarkDataIsStale: &isStale
        )

        url = resolvedURL
        self.bookmarkData = if isStale {
            try resolvedURL.bookmarkData(
                options: .withSecurityScope,
                includingResourceValuesForKeys: nil,
                relativeTo: nil
            )
        } else {
            bookmarkData
        }
        isAccessing = resolvedURL.startAccessingSecurityScopedResource()
    }

    deinit {
        if isAccessing {
            url.stopAccessingSecurityScopedResource()
        }
    }
}
