import Foundation
import SwiftUI

struct FeedbackEntry: Identifiable, Codable, Equatable {
    let id: UUID
    let text: String
    let createdAt: Date
    
    init(id: UUID = UUID(), text: String, createdAt: Date = Date()) {
        self.id = id
        self.text = text
        self.createdAt = createdAt
    }
}

/// Stores feedback locally and optionally POSTs to the Ember routine webhook.
/// To enable Chief-of-Staff relay: paste the “Ember app feedback” routine webhook URL into Info.plist key `EMBER_FEEDBACK_WEBHOOK_URL`.
@MainActor
final class FeedbackManager: ObservableObject {
    @Published private(set) var entries: [FeedbackEntry] = []
    @Published var lastSendSucceeded = false
    
    private let storageKey = "emberFeedbackEntries"
    
    init() {
        load()
    }
    
    func submit(_ text: String) async -> Bool {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }
        
        let entry = FeedbackEntry(text: trimmed)
        entries.insert(entry, at: 0)
        persist()
        
        await postToWebhookIfConfigured(entry)
        lastSendSucceeded = true
        return true
    }
    
    private func load() {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else {
            entries = []
            return
        }
        do {
            let decoded = try JSONDecoder().decode([FeedbackEntry].self, from: data)
            entries = decoded.sorted { $0.createdAt > $1.createdAt }
        } catch {
            print("FeedbackManager: failed to decode entries: \(error)")
            entries = []
        }
    }
    
    private func persist() {
        do {
            let data = try JSONEncoder().encode(entries)
            UserDefaults.standard.set(data, forKey: storageKey)
        } catch {
            print("FeedbackManager: failed to encode entries: \(error)")
        }
    }
    
    private func webhookURL() -> URL? {
        guard let raw = Bundle.main.object(forInfoDictionaryKey: "EMBER_FEEDBACK_WEBHOOK_URL") as? String else {
            return nil
        }
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, let url = URL(string: trimmed) else { return nil }
        return url
    }
    
    private func postToWebhookIfConfigured(_ entry: FeedbackEntry) async {
        guard let url = webhookURL() else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let payload: [String: String] = [
            "text": entry.text,
            "createdAt": formatter.string(from: entry.createdAt),
            "source": "EmberWatch"
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: payload)
            let (_, response) = try await URLSession.shared.data(for: request)
            if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
                print("FeedbackManager: webhook HTTP \(http.statusCode)")
            }
        } catch {
            // Local save already succeeded; network is best-effort.
            print("FeedbackManager: webhook post failed: \(error)")
        }
    }
}
