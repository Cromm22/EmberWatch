import Foundation
import SwiftUI

/// Manages Ember's contextual speech/caption system with random phrases for user actions.
@MainActor
final class EmberTalkManager: ObservableObject {
    /// The current phrase being displayed (nil = no speech).
    @Published private(set) var currentPhrase: String? = nil
    
    /// Last phrase shown to avoid immediate repeats.
    private var lastPhrase: String? = nil
    
    /// Auto-dismiss task.
    private var dismissTask: Task<Void, Never>? = nil
    
    // MARK: - Phrase pools
    
    private let greetingPhrases = [
        "Good morning",
        "Welcome back",
        "Let's get after it",
        "Let's beat yesterday",
        "Ready to go?",
        "Another day to shine"
    ]
    
    private let waterPhrases = [
        "Hydrate!",
        "Stay flowing",
        "Clear mind, clear water",
        "Fuel up",
        "Water is power",
        "Keep it flowing"
    ]
    
    private let foodPhrases = [
        "Mmm, nutrition!",
        "Healthy food is power",
        "Superfood is good",
        "Fuel the fire",
        "Nutrition win!",
        "Good choice!"
    ]
    
    private let workoutPhrases = [
        "I feel stronger",
        "I can feel the power!",
        "That was awesome!",
        "You crushed it!",
        "Burning bright!",
        "Let's go!"
    ]
    
    // MARK: - Public API
    
    /// Show a random greeting (app open / daily first appearance).
    func showGreeting() {
        showRandomPhrase(from: greetingPhrases)
    }
    
    /// Show a random water encouragement.
    func showWaterPhrase() {
        showRandomPhrase(from: waterPhrases)
    }
    
    /// Show a random food encouragement.
    func showFoodPhrase() {
        showRandomPhrase(from: foodPhrases)
    }
    
    /// Show a random workout celebration.
    func showWorkoutPhrase() {
        showRandomPhrase(from: workoutPhrases)
    }
    
    /// Manually clear the current phrase.
    func clearPhrase() {
        dismissTask?.cancel()
        dismissTask = nil
        withAnimation(.easeOut(duration: 0.25)) {
            currentPhrase = nil
        }
    }
    
    // MARK: - Internals
    
    private func showRandomPhrase(from pool: [String]) {
        guard !pool.isEmpty else { return }
        
        // Pick a phrase different from the last one if possible
        var candidates = pool
        if let last = lastPhrase, pool.count > 1 {
            candidates = pool.filter { $0 != last }
        }
        
        guard let phrase = candidates.randomElement() else { return }
        
        lastPhrase = phrase
        
        // Cancel any existing dismiss task
        dismissTask?.cancel()
        
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            currentPhrase = phrase
        }
        
        // Auto-dismiss after 2.5 seconds
        dismissTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 2_500_000_000) // 2.5 seconds
            guard !Task.isCancelled else { return }
            withAnimation(.easeOut(duration: 0.25)) {
                if currentPhrase == phrase {
                    currentPhrase = nil
                }
            }
        }
    }
}
