import SwiftUI

/// Layout tokens and helpers for the Home / Food Macros rings.
/// File-level so these are not MainActor-isolated with the SwiftUI views.
enum MacrosCardChrome {
    static let cornerRadius: CGFloat = 16
    static let ringSize: CGFloat = 60
    static let ringLineWidth: CGFloat = 5
    static let trackColor = Color(hex: "#E5E7EB")
    
    /// Consumed / target, clamped to 0...1. A zero or negative target is an empty ring.
    static func clampedProgress(consumed: Double, target: Double) -> CGFloat {
        guard target > 0.0 else { return 0.0 }
        let ratio = consumed / target
        let notBelowZero = max(ratio, 0.0)
        let notAboveOne = min(notBelowZero, 1.0)
        return CGFloat(notAboveOne)
    }
    
    /// "58 / 180g" or "0 / 2,300mg" using the locale thousands separator.
    static func valueText(amount: Int, target: Int, unit: String) -> String {
        let consumed = amount.formatted()
        let goal = target.formatted()
        return "\(consumed) / \(goal)\(unit)"
    }
}

/// White rounded Macros card: bold title + one row of four progress rings.
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
        VStack(alignment: .leading, spacing: 16) {
            titleRow
            rings
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
    
    private var rings: some View {
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
        RoundedRectangle(cornerRadius: MacrosCardChrome.cornerRadius, style: .continuous)
            .fill(Color.white)
            .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 3)
    }
}

/// Four circular macro rings in a single row. Call-site inputs are unchanged.
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
        HStack(alignment: .top, spacing: 6) {
            proteinRing
            carbsRing
            fatRing
            sodiumRing
        }
        .frame(maxWidth: .infinity)
    }
    
    private var proteinRing: some View {
        MacroCard(
            name: "Protein",
            consumed: protein,
            target: proteinTarget,
            unit: "g",
            color: Color.orange,
            icon: "flame.fill"
        )
    }
    
    private var carbsRing: some View {
        MacroCard(
            name: "Carbs",
            consumed: carbs,
            target: carbsTarget,
            unit: "g",
            color: Color.blue,
            icon: "bolt.fill"
        )
    }
    
    private var fatRing: some View {
        MacroCard(
            name: "Fat",
            consumed: fat,
            target: fatTarget,
            unit: "g",
            color: Color.yellow,
            icon: "drop.fill"
        )
    }
    
    private var sodiumRing: some View {
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

/// One thin circular progress ring, icon at the top, "58 / 180g" under the ring.
struct MacroCard: View {
    let name: String
    let consumed: Double
    let target: Double
    let unit: String
    let color: Color
    let icon: String
    
    var body: some View {
        VStack(spacing: 8) {
            ringStack
            valueLabel
        }
        .frame(maxWidth: .infinity)
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
    
    private var valueString: String {
        MacrosCardChrome.valueText(amount: amountInt, target: targetInt, unit: unit)
    }
    
    private var accessibilityText: String {
        "\(name), \(amountInt) of \(targetInt) \(unit)"
    }
    
    private var ringStack: some View {
        ZStack(alignment: .top) {
            MacroRingView(progress: ringProgress, color: color)
            ringIcon
        }
        .frame(width: MacrosCardChrome.ringSize, height: MacrosCardChrome.ringSize)
    }
    
    private var ringIcon: some View {
        Image(systemName: icon)
            .font(.system(size: 13, weight: .semibold))
            .foregroundColor(color)
            .symbolRenderingMode(.monochrome)
            .offset(y: 7)
            .accessibilityHidden(true)
    }
    
    private var valueLabel: some View {
        Text(valueString)
            .font(.system(size: 11, weight: .semibold, design: .rounded))
            .foregroundColor(EmberColors.cream)
            .lineLimit(1)
            .minimumScaleFactor(0.55)
            .monospacedDigit()
            .multilineTextAlignment(.center)
    }
}

/// Light-gray track + colored progress arc with rounded caps.
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
            .stroke(MacrosCardChrome.trackColor, lineWidth: MacrosCardChrome.ringLineWidth)
    }
    
    private var progressArc: some View {
        Circle()
            .trim(from: trimStart, to: progress)
            .stroke(color, style: progressStroke)
            .rotationEffect(startAngle)
    }
    
    private var trimStart: CGFloat { 0 }
    
    private var startAngle: Angle { Angle(degrees: -90) }
    
    private var progressStroke: StrokeStyle {
        StrokeStyle(lineWidth: MacrosCardChrome.ringLineWidth, lineCap: CGLineCap.round)
    }
}
