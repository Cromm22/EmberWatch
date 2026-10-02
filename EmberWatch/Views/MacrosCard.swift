import SwiftUI

/// Layout tokens and helpers for the Home / Food Macros card.
/// File-level so these are not MainActor-isolated with the SwiftUI views.
enum MacrosCardChrome {
    static let cardCornerRadius: CGFloat = 16
    static let tileCornerRadius: CGFloat = 12
    static let gridSpacing: CGFloat = 12
    static let ringSize: CGFloat = 102
    static let ringLineWidth: CGFloat = 9
    static let tileFill = Color(hex: "#F3F4F6")
    
    /// Consumed / target, clamped to 0...1. A zero or negative target is an empty ring.
    static func clampedProgress(consumed: Double, target: Double) -> CGFloat {
        guard target > 0.0 else { return 0.0 }
        let ratio = consumed / target
        let notBelowZero = max(ratio, 0.0)
        let notAboveOne = min(notBelowZero, 1.0)
        return CGFloat(notAboveOne)
    }
    
    static func amountText(amount: Int) -> String {
        amount.formatted()
    }
    
    /// "/ 180g" or "/ 2,300mg" using the locale thousands separator.
    static func targetText(target: Int, unit: String) -> String {
        let goal = target.formatted()
        return "/ \(goal)\(unit)"
    }
}

/// White Macros card: Today's Summary title style + a 2×2 of ring tiles.
struct MacrosCard: View {
    let protein: Double
    let carbs: Double
    let fat: Double
    let sodium: Double
    let proteinTarget: Double
    let carbsTarget: Double
    let fatTarget: Double
    let sodiumTarget: Double
    
    var body: some View {
        VStack(spacing: 12) {
            titleRow
            grid
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(cardBackground)
    }
    
    private var titleRow: some View {
        Text("Macros")
            .font(.headline)
            .fontWeight(.bold)
            .foregroundColor(EmberColors.cream)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private var grid: some View {
        DailyMacrosGrid(
            protein: protein,
            carbs: carbs,
            fat: fat,
            sodium: sodium,
            proteinTarget: proteinTarget,
            carbsTarget: carbsTarget,
            fatTarget: fatTarget,
            sodiumTarget: sodiumTarget
        )
    }
    
    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: MacrosCardChrome.cardCornerRadius)
            .fill(Color.white)
    }
}

/// 2×2 grid: Protein / Carbs on top, Fat / Sodium on the bottom.
struct DailyMacrosGrid: View {
    let protein: Double
    let carbs: Double
    let fat: Double
    let sodium: Double
    let proteinTarget: Double
    let carbsTarget: Double
    let fatTarget: Double
    let sodiumTarget: Double
    
    var body: some View {
        VStack(spacing: MacrosCardChrome.gridSpacing) {
            topRow
            bottomRow
        }
        .frame(maxWidth: .infinity)
    }
    
    private var topRow: some View {
        HStack(spacing: MacrosCardChrome.gridSpacing) {
            proteinTile
            carbsTile
        }
    }
    
    private var bottomRow: some View {
        HStack(spacing: MacrosCardChrome.gridSpacing) {
            fatTile
            sodiumTile
        }
    }
    
    private var proteinTile: some View {
        MacroCard(
            name: "Protein",
            consumed: protein,
            target: proteinTarget,
            unit: "g",
            color: Color.orange,
            icon: "flame.fill"
        )
    }
    
    private var carbsTile: some View {
        MacroCard(
            name: "Carbs",
            consumed: carbs,
            target: carbsTarget,
            unit: "g",
            color: Color.blue,
            icon: "bolt.fill"
        )
    }
    
    private var fatTile: some View {
        MacroCard(
            name: "Fat",
            consumed: fat,
            target: fatTarget,
            unit: "g",
            color: Color.yellow,
            icon: "drop.fill"
        )
    }
    
    private var sodiumTile: some View {
        MacroCard(
            name: "Sodium",
            consumed: sodium,
            target: sodiumTarget,
            unit: "mg",
            color: Color.teal,
            icon: "humidity.fill"
        )
    }
}

/// One light-gray tile: large ring (icon + value + target inside) and a name under it.
struct MacroCard: View {
    let name: String
    let consumed: Double
    let target: Double
    let unit: String
    let color: Color
    let icon: String
    
    var body: some View {
        VStack(spacing: 8) {
            ringBlock
            nameLabel
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .padding(.horizontal, 8)
        .background(tileBackground)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityText)
    }
    
    private var amountInt: Int {
        Int(consumed.rounded())
    }
    
    private var targetInt: Int {
        Int(target.rounded())
    }
    
    private var ringProgress: CGFloat {
        MacrosCardChrome.clampedProgress(consumed: consumed, target: target)
    }
    
    private var amountString: String {
        MacrosCardChrome.amountText(amount: amountInt)
    }
    
    private var targetString: String {
        MacrosCardChrome.targetText(target: targetInt, unit: unit)
    }
    
    private var accessibilityText: String {
        "\(name), \(amountInt) of \(targetInt) \(unit)"
    }
    
    private var ringBlock: some View {
        ZStack {
            MacroRingView(progress: ringProgress, color: color)
            MacroRingCenter(
                icon: icon,
                color: color,
                amountText: amountString,
                targetText: targetString
            )
        }
        .frame(width: MacrosCardChrome.ringSize, height: MacrosCardChrome.ringSize)
    }
    
    private var nameLabel: some View {
        Text(name)
            .font(.caption)
            .fontWeight(.medium)
            .foregroundColor(EmberColors.muted)
    }
    
    private var tileBackground: some View {
        RoundedRectangle(cornerRadius: MacrosCardChrome.tileCornerRadius)
            .fill(MacrosCardChrome.tileFill)
    }
}

/// Icon, bold consumed value, and "/ 180g" stacked in the center of a ring.
private struct MacroRingCenter: View {
    let icon: String
    let color: Color
    let amountText: String
    let targetText: String
    
    var body: some View {
        VStack(spacing: 2) {
            iconView
            amountView
            targetView
        }
        .padding(.horizontal, 12)
    }
    
    private var iconView: some View {
        Image(systemName: icon)
            .font(.system(size: 14, weight: .semibold))
            .foregroundColor(color)
            .symbolRenderingMode(.monochrome)
            .accessibilityHidden(true)
    }
    
    private var amountView: some View {
        Text(amountText)
            .font(.system(size: 22, weight: .bold, design: .rounded))
            .foregroundColor(EmberColors.cream)
            .lineLimit(1)
            .minimumScaleFactor(0.6)
            .monospacedDigit()
            .multilineTextAlignment(.center)
    }
    
    private var targetView: some View {
        Text(targetText)
            .font(.system(size: 11, weight: .medium, design: .rounded))
            .foregroundColor(EmberColors.muted)
            .lineLimit(1)
            .minimumScaleFactor(0.5)
            .monospacedDigit()
            .multilineTextAlignment(.center)
    }
}

/// Same-hue tinted track + colored progress arc. Starts at 12 o'clock, clockwise.
private struct MacroRingView: View {
    let progress: CGFloat
    let color: Color
    
    var body: some View {
        ZStack {
            track
            progressArc
        }
    }
    
    private var track: some View {
        Circle()
            .stroke(trackColor, lineWidth: MacrosCardChrome.ringLineWidth)
    }
    
    private var progressArc: some View {
        Circle()
            .trim(from: trimStart, to: progress)
            .stroke(color, style: progressStroke)
            .rotationEffect(startAngle)
    }
    
    private var trackColor: Color {
        color.opacity(0.22)
    }
    
    private var trimStart: CGFloat { 0 }
    
    private var startAngle: Angle { Angle(degrees: -90) }
    
    private var progressStroke: StrokeStyle {
        StrokeStyle(lineWidth: MacrosCardChrome.ringLineWidth, lineCap: CGLineCap.round)
    }
}
