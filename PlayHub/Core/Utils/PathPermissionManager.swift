import Foundation

#if os(macOS)
import AppKit
#endif

/// Handles requesting and resolving security-scoped bookmarks for user-selected directories.
final class PathPermissionManager {
    
    static let shared = PathPermissionManager()
    
    private let defaults = UserDefaults.standard
    private let bookmarkKeyPrefix = "securityBookmark."
    private let pathKeyPrefix = "securityBookmarkPath."
    
    enum BookmarkKey: String {
        case coreSimulatorRoot
        case androidAVD
    }
    
    private init() {}
    
    #if os(macOS)
    /// Presents an open panel to request access to a directory and stores a security-scoped bookmark.
    /// - Parameters:
    ///   - key: Bookmark identifier.
    ///   - suggestedPath: Optional initial path shown in the open panel.
    ///   - message: Message displayed to the user.
    /// - Returns: The selected URL if access was granted.
    @discardableResult
    func requestAccess(for key: BookmarkKey, suggestedPath: String?, message: String) -> URL? {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.prompt = NSLocalizedString("Select", comment: "Open panel prompt")
        panel.message = message
        
        if let suggestedPath,
           !suggestedPath.isEmpty {
            let expanded = (suggestedPath as NSString).expandingTildeInPath
            let url = URL(fileURLWithPath: expanded, isDirectory: true)
            if FileManager.default.fileExists(atPath: expanded) {
                panel.directoryURL = url
            }
        }
        
        guard panel.runModal() == .OK, let url = panel.url else {
            return nil
        }
        
        do {
            let bookmark = try url.bookmarkData(
                options: [.withSecurityScope],
                includingResourceValuesForKeys: nil,
                relativeTo: nil
            )
            defaults.set(bookmark, forKey: bookmarkKeyPrefix + key.rawValue)
            defaults.set(url.path, forKey: pathKeyPrefix + key.rawValue)
            return url
        } catch {
            NSLog("🔐 Failed to save bookmark for \(key.rawValue): \(error)")
            return nil
        }
    }
    #else
    func requestAccess(for key: BookmarkKey, suggestedPath: String?, message: String) -> URL? { nil }
    #endif
    
    /// Resolves a stored security-scoped bookmark.
    func resolvedURL(for key: BookmarkKey) -> URL? {
        guard let data = defaults.data(forKey: bookmarkKeyPrefix + key.rawValue) else { return nil }
        var isStale = false
        do {
            let url = try URL(resolvingBookmarkData: data,
                              options: [.withSecurityScope, .withoutUI],
                              relativeTo: nil,
                              bookmarkDataIsStale: &isStale)
            if isStale {
                // Bookmark expired; clear stored values so the app can request again.
                clearAccess(for: key)
                return nil
            }
            return url
        } catch {
            NSLog("🔐 Failed to resolve bookmark for \(key.rawValue): \(error)")
            clearAccess(for: key)
            return nil
        }
    }
    
    /// Returns the stored display path (if any) for the bookmark.
    func currentPath(for key: BookmarkKey) -> String? {
        defaults.string(forKey: pathKeyPrefix + key.rawValue)
    }
    
    /// Executes a block with security-scoped access.
    func useURL(for key: BookmarkKey, block: (URL) -> Void) {
        #if os(macOS)
        guard let url = resolvedURL(for: key),
              url.startAccessingSecurityScopedResource() else { return }
        defer { url.stopAccessingSecurityScopedResource() }
        block(url)
        #endif
    }
    
    /// Removes a stored bookmark (used if the path becomes invalid).
    func clearAccess(for key: BookmarkKey) {
        defaults.removeObject(forKey: bookmarkKeyPrefix + key.rawValue)
        defaults.removeObject(forKey: pathKeyPrefix + key.rawValue)
    }
}
