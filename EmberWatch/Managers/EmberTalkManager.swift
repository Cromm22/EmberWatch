import Foundation
import SwiftUI

enum EmberTalkCategory {
    case greeting
    case water
    case food
    case workout
}

struct EmberPhrase {
    let text: String
    let category: EmberTalkCategory
}

@MainActor
class EmberTalkManager: ObservableObject {
    @Published var currentPhrase: EmberPhrase?
    
    private var lastPhrase: String?
    private var dismissTask: Task<Void, Never>?
    private let autoDismissDuration: TimeInterval = 2.5
    
    private let greetingPhrases = [
        "Good morning! Let's beat yesterday!",
        "Welcome back! I believe in you!",
        "Let's get after it today!",
        "Ready to crush it!"
    ]
    
    private let waterPhrases = [
        "Hydration nation! 💧",
        "Water is life! Keep it up!",
        "You're doing great! Stay hydrated!",
        "That's the spirit! More water!",
        "Perfect hydration timing",
        "Your body thanks you",
        "Cellular refresh in progress",
        "Smart move, champion",
        "That's self-care right there",
        "Elevating your wellness game",
        "Another win for your body",
        "You're taking care of business",
        "Excellence in hydration",
        "This is how winners drink",
        "Your future self approves",
        "Pure refreshment achieved"
    ]
    
    private let foodPhrases = [
        "Mmm nutrition! Fuel that fire!",
        "Healthy food is power!",
        "Smart choices! Keep going!",
        "Fueling excellence",
        "That's premium nutrition",
        "Your body deserves this",
        "Quality fuel, quality results",
        "Nourishment on point",
        "This is how champions eat",
        "Elevating your energy",
        "Smart nutrition choice",
        "Building a stronger you",
        "That's the good stuff",
        "Investing in yourself",
        "Whole food wisdom"
    ]
    
    private let workoutPhrases = [
        "I feel stronger already!",
        "I can feel the power!",
        "That was awesome!",
        "You're on fire! 🔥",
        "Strength forged right now",
        "That's pure dedication",
        "Your power is showing",
        "Excellence in motion",
        "This is transformation",
        "Building unstoppable momentum",
        "That's championship effort",
        "Your best self emerging",
        "Raw strength unleashed",
        "Elite performance unlocked",
        "You're rewriting your limits",
        "This is what winning looks like"
    ]
    
    func showGreeting() {
        showPhrase(from: greetingPhrases, category: .greeting)
    }
    
    func showWaterPhrase() {
        showPhrase(from: waterPhrases, category: .water)
    }
    
    func showFoodPhrase() {
        showPhrase(from: foodPhrases, category: .food)
    }
    
    func showWorkoutPhrase() {
        showPhrase(from: workoutPhrases, category: .workout)
    }
    
    func dismiss() {
        dismissTask?.cancel()
        withAnimation(.easeOut(duration: 0.3)) {
            currentPhrase = nil
        }
    }
    
    private func showPhrase(from pool: [String], category: EmberTalkCategory) {
        guard !pool.isEmpty else { return }
        
        dismissTask?.cancel()
        
        var candidates = pool
        if let last = lastPhrase, pool.count > 1 {
            candidates = pool.filter { $0 != last }
        }
        
        guard let text = candidates.randomElement() else { return }
        
        lastPhrase = text
        currentPhrase = EmberPhrase(text: text, category: category)
        
        dismissTask = Task {
            try? await Task.sleep(nanoseconds: UInt64(autoDismissDuration * 1_000_000_000))
            guard !Task.isCancelled else { return }
            withAnimation(.easeOut(duration: 0.3)) {
                currentPhrase = nil
            }
        }
    }
}
