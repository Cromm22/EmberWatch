import SwiftUI

/// Shared Home colors for the compact streak pill and the streak / sparks / XP cards.
enum HomeStatBadgePalette {
    // Richer peach / orange — same hue family, higher chroma than the original pastels.
    static let streakFill = Color(hex: "#FFD2B3")
    static let streakIcon = Color(hex: "#FF5314")
    static let streakInk = Color(hex: "#6B2410")

    // Richer sky blue
    static let sparksFill = Color(hex: "#BDD5FF")
    static let sparksIcon = Color(hex: "#2568F5")
    static let sparksInk = Color(hex: "#122E68")

    // Richer gold / amber
    static let boostFill = Color(hex: "#FFE6A3")
    static let boostIcon = Color(hex: "#E89800")
    static let boostInk = Color(hex: "#6B4000")
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

/// Soft pastel fills for the Home Quick Actions row (Log Food / Workout / Progress / Goals).
enum HomeQuickActionPalette {
    static let foodFill = Color(hex: "#FFE4D2")
    static let foodIcon = Color(hex: "#FF6A2B")

    static let workoutFill = Color(hex: "#D9E6FF")
    static let workoutIcon = Color(hex: "#3B6FE8")

    static let progressFill = Color(hex: "#E6DEFF")
    static let progressIcon = Color(hex: "#7B63E0")

    static let goalsFill = Color(hex: "#D8F3E6")
    static let goalsIcon = Color(hex: "#2FA36A")

    static let label = Color(hex: "#1A1A1A")
}

/// One colored Quick Action tile on Home (icon above label).
struct HomeQuickActionButton: View {
    let icon: String
    let title: String
    let fill: Color
    let iconColor: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(iconColor)
                    .symbolRenderingMode(.monochrome)
                    .frame(height: 30)

                Text(title)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(HomeQuickActionPalette.label)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(fill)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
        .accessibilityAddTraits(.isButton)
    }
}

/// Four-up Quick Actions row: Log Food, Log Workout, Progress, Goals.
struct HomeQuickActionRow: View {
    var onLogFood: () -> Void
    var onLogWorkout: () -> Void
    var onProgress: () -> Void
    var onGoals: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            HomeQuickActionButton(
                icon: "plus.circle.fill",
                title: "Log Food",
                fill: HomeQuickActionPalette.foodFill,
                iconColor: HomeQuickActionPalette.foodIcon,
                action: onLogFood
            )

            HomeQuickActionButton(
                icon: "figure.run",
                title: "Log Workout",
                fill: HomeQuickActionPalette.workoutFill,
                iconColor: HomeQuickActionPalette.workoutIcon,
                action: onLogWorkout
            )

            HomeQuickActionButton(
                icon: "chart.bar.fill",
                title: "Progress",
                fill: HomeQuickActionPalette.progressFill,
                iconColor: HomeQuickActionPalette.progressIcon,
                action: onProgress
            )

            HomeQuickActionButton(
                icon: "doc.fill",
                title: "Goals",
                fill: HomeQuickActionPalette.goalsFill,
                iconColor: HomeQuickActionPalette.goalsIcon,
                action: onGoals
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

#Preview("Quick actions") {
    HomeQuickActionRow(
        onLogFood: {},
        onLogWorkout: {},
        onProgress: {},
        onGoals: {}
    )
    .padding()
    .background(Color.white)
}
