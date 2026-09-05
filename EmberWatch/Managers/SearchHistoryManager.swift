import Foundation

/// Manages search history for the last 48 hours
@MainActor
class SearchHistoryManager: ObservableObject {
    @Published private(set) var recentSearches: [SearchHistoryItem] = []
    
    private static let storageKey = "ember_search_history"
    private static let maxAge: TimeInterval = 48 * 60 * 60 // 48 hours
    private static let maxItems = 20
    
    init() {
        loadHistory()
    }
    
    /// Add a search query to history
    func addSearch(_ query: String) {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, trimmed.count >= 2 else { return }
        
        // Remove duplicate if exists
        recentSearches.removeAll { $0.query.lowercased() == trimmed.lowercased() }
        
        // Add to front
        let item = SearchHistoryItem(query: trimmed, timestamp: Date())
        recentSearches.insert(item, at: 0)
        
        // Keep only recent items
        recentSearches = Array(recentSearches.prefix(Self.maxItems))
        
        saveHistory()
    }
    
    /// Get recent searches that are still within 48 hours
    func getRecentSearches() -> [SearchHistoryItem] {
        cleanupOldSearches()
        return recentSearches
    }
    
    /// Clear all search history
    func clearHistory() {
        recentSearches = []
        saveHistory()
    }
    
    /// Remove searches older than 48 hours
    private func cleanupOldSearches() {
        let cutoff = Date().addingTimeInterval(-Self.maxAge)
        let before = recentSearches.count
        recentSearches.removeAll { $0.timestamp < cutoff }
        if recentSearches.count != before {
            saveHistory()
        }
    }
    
    private func loadHistory() {
        guard let data = UserDefaults.standard.data(forKey: Self.storageKey),
              let items = try? JSONDecoder().decode([SearchHistoryItem].self, from: data) else {
            recentSearches = []
            return
        }
        
        // Filter out old items on load
        let cutoff = Date().addingTimeInterval(-Self.maxAge)
        recentSearches = items.filter { $0.timestamp >= cutoff }
    }
    
    private func saveHistory() {
        guard let data = try? JSONEncoder().encode(recentSearches) else { return }
        UserDefaults.standard.set(data, forKey: Self.storageKey)
    }
}

struct SearchHistoryItem: Identifiable, Codable {
    let id: UUID
    let query: String
    let timestamp: Date
    
    init(id: UUID = UUID(), query: String, timestamp: Date) {
        self.id = id
        self.query = query
        self.timestamp = timestamp
    }
    
    var relativeTime: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: timestamp, relativeTo: Date())
    }
}
