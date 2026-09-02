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
    let hasHorns: Bool
    let forceBlaze: Bool
    let eyeStyle: EyeStyle
    
    enum EyeStyle: String, Codable {
        case normal
        case wide
        case sleepy
        case excited
    }
    
    /// Exactly 20. Only `classic` uses amber/orange ember hues.
    static let presets: [AvatarStyle] = [
        AvatarStyle(
            id: "classic",
            name: "Classic Ember",
            outerColors: ["#ffe08a", "#ff9a3c", "#ff6a1a", "#d9480f"],
            innerColors: ["#fff6c8", "#ffd27a", "#ff9f43"],
            coreColors: ["#fffef5", "#ffe08a", "#ffb347"],
            auraColor: "#ff7a3c",
            sparkColors: ["#ffe08a", "#ffd27a"],
            hasCirclet: false, hasSideSparks: false, hasHorns: false, forceBlaze: false,
            eyeStyle: .normal
        ),
        AvatarStyle(
            id: "glacier",
            name: "Glacier",
            outerColors: ["#e0f2fe", "#7dd3fc", "#0ea5e9", "#075985"],
            innerColors: ["#f0f9ff", "#bae6fd", "#7dd3fc"],
            coreColors: ["#ffffff", "#f0f9ff", "#e0f2fe"],
            auraColor: "#38bdf8",
            sparkColors: ["#f0f9ff", "#bae6fd"],
            hasCirclet: false, hasSideSparks: true, hasHorns: false, forceBlaze: true,
            eyeStyle: .sleepy
        ),
        AvatarStyle(
            id: "aurora",
            name: "Aurora",
            outerColors: ["#a7f3d0", "#34d399", "#059669", "#064e3b"],
            innerColors: ["#ecfdf5", "#6ee7b7", "#34d399"],
            coreColors: ["#ffffff", "#d1fae5", "#a7f3d0"],
            auraColor: "#10b981",
            sparkColors: ["#ecfdf5", "#6ee7b7"],
            hasCirclet: true, hasSideSparks: true, hasHorns: false, forceBlaze: false,
            eyeStyle: .wide
        ),
        AvatarStyle(
            id: "nebula",
            name: "Nebula",
            outerColors: ["#e9d5ff", "#c084fc", "#7c3aed", "#4c1d95"],
            innerColors: ["#faf5ff", "#d8b4fe", "#a855f7"],
            coreColors: ["#ffffff", "#f3e8ff", "#e9d5ff"],
            auraColor: "#a855f7",
            sparkColors: ["#faf5ff", "#e9d5ff"],
            hasCirclet: true, hasSideSparks: false, hasHorns: true, forceBlaze: true,
            eyeStyle: .excited
        ),
        AvatarStyle(
            id: "cobalt",
            name: "Cobalt",
            outerColors: ["#bfdbfe", "#3b82f6", "#1d4ed8", "#1e3a8a"],
            innerColors: ["#eff6ff", "#93c5fd", "#60a5fa"],
            coreColors: ["#ffffff", "#dbeafe", "#bfdbfe"],
            auraColor: "#2563eb",
            sparkColors: ["#eff6ff", "#93c5fd"],
            hasCirclet: false, hasSideSparks: true, hasHorns: false, forceBlaze: false,
            eyeStyle: .normal
        ),
        AvatarStyle(
            id: "plasma",
            name: "Plasma",
            outerColors: ["#f5d0fe", "#e879f9", "#c026d3", "#86198f"],
            innerColors: ["#fdf4ff", "#f0abfc", "#e879f9"],
            coreColors: ["#ffffff", "#fae8ff", "#f5d0fe"],
            auraColor: "#d946ef",
            sparkColors: ["#fdf4ff", "#f0abfc"],
            hasCirclet: false, hasSideSparks: true, hasHorns: true, forceBlaze: true,
            eyeStyle: .excited
        ),
        AvatarStyle(
            id: "mint",
            name: "Mint Storm",
            outerColors: ["#ccfbf1", "#2dd4bf", "#0f766e", "#134e4a"],
            innerColors: ["#f0fdfa", "#99f6e4", "#5eead4"],
            coreColors: ["#ffffff", "#ccfbf1", "#99f6e4"],
            auraColor: "#14b8a6",
            sparkColors: ["#f0fdfa", "#99f6e4"],
            hasCirclet: true, hasSideSparks: false, hasHorns: false, forceBlaze: false,
            eyeStyle: .sleepy
        ),
        AvatarStyle(
            id: "ink",
            name: "Ink Flame",
            outerColors: ["#cbd5e1", "#64748b", "#334155", "#0f172a"],
            innerColors: ["#f1f5f9", "#94a3b8", "#64748b"],
            coreColors: ["#ffffff", "#e2e8f0", "#cbd5e1"],
            auraColor: "#475569",
            sparkColors: ["#f8fafc", "#e2e8f0"],
            hasCirclet: false, hasSideSparks: false, hasHorns: false, forceBlaze: false,
            eyeStyle: .sleepy
        ),
        AvatarStyle(
            id: "lime",
            name: "Voltage",
            outerColors: ["#ecfccb", "#a3e635", "#65a30d", "#365314"],
            innerColors: ["#f7fee7", "#d9f99d", "#bef264"],
            coreColors: ["#ffffff", "#ecfccb", "#d9f99d"],
            auraColor: "#84cc16",
            sparkColors: ["#fefce8", "#d9f99d"],
            hasCirclet: false, hasSideSparks: true, hasHorns: true, forceBlaze: true,
            eyeStyle: .wide
        ),
        AvatarStyle(
            id: "rose",
            name: "Rose Quartz",
            outerColors: ["#ffe4e6", "#fb7185", "#e11d48", "#9f1239"],
            innerColors: ["#fff1f2", "#fecdd3", "#fda4af"],
            coreColors: ["#ffffff", "#fff1f2", "#ffe4e6"],
            auraColor: "#f43f5e",
            sparkColors: ["#fff1f2", "#fecdd3"],
            hasCirclet: true, hasSideSparks: false, hasHorns: false, forceBlaze: false,
            eyeStyle: .excited
        ),
        AvatarStyle(
            id: "sapphire",
            name: "Deep Sapphire",
            outerColors: ["#a5b4fc", "#6366f1", "#3730a3", "#1e1b4b"],
            innerColors: ["#e0e7ff", "#a5b4fc", "#818cf8"],
            coreColors: ["#ffffff", "#eef2ff", "#c7d2fe"],
            auraColor: "#4f46e5",
            sparkColors: ["#eef2ff", "#c7d2fe"],
            hasCirclet: true, hasSideSparks: true, hasHorns: false, forceBlaze: true,
            eyeStyle: .wide
        ),
        AvatarStyle(
            id: "seafoam",
            name: "Seafoam",
            outerColors: ["#a5f3fc", "#22d3ee", "#0891b2", "#164e63"],
            innerColors: ["#ecfeff", "#67e8f9", "#22d3ee"],
            coreColors: ["#ffffff", "#cffafe", "#a5f3fc"],
            auraColor: "#06b6d4",
            sparkColors: ["#ecfeff", "#67e8f9"],
            hasCirclet: false, hasSideSparks: true, hasHorns: false, forceBlaze: false,
            eyeStyle: .normal
        ),
        AvatarStyle(
            id: "orchid",
            name: "Orchid",
            outerColors: ["#f5d0fe", "#d946ef", "#a21caf", "#701a75"],
            innerColors: ["#fdf4ff", "#e879f9", "#d946ef"],
            coreColors: ["#ffffff", "#fae8ff", "#f5d0fe"],
            auraColor: "#c026d3",
            sparkColors: ["#fdf4ff", "#f0abfc"],
            hasCirclet: true, hasSideSparks: false, hasHorns: true, forceBlaze: false,
            eyeStyle: .excited
        ),
        AvatarStyle(
            id: "silver",
            name: "Silver Ghost",
            outerColors: ["#f8fafc", "#cbd5e1", "#94a3b8", "#475569"],
            innerColors: ["#ffffff", "#e2e8f0", "#cbd5e1"],
            coreColors: ["#ffffff", "#f8fafc", "#e2e8f0"],
            auraColor: "#94a3b8",
            sparkColors: ["#ffffff", "#e2e8f0"],
            hasCirclet: true, hasSideSparks: true, hasHorns: false, forceBlaze: true,
            eyeStyle: .sleepy
        ),
        AvatarStyle(
            id: "crimson",
            name: "Crimson Veil",
            outerColors: ["#fecaca", "#ef4444", "#b91c1c", "#7f1d1d"],
            innerColors: ["#fef2f2", "#fca5a5", "#f87171"],
            coreColors: ["#ffffff", "#fee2e2", "#fecaca"],
            auraColor: "#dc2626",
            sparkColors: ["#fef2f2", "#fecaca"],
            hasCirclet: false, hasSideSparks: false, hasHorns: true, forceBlaze: true,
            eyeStyle: .wide
        ),
        AvatarStyle(
            id: "moss",
            name: "Moss Spirit",
            outerColors: ["#bbf7d0", "#4ade80", "#15803d", "#14532d"],
            innerColors: ["#f0fdf4", "#86efac", "#4ade80"],
            coreColors: ["#ffffff", "#dcfce7", "#bbf7d0"],
            auraColor: "#22c55e",
            sparkColors: ["#f0fdf4", "#86efac"],
            hasCirclet: false, hasSideSparks: true, hasHorns: false, forceBlaze: false,
            eyeStyle: .normal
        ),
        AvatarStyle(
            id: "ultraviolet",
            name: "Ultraviolet",
            outerColors: ["#ddd6fe", "#8b5cf6", "#5b21b6", "#2e1065"],
            innerColors: ["#f5f3ff", "#c4b5fd", "#a78bfa"],
            coreColors: ["#ffffff", "#ede9fe", "#ddd6fe"],
            auraColor: "#7c3aed",
            sparkColors: ["#f5f3ff", "#c4b5fd"],
            hasCirclet: true, hasSideSparks: true, hasHorns: true, forceBlaze: true,
            eyeStyle: .excited
        ),
        AvatarStyle(
            id: "lagoon",
            name: "Lagoon",
            outerColors: ["#99f6e4", "#2dd4bf", "#0e7490", "#164e63"],
            innerColors: ["#f0fdfa", "#5eead4", "#2dd4bf"],
            coreColors: ["#ffffff", "#ccfbf1", "#99f6e4"],
            auraColor: "#14b8a6",
            sparkColors: ["#f0fdfa", "#5eead4"],
            hasCirclet: false, hasSideSparks: false, hasHorns: false, forceBlaze: false,
            eyeStyle: .sleepy
        ),
        AvatarStyle(
            id: "neon",
            name: "Neon Night",
            outerColors: ["#a5f3fc", "#22d3ee", "#db2777", "#9d174d"],
            innerColors: ["#ecfeff", "#67e8f9", "#f472b6"],
            coreColors: ["#ffffff", "#fce7f3", "#a5f3fc"],
            auraColor: "#ec4899",
            sparkColors: ["#ecfeff", "#fbcfe8"],
            hasCirclet: false, hasSideSparks: true, hasHorns: true, forceBlaze: true,
            eyeStyle: .wide
        ),
        AvatarStyle(
            id: "pearl",
            name: "Pearl Mist",
            outerColors: ["#fce7f3", "#e9d5ff", "#c4b5fd", "#7e22ce"],
            innerColors: ["#fdf4ff", "#f5d0fe", "#e9d5ff"],
            coreColors: ["#ffffff", "#faf5ff", "#fce7f3"],
            auraColor: "#c084fc",
            sparkColors: ["#fdf4ff", "#f5d0fe"],
            hasCirclet: true, hasSideSparks: false, hasHorns: false, forceBlaze: false,
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
        let savedId = UserDefaults.standard.string(forKey: "selectedAvatarId") ?? "classic"
        // Migrate away from removed amber-ish ids
        let valid = Set(AvatarStyle.presets.map(\.id))
        self.selectedAvatarId = valid.contains(savedId) ? savedId : "classic"
    }
    
    var selectedStyle: AvatarStyle {
        AvatarStyle.presets.first { $0.id == selectedAvatarId } ?? AvatarStyle.presets[0]
    }
    
    func selectAvatar(_ id: String) {
        selectedAvatarId = id
    }
}
