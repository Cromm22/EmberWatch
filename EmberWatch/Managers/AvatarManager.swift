import Foundation
import SwiftUI

struct AvatarStyle: Identifiable, Codable {
    let id: String
    let name: String
    let outerColors: [String]
    let innerColors: [String]
    let coreColors: [String]
    let auraColor: String
    let sparkColors: [String]
    let hasCirclet: Bool
    let hasSideSparks: Bool
    let eyeStyle: EyeStyle
    
    enum EyeStyle: String, Codable {
        case normal
        case wide
        case sleepy
        case excited
    }
    
    static let presets: [AvatarStyle] = [
        AvatarStyle(
            id: "classic",
            name: "Classic Ember",
            outerColors: ["#ffe08a", "#ff9a3c", "#ff6a1a", "#d9480f"],
            innerColors: ["#fff6c8", "#ffd27a", "#ff9f43"],
            coreColors: ["#fffef5", "#ffe08a", "#ffb347"],
            auraColor: "#ff7a3c",
            sparkColors: ["#ffe08a", "#ffd27a"],
            hasCirclet: false,
            hasSideSparks: false,
            eyeStyle: .normal
        ),
        AvatarStyle(
            id: "gold",
            name: "Golden Flame",
            outerColors: ["#fff4c4", "#ffdb58", "#ffb347", "#ff9500"],
            innerColors: ["#fffef5", "#fff9d0", "#ffd27a"],
            coreColors: ["#ffffff", "#fffacd", "#ffdb58"],
            auraColor: "#ffb347",
            sparkColors: ["#fffef5", "#fff4c4"],
            hasCirclet: true,
            hasSideSparks: false,
            eyeStyle: .wide
        ),
        AvatarStyle(
            id: "teal",
            name: "Teal Ember",
            outerColors: ["#a8edea", "#5fd3d0", "#3aa8a6", "#2d8684"],
            innerColors: ["#e0f9f7", "#a8edea", "#6dd3cf"],
            coreColors: ["#ffffff", "#d4f5f4", "#a8edea"],
            auraColor: "#5fd3d0",
            sparkColors: ["#e0f9f7", "#a8edea"],
            hasCirclet: false,
            hasSideSparks: true,
            eyeStyle: .normal
        ),
        AvatarStyle(
            id: "violet",
            name: "Violet Blaze",
            outerColors: ["#e9d5ff", "#c084fc", "#a855f7", "#7e22ce"],
            innerColors: ["#faf5ff", "#e9d5ff", "#c084fc"],
            coreColors: ["#ffffff", "#f3e8ff", "#e9d5ff"],
            auraColor: "#c084fc",
            sparkColors: ["#faf5ff", "#e9d5ff"],
            hasCirclet: true,
            hasSideSparks: false,
            eyeStyle: .wide
        ),
        AvatarStyle(
            id: "ice",
            name: "Ice Blue",
            outerColors: ["#e0f2fe", "#7dd3fc", "#0ea5e9", "#0369a1"],
            innerColors: ["#f0f9ff", "#e0f2fe", "#bae6fd"],
            coreColors: ["#ffffff", "#f0f9ff", "#e0f2fe"],
            auraColor: "#7dd3fc",
            sparkColors: ["#f0f9ff", "#e0f2fe"],
            hasCirclet: false,
            hasSideSparks: true,
            eyeStyle: .sleepy
        ),
        AvatarStyle(
            id: "magenta",
            name: "Magenta Fire",
            outerColors: ["#fce7f3", "#f472b6", "#ec4899", "#be185d"],
            innerColors: ["#fdf2f8", "#fce7f3", "#fbcfe8"],
            coreColors: ["#ffffff", "#fdf4f8", "#fce7f3"],
            auraColor: "#f472b6",
            sparkColors: ["#fdf2f8", "#fce7f3"],
            hasCirclet: true,
            hasSideSparks: true,
            eyeStyle: .excited
        ),
        AvatarStyle(
            id: "lime",
            name: "Lime Spark",
            outerColors: ["#ecfccb", "#bef264", "#84cc16", "#65a30d"],
            innerColors: ["#f7fee7", "#ecfccb", "#d9f99d"],
            coreColors: ["#ffffff", "#fefce8", "#ecfccb"],
            auraColor: "#bef264",
            sparkColors: ["#fefce8", "#ecfccb"],
            hasCirclet: false,
            hasSideSparks: true,
            eyeStyle: .normal
        ),
        AvatarStyle(
            id: "charcoal",
            name: "Charcoal Ember",
            outerColors: ["#9ca3af", "#6b7280", "#ff7a3c", "#d9480f"],
            innerColors: ["#e5e7eb", "#d1d5db", "#ff9a3c"],
            coreColors: ["#f9fafb", "#e5e7eb", "#ffb347"],
            auraColor: "#6b7280",
            sparkColors: ["#f3f4f6", "#e5e7eb"],
            hasCirclet: false,
            hasSideSparks: false,
            eyeStyle: .sleepy
        ),
        AvatarStyle(
            id: "sunrise",
            name: "Sunrise Glow",
            outerColors: ["#fed7aa", "#fb923c", "#f97316", "#ea580c"],
            innerColors: ["#ffedd5", "#fed7aa", "#fdba74"],
            coreColors: ["#fffbf5", "#ffedd5", "#fed7aa"],
            auraColor: "#fb923c",
            sparkColors: ["#fff7ed", "#ffedd5"],
            hasCirclet: true,
            hasSideSparks: false,
            eyeStyle: .wide
        ),
        AvatarStyle(
            id: "forest",
            name: "Forest Fire",
            outerColors: ["#d9f99d", "#84cc16", "#ff7a3c", "#ea580c"],
            innerColors: ["#fef9c3", "#d9f99d", "#fbbf24"],
            coreColors: ["#fffef5", "#fef9c3", "#fde68a"],
            auraColor: "#84cc16",
            sparkColors: ["#fefce8", "#fef9c3"],
            hasCirclet: false,
            hasSideSparks: true,
            eyeStyle: .normal
        ),
        AvatarStyle(
            id: "rose",
            name: "Rose Flame",
            outerColors: ["#fecdd3", "#fb7185", "#e11d48", "#9f1239"],
            innerColors: ["#fff1f2", "#fecdd3", "#fda4af"],
            coreColors: ["#ffffff", "#fff1f2", "#ffe4e6"],
            auraColor: "#fb7185",
            sparkColors: ["#fff1f2", "#fecdd3"],
            hasCirclet: true,
            hasSideSparks: false,
            eyeStyle: .excited
        ),
        AvatarStyle(
            id: "amber",
            name: "Amber Blaze",
            outerColors: ["#fde68a", "#fbbf24", "#f59e0b", "#d97706"],
            innerColors: ["#fef3c7", "#fde68a", "#fcd34d"],
            coreColors: ["#fffef5", "#fef3c7", "#fef08a"],
            auraColor: "#fbbf24",
            sparkColors: ["#fefce8", "#fef3c7"],
            hasCirclet: false,
            hasSideSparks: true,
            eyeStyle: .wide
        ),
        AvatarStyle(
            id: "ocean",
            name: "Ocean Wave",
            outerColors: ["#bfdbfe", "#60a5fa", "#2563eb", "#1e40af"],
            innerColors: ["#dbeafe", "#bfdbfe", "#93c5fd"],
            coreColors: ["#ffffff", "#eff6ff", "#dbeafe"],
            auraColor: "#60a5fa",
            sparkColors: ["#eff6ff", "#dbeafe"],
            hasCirclet: false,
            hasSideSparks: true,
            eyeStyle: .normal
        ),
        AvatarStyle(
            id: "mint",
            name: "Mint Frost",
            outerColors: ["#ccfbf1", "#5eead4", "#14b8a6", "#0f766e"],
            innerColors: ["#f0fdfa", "#ccfbf1", "#99f6e4"],
            coreColors: ["#ffffff", "#f0fdfa", "#ccfbf1"],
            auraColor: "#5eead4",
            sparkColors: ["#f0fdfa", "#ccfbf1"],
            hasCirclet: true,
            hasSideSparks: false,
            eyeStyle: .sleepy
        ),
        AvatarStyle(
            id: "ruby",
            name: "Ruby Heat",
            outerColors: ["#fecaca", "#f87171", "#dc2626", "#991b1b"],
            innerColors: ["#fef2f2", "#fecaca", "#fca5a5"],
            coreColors: ["#ffffff", "#fef2f2", "#fee2e2"],
            auraColor: "#f87171",
            sparkColors: ["#fef2f2", "#fecaca"],
            hasCirclet: true,
            hasSideSparks: true,
            eyeStyle: .excited
        ),
        AvatarStyle(
            id: "indigo",
            name: "Indigo Spirit",
            outerColors: ["#c7d2fe", "#818cf8", "#6366f1", "#4338ca"],
            innerColors: ["#e0e7ff", "#c7d2fe", "#a5b4fc"],
            coreColors: ["#ffffff", "#eef2ff", "#e0e7ff"],
            auraColor: "#818cf8",
            sparkColors: ["#eef2ff", "#e0e7ff"],
            hasCirclet: false,
            hasSideSparks: false,
            eyeStyle: .wide
        ),
        AvatarStyle(
            id: "emerald",
            name: "Emerald Shine",
            outerColors: ["#a7f3d0", "#34d399", "#10b981", "#059669"],
            innerColors: ["#d1fae5", "#a7f3d0", "#6ee7b7"],
            coreColors: ["#ffffff", "#ecfdf5", "#d1fae5"],
            auraColor: "#34d399",
            sparkColors: ["#ecfdf5", "#d1fae5"],
            hasCirclet: true,
            hasSideSparks: true,
            eyeStyle: .normal
        ),
        AvatarStyle(
            id: "coral",
            name: "Coral Reef",
            outerColors: ["#fed7d7", "#fc8181", "#f56565", "#e53e3e"],
            innerColors: ["#fff5f5", "#fed7d7", "#fbb6b6"],
            coreColors: ["#ffffff", "#fffafa", "#fff5f5"],
            auraColor: "#fc8181",
            sparkColors: ["#fff5f5", "#fed7d7"],
            hasCirclet: false,
            hasSideSparks: true,
            eyeStyle: .excited
        ),
        AvatarStyle(
            id: "lavender",
            name: "Lavender Dream",
            outerColors: ["#ddd6fe", "#a78bfa", "#8b5cf6", "#6d28d9"],
            innerColors: ["#ede9fe", "#ddd6fe", "#c4b5fd"],
            coreColors: ["#ffffff", "#f5f3ff", "#ede9fe"],
            auraColor: "#a78bfa",
            sparkColors: ["#f5f3ff", "#ede9fe"],
            hasCirclet: true,
            hasSideSparks: false,
            eyeStyle: .sleepy
        ),
        AvatarStyle(
            id: "peach",
            name: "Peach Sunset",
            outerColors: ["#fed7aa", "#fdba74", "#fb923c", "#f97316"],
            innerColors: ["#fff7ed", "#fed7aa", "#fde68a"],
            coreColors: ["#fffef5", "#fff7ed", "#ffedd5"],
            auraColor: "#fdba74",
            sparkColors: ["#fff7ed", "#ffedd5"],
            hasCirclet: false,
            hasSideSparks: false,
            eyeStyle: .normal
        )
    ]
}

@MainActor
class AvatarManager: ObservableObject {
    @Published var selectedAvatarId: String {
        didSet {
            UserDefaults.standard.set(selectedAvatarId, forKey: "selectedAvatarId")
        }
    }
    
    init() {
        let savedId = UserDefaults.standard.string(forKey: "selectedAvatarId")
        self.selectedAvatarId = savedId ?? "classic"
    }
    
    var selectedStyle: AvatarStyle {
        AvatarStyle.presets.first { $0.id == selectedAvatarId } ?? AvatarStyle.presets[0]
    }
    
    func selectAvatar(_ id: String) {
        selectedAvatarId = id
    }
}
