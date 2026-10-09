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
    static let rowSpacing: CGFloat = 8
    static let cardHeight: CGFloat = 74
    static let cardCornerRadius: CGFloat = 18
    static let cardPadding: CGFloat = 8
    /// Icon sits on the left and overlaps this inset so it matches the mock.
    static let iconLeading: CGFloat = 2
    /// ~76% of card height; drawn at this height so the glyph fills the slot.
    static let iconSize: CGFloat = 56
    static let iconTextSpacing: CGFloat = 2
    static let textStackSpacing: CGFloat = 1
    static let valueChevronSpacing: CGFloat = 2
    static let valueSize: CGFloat = 23
    static let labelSize: CGFloat = 8
    static let labelTracking: CGFloat = 0.55
    static let chevronSize: CGFloat = 12
    static let textMinimumScale: CGFloat = 0.5
    static let rimWidth: CGFloat = 1.35
    static let glowRadius: CGFloat = 6
}

/// Visual tokens for one Home stat card. Sampled from docs/mocks/badges-v3.png.
struct HomeStatBadgeStyle {
    let assetName: String
    let edge: Color
    let mid: Color
    let highlight: Color
    let rim: Color
    let glow: Color

    /// Deep red-orange: dark edges to a brighter center bloom.
    static let streak = HomeStatBadgeStyle(
        assetName: "BadgeFlame",
        edge: Color(hex: "#8E1F0E"),
        mid: Color(hex: "#C43316"),
        highlight: Color(hex: "#E8501A"),
        rim: Color(hex: "#F6B07A"),
        glow: Color(hex: "#E8501A")
    )

    /// Royal blue with a light-blue rim.
    static let crystals = HomeStatBadgeStyle(
        assetName: "BadgeCrystal",
        edge: Color(hex: "#1E3FA8"),
        mid: Color(hex: "#2B55C8"),
        highlight: Color(hex: "#3E6FE8"),
        rim: Color(hex: "#A8C8FF"),
        glow: Color(hex: "#3E6FE8")
    )

    /// Gold / amber with a golden rim.
    static let coins = HomeStatBadgeStyle(
        assetName: "BadgeCoins",
        edge: Color(hex: "#8A5A12"),
        mid: Color(hex: "#B87A22"),
        highlight: Color(hex: "#D9A23A"),
        rim: Color(hex: "#F3D27A"),
        glow: Color(hex: "#D9A23A")
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

/// Catalog icon from docs/mocks/badges-v3.png (BadgeFlame / Crystal / Coins).
/// Square slot is ~76% of card height; `scaledToFit` keeps the full glyph.
private struct HomeStatBadgeIcon: View {
    let assetName: String

    var body: some View {
        Image(assetName)
            .resizable()
            .scaledToFit()
            .frame(width: HomeStatBadgeMetrics.iconSize, height: HomeStatBadgeMetrics.iconSize)
            .accessibilityHidden(true)
    }
}

/// Diagonal card wash plus a brighter center bloom. Split so the type checker
/// does not have to solve one giant gradient expression.
private struct HomeStatBadgeFill: View {
    let style: HomeStatBadgeStyle

    var body: some View {
        ZStack {
            diagonal
            bloom
        }
    }

    private var diagonal: some View {
        LinearGradient(
            colors: [style.edge, style.mid, style.highlight, style.mid, style.edge],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var bloom: some View {
        RadialGradient(
            colors: [style.highlight.opacity(0.9), style.highlight.opacity(0)],
            center: UnitPoint(x: 0.46, y: 0.40),
            startRadius: 2,
            endRadius: 56
        )
    }
}

/// Lighter glowing inner rim on top of the filled card.
private struct HomeStatBadgeRim: View {
    let style: HomeStatBadgeStyle

    var body: some View {
        ZStack {
            outer
            inner
        }
        .allowsHitTesting(false)
    }

    private var outer: some View {
        RoundedRectangle(cornerRadius: HomeStatBadgeMetrics.cardCornerRadius, style: .continuous)
            .strokeBorder(outerGradient, lineWidth: HomeStatBadgeMetrics.rimWidth)
    }

    private var inner: some View {
        RoundedRectangle(
            cornerRadius: HomeStatBadgeMetrics.cardCornerRadius - 1.2,
            style: .continuous
        )
        .strokeBorder(Color.white.opacity(0.28), lineWidth: 0.7)
        .padding(1.4)
    }

    private var outerGradient: LinearGradient {
        LinearGradient(
            colors: [style.rim.opacity(0.95), style.rim.opacity(0.38), style.rim.opacity(0.78)],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}

private struct HomeStatBadgeChrome: View {
    let style: HomeStatBadgeStyle

    var body: some View {
        HomeStatBadgeFill(style: style)
            .clipShape(cardShape)
            .overlay(HomeStatBadgeRim(style: style))
            .shadow(
                color: style.glow.opacity(0.42),
                radius: HomeStatBadgeMetrics.glowRadius,
                x: 0,
                y: 2
            )
    }

    private var cardShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: HomeStatBadgeMetrics.cardCornerRadius, style: .continuous)
    }
}

/// Big white value + chevron on the first line, uppercase tracked label under it.
private struct HomeStatBadgeTexts: View {
    let value: String
    let label: String

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
                .foregroundStyle(Color.white)
                .lineLimit(1)
                .minimumScaleFactor(HomeStatBadgeMetrics.textMinimumScale)
                .monospacedDigit()
                .frame(minWidth: 0.0, alignment: .leading)

            Image(systemName: "chevron.right")
                .font(.system(size: HomeStatBadgeMetrics.chevronSize, weight: .bold))
                .foregroundStyle(Color.white.opacity(0.92))
                .fixedSize()
        }
    }

    private var labelText: some View {
        Text(label)
            .font(.system(size: HomeStatBadgeMetrics.labelSize, weight: .semibold))
            .tracking(HomeStatBadgeMetrics.labelTracking)
            .foregroundStyle(Color.white.opacity(0.92))
            .textCase(.uppercase)
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
            HomeStatBadgeIcon(assetName: style.assetName)
            HomeStatBadgeTexts(value: value, label: label)
        }
        .padding(.leading, HomeStatBadgeMetrics.iconLeading)
        .padding(.trailing, HomeStatBadgeMetrics.cardPadding)
        .frame(
            maxWidth: .infinity,
            minHeight: HomeStatBadgeMetrics.cardHeight,
            maxHeight: HomeStatBadgeMetrics.cardHeight,
            alignment: .leading
        )
        .clipShape(cardShape)
        .background(HomeStatBadgeChrome(style: style))
    }

    private var cardShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: HomeStatBadgeMetrics.cardCornerRadius, style: .continuous)
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

// MARK: - Daily quest card

enum HomeDailyQuestPalette {
    static let fill = Color(hex: "#FFF1E8")
    static let border = Color(hex: "#F3C2A0")
    static let title = Color(hex: "#1A1A1A")
    static let subtitle = Color(hex: "#8A8580")
    static let ribbonTop = Color(hex: "#F28A3C")
    static let ribbonBottom = Color(hex: "#E8641E")
    static let xp = Color(hex: "#F07820")
    static let stepTrack = Color(hex: "#E8E4DF")
    static let stepIdle = Color(hex: "#F4F1ED")
    static let stepDone = Color(hex: "#F28A3C")
    static let sun = Color(hex: "#F5A623")
    static let burgerTop = Color(hex: "#E0A36A")
    static let burgerPatty = Color(hex: "#8B5A32")
    static let moon = Color(hex: "#7B6FE0")
}

enum HomeDailyQuestMetrics {
    static let cardCorner: CGFloat = 22
    static let ribbonWidth: CGFloat = 62
    static let ribbonHeight: CGFloat = 96
    static let stepSize: CGFloat = 28
}

enum HomeDailyQuestGlyph: Equatable {
    case sun
    case burger
    case moon
    case symbol(String)
}

struct HomeDailyQuestStep: Equatable {
    let glyph: HomeDailyQuestGlyph
    let label: String
    let isComplete: Bool
}

/// Display-only copy and step layout for today's quest. Does not change quest logic.
enum HomeDailyQuestCopy {
    static func subtitle(for kind: DailyQuestKind) -> String {
        switch kind {
        case .logThreeMeals:
            return "Track breakfast, lunch, and dinner"
        case .proteinRange:
            return "Stay in today's protein target"
        case .movementGoal:
            return "Hit today's movement minutes"
        case .calorieRange:
            return "Stay in today's calorie range"
        case .recoveryGoal:
            return "Hit today's water goal"
        }
    }

    static func buttonTitle(for kind: DailyQuestKind) -> String {
        switch kind {
        case .logThreeMeals, .proteinRange, .calorieRange:
            return "Log Meal"
        case .movementGoal:
            return "Log Workout"
        case .recoveryGoal:
            return "Log Water"
        }
    }

    static func steps(
        kind: DailyQuestKind,
        breakfast: Bool,
        lunch: Bool,
        dinner: Bool,
        isComplete: Bool
    ) -> [HomeDailyQuestStep] {
        switch kind {
        case .logThreeMeals:
            return [
                HomeDailyQuestStep(glyph: .sun, label: "Breakfast", isComplete: breakfast),
                HomeDailyQuestStep(glyph: .burger, label: "Lunch", isComplete: lunch),
                HomeDailyQuestStep(glyph: .moon, label: "Dinner", isComplete: dinner)
            ]
        case .proteinRange:
            return [HomeDailyQuestStep(glyph: .symbol("leaf.fill"), label: "Protein", isComplete: isComplete)]
        case .movementGoal:
            return [HomeDailyQuestStep(glyph: .symbol("figure.run"), label: "Move", isComplete: isComplete)]
        case .calorieRange:
            return [HomeDailyQuestStep(glyph: .symbol("fork.knife"), label: "Calories", isComplete: isComplete)]
        case .recoveryGoal:
            return [HomeDailyQuestStep(glyph: .symbol("drop.fill"), label: "Water", isComplete: isComplete)]
        }
    }
}

private struct HomeDailyQuestRibbonShape: Shape {
    func path(in rect: CGRect) -> Path {
        let notch = min(12.0, rect.height * 0.14)
        var path = Path()
        path.move(to: CGPoint(x: 0, y: 0))
        path.addLine(to: CGPoint(x: rect.maxX, y: 0))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - notch))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: 0, y: rect.maxY - notch))
        path.closeSubpath()
        return path
    }
}

enum HomeDailyQuestRibbonFill {
    static var paint: LinearGradient {
        LinearGradient(
            colors: [HomeDailyQuestPalette.ribbonTop, HomeDailyQuestPalette.ribbonBottom],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}

private struct HomeDailyQuestRibbon: View {
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: "flag.fill")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Color.white)
                .padding(.top, 12)
            Text("DAILY\nQUEST")
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(Color.white)
                .multilineTextAlignment(.center)
                .tracking(0.65)
                .lineSpacing(1)
            Spacer(minLength: 0)
        }
        .frame(width: HomeDailyQuestMetrics.ribbonWidth, height: HomeDailyQuestMetrics.ribbonHeight)
        .background(ribbonBackground)
    }

    private var ribbonBackground: some View {
        HomeDailyQuestRibbonShape()
            .fill(HomeDailyQuestRibbonFill.paint)
    }
}

private struct HomeQuestBurgerGlyph: View {
    var body: some View {
        VStack(spacing: 1.1) {
            Capsule()
                .fill(HomeDailyQuestPalette.burgerTop)
                .frame(width: 13, height: 4)
            Capsule()
                .fill(HomeDailyQuestPalette.burgerPatty)
                .frame(width: 13, height: 2.4)
            Capsule()
                .fill(HomeDailyQuestPalette.burgerTop)
                .frame(width: 13, height: 3.4)
        }
        .frame(width: 14, height: 12)
    }
}

private struct HomeDailyQuestStepGlyph: View {
    let glyph: HomeDailyQuestGlyph
    let isComplete: Bool

    var body: some View {
        switch glyph {
        case .sun:
            Image(systemName: "sun.max.fill")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(HomeDailyQuestPalette.sun)
        case .burger:
            HomeQuestBurgerGlyph()
        case .moon:
            Image(systemName: "moon.fill")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(HomeDailyQuestPalette.moon)
        case .symbol(let name):
            Image(systemName: name)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(isComplete ? HomeDailyQuestPalette.stepDone : HomeDailyQuestPalette.subtitle)
        }
    }
}

private struct HomeDailyQuestStepDot: View {
    let step: HomeDailyQuestStep

    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                Circle()
                    .fill(step.isComplete ? HomeDailyQuestPalette.stepDone.opacity(0.18) : HomeDailyQuestPalette.stepIdle)
                    .overlay(circleStroke)
                    .frame(width: HomeDailyQuestMetrics.stepSize, height: HomeDailyQuestMetrics.stepSize)
                HomeDailyQuestStepGlyph(glyph: step.glyph, isComplete: step.isComplete)
            }
            Text(step.label)
                .font(.system(size: 9, weight: .regular))
                .foregroundStyle(HomeDailyQuestPalette.subtitle)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
        .frame(minWidth: 34)
    }

    private var circleStroke: some View {
        Circle()
            .strokeBorder(
                step.isComplete ? HomeDailyQuestPalette.stepDone : HomeDailyQuestPalette.stepTrack,
                lineWidth: 1
            )
    }
}

private struct HomeDailyQuestStepConnector: View {
    let isLit: Bool

    var body: some View {
        Rectangle()
            .fill(isLit ? HomeDailyQuestPalette.stepDone.opacity(0.55) : HomeDailyQuestPalette.stepTrack)
            .frame(height: 2)
            .frame(maxWidth: .infinity)
            .padding(.top, 13)
    }
}

private struct HomeDailyQuestStepTrack: View {
    let steps: [HomeDailyQuestStep]

    var body: some View {
        if steps.count <= 1 {
            single
        } else {
            multi
        }
    }

    @ViewBuilder
    private var single: some View {
        if let step = steps.first {
            HomeDailyQuestStepDot(step: step)
        }
    }

    private var multi: some View {
        HStack(alignment: .top, spacing: 0) {
            ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                if index > 0 {
                    HomeDailyQuestStepConnector(isLit: steps[index - 1].isComplete)
                }
                HomeDailyQuestStepDot(step: step)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

private struct HomeDailyQuestMain: View {
    let title: String
    let subtitle: String
    let steps: [HomeDailyQuestStep]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            texts
            HomeDailyQuestStepTrack(steps: steps)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 12)
    }

    private var texts: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(HomeDailyQuestPalette.title)
                .lineLimit(2)
                .minimumScaleFactor(0.7)
            Text(subtitle)
                .font(.system(size: 12, weight: .regular))
                .foregroundStyle(HomeDailyQuestPalette.subtitle)
                .lineLimit(2)
                .minimumScaleFactor(0.7)
        }
    }
}

enum HomeDailyQuestActionGradient {
    static var paint: LinearGradient {
        LinearGradient(
            colors: [Color(hex: "#F28A3C"), Color(hex: "#E8641E")],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
}

private struct HomeDailyQuestXPBadge: View {
    var body: some View {
        ZStack {
            Image(systemName: "hexagon.fill")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(HomeDailyQuestPalette.xp)
            Text("XP")
                .font(.system(size: 6, weight: .heavy))
                .foregroundStyle(Color.white)
        }
        .accessibilityHidden(true)
    }
}

private struct HomeDailyQuestXPLabel: View {
    var body: some View {
        HStack(spacing: 4) {
            Text("+\(XPRules.dailyQuestXP)")
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(HomeDailyQuestPalette.xp)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            HomeDailyQuestXPBadge()
        }
    }
}

private struct HomeDailyQuestActionFill: View {
    var body: some View {
        Capsule()
            .fill(HomeDailyQuestActionGradient.paint)
    }
}

private struct HomeDailyQuestActionButton: View {
    let title: String
    var onAction: (() -> Void)?

    var body: some View {
        Button {
            onAction?()
        } label: {
            label
        }
        .buttonStyle(.plain)
        .disabled(onAction == nil)
        .accessibilityLabel(title)
    }

    private var label: some View {
        HStack(spacing: 3) {
            Text(title)
                .font(.system(size: 13, weight: .bold))
                .lineLimit(1)
                .minimumScaleFactor(0.65)
            Image(systemName: "chevron.right")
                .font(.system(size: 11, weight: .bold))
        }
        .foregroundStyle(Color.white)
        .padding(.horizontal, 14)
        .padding(.vertical, 9)
        .background(HomeDailyQuestActionFill())
    }
}

private struct HomeDailyQuestReward: View {
    let isComplete: Bool
    let buttonTitle: String
    var onAction: (() -> Void)?

    var body: some View {
        VStack(alignment: .trailing, spacing: 10) {
            HomeDailyQuestXPLabel()
            HomeDailyQuestActionButton(
                title: isComplete ? "Done" : buttonTitle,
                onAction: onAction
            )
        }
        .frame(minWidth: 96, alignment: .trailing)
        .padding(.top, 12)
        .padding(.trailing, 12)
    }
}

private struct HomeDailyQuestChrome: View {
    var body: some View {
        RoundedRectangle(cornerRadius: HomeDailyQuestMetrics.cardCorner, style: .continuous)
            .fill(HomeDailyQuestPalette.fill)
            .overlay(border)
    }

    private var border: some View {
        RoundedRectangle(cornerRadius: HomeDailyQuestMetrics.cardCorner, style: .continuous)
            .strokeBorder(HomeDailyQuestPalette.border, lineWidth: 1.2)
    }
}

/// Home Daily Quest card. Bound to existing quest title / completion; steps and
/// the action button adapt per `DailyQuestKind` without changing quest logic.
struct HomeDailyQuestCard: View {
    let title: String
    let subtitle: String
    let isComplete: Bool
    let steps: [HomeDailyQuestStep]
    let buttonTitle: String
    var onAction: (() -> Void)? = nil

    var body: some View {
        content
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(accessibilityText)
            .accessibilityAddTraits(onAction == nil ? [] : .isButton)
            .accessibilityHint(onAction == nil ? "" : "Opens \(buttonTitle)")
            .accessibilityAction {
                onAction?()
            }
    }

    private var accessibilityText: String {
        let stepBits = steps
            .map { $0.isComplete ? "\($0.label) done" : $0.label }
            .joined(separator: ", ")
        let state = isComplete ? "complete" : "+\(XPRules.dailyQuestXP) XP"
        return "Daily quest, \(title), \(state), \(stepBits)"
    }

    private var content: some View {
        HStack(alignment: .top, spacing: 8) {
            HomeDailyQuestRibbon()
            HomeDailyQuestMain(title: title, subtitle: subtitle, steps: steps)
            HomeDailyQuestReward(
                isComplete: isComplete,
                buttonTitle: buttonTitle,
                onAction: onAction
            )
        }
        .padding(.bottom, 12)
        .padding(.leading, 12)
        .background(HomeDailyQuestChrome())
        .clipShape(
            RoundedRectangle(cornerRadius: HomeDailyQuestMetrics.cardCorner, style: .continuous)
        )
    }
}

// MARK: - Home XP bar

enum HomeXPBarGradient {
    static var fill: LinearGradient {
        LinearGradient(
            colors: [
                EmberColors.ember,
                EmberColors.emberAccent,
                Color.orange.opacity(0.9)
            ],
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    static var wave: LinearGradient {
        LinearGradient(
            colors: [
                Color.white.opacity(0),
                Color.white.opacity(0.3),
                Color.white.opacity(0)
            ],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
}

private struct HomeXPGainToast: View {
    let amount: Int
    let offset: CGFloat
    let opacity: Double

    var body: some View {
        HStack {
            Spacer()
            HStack(spacing: 4) {
                Image(systemName: "sparkle")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(EmberColors.ember)
                Text("+\(amount)")
                    .font(.headline.weight(.bold))
                    .foregroundColor(EmberColors.ember)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(toastFill)
            .offset(y: offset)
            .opacity(opacity)
            Spacer()
        }
    }

    private var toastFill: some View {
        Capsule()
            .fill(EmberColors.cream)
            .shadow(color: EmberColors.ember.opacity(0.4), radius: 8, y: 2)
    }
}

private struct HomeXPProgressTrack: View {
    let width: CGFloat
    let fraction: Double
    let level: Int
    let barScale: CGFloat
    let wavePhase: CGFloat

    var body: some View {
        ZStack(alignment: .leading) {
            RoundedRectangle(cornerRadius: 10)
                .fill(EmberColors.darkPlum)
                .frame(height: 36)
            fillLayer
            levelLabel
        }
    }

    private var fillWidth: CGFloat {
        width * CGFloat(min(1, max(0, fraction)))
    }

    private var fillLayer: some View {
        ZStack(alignment: .leading) {
            RoundedRectangle(cornerRadius: 10)
                .fill(HomeXPBarGradient.fill)
                .frame(width: fillWidth, height: 36)
                .scaleEffect(x: barScale, y: barScale, anchor: .leading)
            if fraction > 0 {
                wave
            }
        }
    }

    private var wave: some View {
        RoundedRectangle(cornerRadius: 10)
            .fill(HomeXPBarGradient.wave)
            .frame(width: 60, height: 36)
            .offset(x: wavePhase * fillWidth - 30)
            .mask(
                RoundedRectangle(cornerRadius: 10)
                    .frame(width: fillWidth, height: 36)
            )
    }

    private var levelLabel: some View {
        HStack {
            Spacer()
            Text(level >= LevelManager.maxLevel ? "Max Lv" : "Lv \(level)")
                .font(.subheadline.weight(.bold))
                .foregroundColor(.black)
                .shadow(color: Color.black.opacity(0.3), radius: 2, x: 0, y: 1)
                .shadow(color: EmberColors.cream.opacity(0.2), radius: 1, x: 0, y: 0)
            Spacer()
        }
        .frame(height: 36)
        .allowsHitTesting(false)
    }
}

/// Existing Home XP bar (level + progress to next). Extracted so HomeView can
/// place it under the hero and wrap it in a Character-sheet button.
struct HomeXPProgressBar: View {
    let level: Int
    let progressFraction: Double
    var barScale: CGFloat = 1
    var wavePhase: CGFloat = 0
    var showXPGain: Bool = false
    var xpGainAmount: Int = 0
    var xpGainOffset: CGFloat = 0
    var xpGainOpacity: Double = 0

    var body: some View {
        ZStack {
            GeometryReader { geometry in
                HomeXPProgressTrack(
                    width: geometry.size.width,
                    fraction: progressFraction,
                    level: level,
                    barScale: barScale,
                    wavePhase: wavePhase
                )
            }
            .frame(height: 36)

            if showXPGain {
                HomeXPGainToast(amount: xpGainAmount, offset: xpGainOffset, opacity: xpGainOpacity)
            }
        }
        .frame(height: 60)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(levelLabel)
    }

    private var levelLabel: String {
        if level >= LevelManager.maxLevel {
            return "Max level"
        }
        return "Level \(level), experience progress"
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
    HomeStatBadgeRow(streak: 23, crystals: 1000, coins: 215)
        .padding()
        .background(Color.white)
}

#Preview("Daily quest") {
    HomeDailyQuestCard(
        title: "Log all 3 meals",
        subtitle: "Track breakfast, lunch, and dinner",
        isComplete: false,
        steps: HomeDailyQuestCopy.steps(
            kind: .logThreeMeals,
            breakfast: true,
            lunch: false,
            dinner: false,
            isComplete: false
        ),
        buttonTitle: "Log Meal",
        onAction: {}
    )
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
