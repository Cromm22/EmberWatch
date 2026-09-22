import SwiftUI

/// Shared Home colors for the compact streak pill and the streak / sparks / XP cards.
enum HomeStatBadgePalette {
    static let streakFill = Color(hex: "#FFEDE4")
    static let streakIcon = Color(hex: "#FF6B2C")
    static let streakInk = Color(hex: "#5A2A1C")

    static let sparksFill = Color(hex: "#EAF2FF")
    static let sparksIcon = Color(hex: "#4C82F7")
    static let sparksInk = Color(hex: "#1A2A4A")

    static let boostFill = Color(hex: "#FFF6D9")
    static let boostIcon = Color(hex: "#E6A817")
    static let boostInk = Color(hex: "#5C3D0A")
}

/// Compact top-right header badge: flame + streak day count (number only).
struct DailyStreakPill: View {
    let streak: Int

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: "flame.fill")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(HomeStatBadgePalette.streakIcon)
                .symbolRenderingMode(.monochrome)

            Text("\(max(0, streak))")
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(HomeStatBadgePalette.streakInk)
                .monospacedDigit()
        }
        .padding(.horizontal, 14)
        .frame(height: 32)
        .background(
            Capsule(style: .continuous)
                .fill(HomeStatBadgePalette.streakFill)
        )
        .fixedSize(horizontal: true, vertical: true)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Daily streak, day \(max(0, streak))")
    }
}

/// One of the three equal Home stat cards (Daily Streak / Sparks / XP Boost).
struct HomeStatBadgeCard: View {
    let icon: String
    let value: String
    let label: String
    let background: Color
    let iconColor: Color
    let valueColor: Color
    var action: (() -> Void)? = nil

    var body: some View {
        Group {
            if let action {
                Button(action: action) { cardContent }
                    .buttonStyle(.plain)
            } else {
                cardContent
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(label), \(value)")
        .accessibilityAddTraits(action == nil ? [] : .isButton)
    }

    private var cardContent: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(iconColor)
                    .symbolRenderingMode(.monochrome)

                Text(value)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(valueColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .monospacedDigit()

                Image(systemName: "chevron.right")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundStyle(valueColor.opacity(0.4))
            }

            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(valueColor.opacity(0.62))
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 10)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(background)
        )
    }
}

/// Horizontal row of the three Home stat cards, bound to live streak / sparks / XP boost.
struct HomeStatBadgeRow: View {
    let streak: Int
    let sparks: Int
    let xpBoost: String
    var onSparksTap: (() -> Void)? = nil

    var body: some View {
        HStack(spacing: 8) {
            HomeStatBadgeCard(
                icon: "flame.fill",
                value: "\(max(0, streak))d",
                label: "Daily Streak",
                background: HomeStatBadgePalette.streakFill,
                iconColor: HomeStatBadgePalette.streakIcon,
                valueColor: HomeStatBadgePalette.streakInk
            )

            HomeStatBadgeCard(
                icon: "sparkles",
                value: "+\(max(0, sparks))",
                label: "Sparks",
                background: HomeStatBadgePalette.sparksFill,
                iconColor: HomeStatBadgePalette.sparksIcon,
                valueColor: HomeStatBadgePalette.sparksInk,
                action: onSparksTap
            )

            HomeStatBadgeCard(
                icon: "rocket.fill",
                value: xpBoost,
                label: "XP Boost",
                background: HomeStatBadgePalette.boostFill,
                iconColor: HomeStatBadgePalette.boostIcon,
                valueColor: HomeStatBadgePalette.boostInk
            )
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview("Streak pill") {
    DailyStreakPill(streak: 6)
        .padding()
        .background(Color.white)
}

#Preview("Stat cards") {
    HomeStatBadgeRow(streak: 6, sparks: 340, xpBoost: "+30%")
        .padding()
        .background(Color.white)
}
