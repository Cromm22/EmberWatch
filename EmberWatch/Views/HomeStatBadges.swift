import SwiftUI

/// Compact header-pill colors. Separate from the three Home cards so restyling
/// the cards does not retint the top-right streak capsule.
enum HomeStatBadgePalette {
    static let streakFill = Color(hex: "#FFD2B3")
    static let streakIcon = Color(hex: "#FF5314")
    static let streakInk = Color(hex: "#6B2410")
}

/// Layout tokens for the three Home stat cards. File-level so these are not
/// MainActor-isolated with the SwiftUI views.
enum HomeStatBadgeMetrics {
    static let rowSpacing: CGFloat = 10
    static let cardHeight: CGFloat = 72
    static let cardCornerRadius: CGFloat = 16
    static let cardPadding: CGFloat = 12
    static let iconSize: CGFloat = 28
    static let iconTextSpacing: CGFloat = 8
    static let textStackSpacing: CGFloat = 2
    static let valueChevronSpacing: CGFloat = 3
    static let valueSize: CGFloat = 20
    static let labelSize: CGFloat = 13
    static let chevronSize: CGFloat = 11
    static let textMinimumScale: CGFloat = 0.7
}

/// Visual tokens for one Home stat card. Sampled from the design mock PNG.
struct HomeStatBadgeStyle {
    let fill: Color
    let iconName: String
    let iconTop: Color
    let iconBottom: Color
    let valueColor: Color
    let labelColor: Color
    let chevronColor: Color

    /// Pale peach fill, orange-to-red-orange flame.
    static let streak = HomeStatBadgeStyle(
        fill: Color(hex: "#FED7BF"),
        iconName: "flame.fill",
        iconTop: Color(hex: "#FF7A18"),
        iconBottom: Color(hex: "#FD3D00"),
        valueColor: Color(hex: "#1A1A1A"),
        labelColor: Color(hex: "#855F49"),
        chevronColor: Color(hex: "#9A9A9A")
    )

    /// Pale periwinkle fill, crystal diamond.
    static let crystals = HomeStatBadgeStyle(
        fill: Color(hex: "#BDD5FD"),
        iconName: "diamond.fill",
        iconTop: Color(hex: "#2F5BEA"),
        iconBottom: Color(hex: "#2F5BEA"),
        valueColor: Color(hex: "#1A1A1A"),
        labelColor: Color(hex: "#5D78B2"),
        chevronColor: Color(hex: "#9A9A9A")
    )

    /// Pale butter-yellow fill, gold coin.
    static let coins = HomeStatBadgeStyle(
        fill: Color(hex: "#FEE5A5"),
        iconName: "circle.fill",
        iconTop: Color(hex: "#E8B923"),
        iconBottom: Color(hex: "#C98A12"),
        valueColor: Color(hex: "#1A1A1A"),
        labelColor: Color(hex: "#A57A22"),
        chevronColor: Color(hex: "#9A9A9A")
    )
}

/// Opaque tooltip chrome. File-level so these colors are not MainActor-isolated
/// with the SwiftUI views. Do not use `EmberColors.cream` here — that token is
/// near-black in the light theme and disappears on a dark popover.
enum HomeStatTooltipPalette {
    static let fill = Color(hex: "#1F1F24")
    static let text = Color.white
}

/// Compact name bubble shown when a Home streak / XP badge is tapped.
/// Solid near-black fill + white text so it stays readable on pastel cards.
/// Presentation chrome lives here so the modifier body stays type-checker thin.
private struct HomeStatTooltipLabel: View {
    let text: String

    var body: some View {
        label
            .presentationCompactAdaptation(.popover)
            .presentationBackground(HomeStatTooltipPalette.fill)
            .presentationCornerRadius(12)
    }

    private var label: some View {
        Text(text)
            .font(.system(size: 13, weight: .semibold, design: .rounded))
            .foregroundStyle(HomeStatTooltipPalette.text)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(HomeStatTooltipPalette.fill, ignoresSafeAreaEdges: [])
            .fixedSize()
    }
}

/// Anchors a small auto-dismissing popover to a badge. Tap elsewhere also dismisses.
private struct HomeStatTooltipModifier: ViewModifier {
    let text: String
    var arrowEdge: Edge = .top
    @State private var isPresented = false

    func body(content: Content) -> some View {
        Button {
            isPresented = true
        } label: {
            content
        }
        .buttonStyle(.plain)
        .popover(isPresented: $isPresented, arrowEdge: arrowEdge) {
            HomeStatTooltipLabel(text: text)
                .onTapGesture { isPresented = false }
        }
        .task(id: isPresented) {
            guard isPresented else { return }
            do {
                try await Task.sleep(for: .seconds(2))
                isPresented = false
            } catch {
                // Cancelled because the bubble was already dismissed.
            }
        }
    }
}

private extension View {
    func homeStatTooltip(_ text: String, arrowEdge: Edge = .top) -> some View {
        modifier(HomeStatTooltipModifier(text: text, arrowEdge: arrowEdge))
    }
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
        .homeStatTooltip("Daily Streak", arrowEdge: .top)
        .fixedSize(horizontal: true, vertical: true)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Daily streak, day \(max(0, streak))")
        .accessibilityAddTraits(.isButton)
        .accessibilityHint("Shows Daily Streak")
    }
}

/// Large left icon for a Home stat card. Always a two-stop vertical gradient
/// (solid icons use the same color twice) so the type checker sees one path.
private struct HomeStatBadgeIcon: View {
    let name: String
    let topColor: Color
    let bottomColor: Color

    var body: some View {
        Image(systemName: name)
            .font(.system(size: HomeStatBadgeMetrics.iconSize, weight: .semibold))
            .symbolRenderingMode(.monochrome)
            .foregroundStyle(fill)
            .frame(width: HomeStatBadgeMetrics.iconSize, height: HomeStatBadgeMetrics.iconSize)
    }

    private var fill: LinearGradient {
        LinearGradient(
            colors: [topColor, bottomColor],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}

/// Value + gray chevron on the first line, label on the second.
private struct HomeStatBadgeTexts: View {
    let value: String
    let label: String
    let valueColor: Color
    let labelColor: Color
    let chevronColor: Color

    var body: some View {
        VStack(alignment: .leading, spacing: HomeStatBadgeMetrics.textStackSpacing) {
            valueRow
            labelText
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var valueRow: some View {
        HStack(spacing: HomeStatBadgeMetrics.valueChevronSpacing) {
            Text(value)
                .font(.system(size: HomeStatBadgeMetrics.valueSize, weight: .bold, design: .rounded))
                .foregroundStyle(valueColor)
                .lineLimit(1)
                .minimumScaleFactor(HomeStatBadgeMetrics.textMinimumScale)
                .monospacedDigit()
                .frame(minWidth: 0.0, alignment: .leading)

            Image(systemName: "chevron.right")
                .font(.system(size: HomeStatBadgeMetrics.chevronSize, weight: .semibold))
                .foregroundStyle(chevronColor)
                .fixedSize()
        }
    }

    private var labelText: some View {
        Text(label)
            .font(.system(size: HomeStatBadgeMetrics.labelSize, weight: .medium))
            .foregroundStyle(labelColor)
            .lineLimit(1)
            .minimumScaleFactor(HomeStatBadgeMetrics.textMinimumScale)
            .frame(minWidth: 0.0, maxWidth: .infinity, alignment: .leading)
    }
}

/// One of the three equal Home stat cards (Daily Streak / Crystals / Coins).
struct HomeStatBadgeCard: View {
    let value: String
    let label: String
    let style: HomeStatBadgeStyle
    var action: (() -> Void)? = nil
    var tooltip: String? = nil
    var tooltipArrowEdge: Edge = .bottom

    private var isTappable: Bool { action != nil || tooltip != nil }

    var body: some View {
        tappableCard
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("\(label), \(value)")
            .accessibilityAddTraits(isTappable ? .isButton : [])
            .accessibilityHint(tooltip.map { "Shows \($0)" } ?? "")
    }

    @ViewBuilder
    private var tappableCard: some View {
        if let action {
            Button {
                action()
            } label: {
                cardContent
            }
            .buttonStyle(.plain)
        } else if let tooltip {
            cardContent
                .homeStatTooltip(tooltip, arrowEdge: tooltipArrowEdge)
        } else {
            cardContent
        }
    }

    private var cardContent: some View {
        HStack(spacing: HomeStatBadgeMetrics.iconTextSpacing) {
            HomeStatBadgeIcon(
                name: style.iconName,
                topColor: style.iconTop,
                bottomColor: style.iconBottom
            )
            HomeStatBadgeTexts(
                value: value,
                label: label,
                valueColor: style.valueColor,
                labelColor: style.labelColor,
                chevronColor: style.chevronColor
            )
        }
        .padding(.horizontal, HomeStatBadgeMetrics.cardPadding)
        .frame(
            maxWidth: .infinity,
            minHeight: HomeStatBadgeMetrics.cardHeight,
            maxHeight: HomeStatBadgeMetrics.cardHeight,
            alignment: .leading
        )
        .background(cardFill)
    }

    private var cardFill: some View {
        RoundedRectangle(cornerRadius: HomeStatBadgeMetrics.cardCornerRadius, style: .continuous)
            .fill(style.fill)
    }
}

/// Horizontal row of the three Home stat cards, bound to live streak / crystals / coins.
struct HomeStatBadgeRow: View {
    let streak: Int
    let crystals: Int
    let coins: Int
    var onCrystalsTap: (() -> Void)? = nil
    var onCoinsTap: (() -> Void)? = nil

    var body: some View {
        HStack(spacing: HomeStatBadgeMetrics.rowSpacing) {
            streakCard
            crystalsCard
            coinsCard
        }
        .frame(maxWidth: .infinity)
    }

    private var streakCard: some View {
        HomeStatBadgeCard(
            value: "\(max(0, streak))d",
            label: "Daily Streak",
            style: HomeStatBadgeStyle.streak,
            tooltip: "Daily Streak"
        )
    }

    private var crystalsCard: some View {
        HomeStatBadgeCard(
            value: XPRules.groupedNumber(max(0, crystals)),
            label: "Crystals",
            style: HomeStatBadgeStyle.crystals,
            action: onCrystalsTap
        )
    }

    private var coinsCard: some View {
        HomeStatBadgeCard(
            value: XPRules.groupedNumber(max(0, coins)),
            label: "Coins",
            style: HomeStatBadgeStyle.coins,
            action: onCoinsTap
        )
    }
}

/// Compact Home card for the rotating daily quest.
struct HomeDailyQuestCard: View {
    let title: String
    let isComplete: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: isComplete ? "checkmark.circle.fill" : "flag.fill")
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(isComplete ? Color(hex: "#2FA36A") : EmberColors.ember)
                .frame(width: 28, height: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text("Daily Quest")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color(hex: "#855F49"))
                Text(title)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color(hex: "#1A1A1A"))
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
            }

            Spacer(minLength: 8)

            Text(isComplete ? "Done" : "+\(XPRules.dailyQuestXP) XP")
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(isComplete ? Color(hex: "#2FA36A") : EmberColors.ember)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(hex: "#FFE4D2"))
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Daily quest, \(title), \(isComplete ? "complete" : "+\(XPRules.dailyQuestXP) XP")")
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
    HomeStatBadgeRow(streak: 20, crystals: 805, coins: 1250)
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
