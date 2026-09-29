import SwiftUI
import Charts

/// Builds a week-based X-axis for the weight projection chart.
/// Tick dates stay in-domain (from today through the projected goal date) and
/// are thinned on long spans so labels stay readable.
enum WeightProjectionWeekAxis {
    static let daysPerWeek = 7.0
    /// Average days per calendar month; keeps the 4 lb/month rate aligned to weeks.
    static let daysPerMonth = 30.4375
    
    static func date(byAddingWeeks weeks: Double, to date: Date, calendar: Calendar = .current) -> Date {
        let days = Int((weeks * daysPerWeek).rounded())
        return calendar.date(byAdding: .day, value: days, to: date) ?? date
    }
    
    /// Weeks between consecutive labeled ticks. Targets about 4–6 readable labels.
    /// Short spans are weekly; longer spans step by 2 or 4 weeks (or a 4-week multiple).
    static func stride(forWeeksToGoal weeksToGoal: Double) -> Int {
        let span = max(1, Int(ceil(weeksToGoal)))
        let targetGaps = 4
        let raw = max(1, Int((Double(span) / Double(targetGaps)).rounded()))
        if raw <= 1 { return 1 }
        if raw <= 2 { return 2 }
        if raw <= 6 { return 4 }
        return ((raw + 3) / 4) * 4
    }
    
    static func tickDates(from start: Date, weeksToGoal: Double, calendar: Calendar = .current) -> [Date] {
        let safeWeeks = max(weeksToGoal, 1.0 / daysPerWeek)
        let goal = date(byAddingWeeks: safeWeeks, to: start, calendar: calendar)
        let step = stride(forWeeksToGoal: safeWeeks)
        var dates: [Date] = [start]
        var offset = step
        // Keep the last interior tick far enough from the goal so labels do not collide.
        let lastOpenOffset = safeWeeks - Double(step) * 0.55
        while Double(offset) < lastOpenOffset {
            dates.append(date(byAddingWeeks: Double(offset), to: start, calendar: calendar))
            offset += step
        }
        if shouldAppendGoal(goal, after: dates.last ?? start, calendar: calendar) {
            dates.append(goal)
        }
        return dates
    }
    
    /// Week index from the start date: Wk 1, Wk 2, …
    static func label(for date: Date, start: Date, calendar: Calendar = .current) -> String {
        let startDay = calendar.startOfDay(for: start)
        let tickDay = calendar.startOfDay(for: date)
        let days = calendar.dateComponents([.day], from: startDay, to: tickDay).day ?? 0
        let weeks = Double(max(0, days)) / daysPerWeek
        let weekNumber = max(1, Int(weeks.rounded()) + 1)
        return "Wk \(weekNumber)"
    }
    
    private static func shouldAppendGoal(_ goal: Date, after last: Date, calendar: Calendar) -> Bool {
        !calendar.isDate(last, equalTo: goal, toGranularity: .weekOfYear)
    }
}

struct WeightProjectionChart: View {
    let startingWeightLb: Double
    let goalWeightLb: Double
    let currentWeightLb: Double?
    let unit: WeightUnit
    /// Optional override (e.g. a live edit preview). When nil, uses WeightManager pace/date.
    var weeklyPaceLb: Double? = nil
    
    @EnvironmentObject var weightManager: WeightManager
    
    private var lbsPerWeek: Double {
        if let weeklyPaceLb {
            return max(0.05, weeklyPaceLb)
        }
        return weightManager.resolvedWeeklyPaceLb(
            startingWeightLb: startingWeightLb,
            goalWeightLb: goalWeightLb
        )
    }
    
    private struct DataPoint: Identifiable {
        let id = UUID()
        let date: Date
        let weightLb: Double
        let isCurrent: Bool
    }
    
    private var startDate: Date {
        Calendar.current.startOfDay(for: Date())
    }
    
    private var weeksToGoal: Double {
        abs(goalWeightLb - startingWeightLb) / lbsPerWeek
    }
    
    private var weeksToGoalCaption: String {
        let weeks = max(1, Int(weeksToGoal.rounded()))
        return weeks == 1 ? "1 week to goal" : "\(weeks) weeks to goal"
    }
    
    private var projectionRateCaption: String {
        String(format: "Projection (%.1f lb/wk)", lbsPerWeek)
    }
    
    private var goalDate: Date {
        let projected = WeightProjectionWeekAxis.date(byAddingWeeks: weeksToGoal, to: startDate)
        if projected <= startDate {
            return Calendar.current.date(byAdding: .day, value: 1, to: startDate) ?? startDate.addingTimeInterval(86_400)
        }
        return projected
    }
    
    private var xAxisTickDates: [Date] {
        WeightProjectionWeekAxis.tickDates(from: startDate, weeksToGoal: weeksToGoal)
    }
    
    private var projectionPoints: [DataPoint] {
        [
            DataPoint(date: startDate, weightLb: startingWeightLb, isCurrent: false),
            DataPoint(date: goalDate, weightLb: goalWeightLb, isCurrent: false)
        ]
    }
    
    private var currentWeightPoint: DataPoint? {
        guard let current = currentWeightLb else { return nil }
        
        let weightDifference = goalWeightLb - startingWeightLb
        
        if abs(weightDifference) < 0.1 { return nil }
        
        let isGaining = weightDifference > 0
        let currentProgress = isGaining ? (current - startingWeightLb) : (startingWeightLb - current)
        let progressRatio = currentProgress / abs(weightDifference)
        let currentWeek = progressRatio * weeksToGoal
        let currentDate = WeightProjectionWeekAxis.date(byAddingWeeks: max(0, currentWeek), to: startDate)
        
        return DataPoint(date: currentDate, weightLb: current, isCurrent: true)
    }
    
    private var weightRange: ClosedRange<Double> {
        let minWeight = min(startingWeightLb, goalWeightLb)
        let maxWeight = max(startingWeightLb, goalWeightLb)
        let padding = (maxWeight - minWeight) * 0.15
        
        let paddedMin = max(0, minWeight - padding)
        let paddedMax = maxWeight + padding
        
        return paddedMin...paddedMax
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Weight Projection")
                    .font(.headline)
                    .foregroundColor(EmberColors.cream)
                
                Spacer()
                
                Text(weeksToGoalCaption)
                    .font(.caption)
                    .foregroundColor(EmberColors.muted)
            }
            
            Chart {
                ForEach(projectionPoints) { point in
                    LineMark(
                        x: .value("Week", point.date),
                        y: .value("Weight", unit.fromPounds(point.weightLb))
                    )
                    .foregroundStyle(EmberColors.ember)
                    .lineStyle(StrokeStyle(lineWidth: 3))
                }
                
                ForEach(projectionPoints) { point in
                    PointMark(
                        x: .value("Week", point.date),
                        y: .value("Weight", unit.fromPounds(point.weightLb))
                    )
                    .foregroundStyle(EmberColors.ember)
                    .symbolSize(80)
                }
                
                if let current = currentWeightPoint {
                    PointMark(
                        x: .value("Week", current.date),
                        y: .value("Weight", unit.fromPounds(current.weightLb))
                    )
                    .foregroundStyle(EmberColors.gold)
                    .symbolSize(100)
                    .symbol {
                        Circle()
                            .fill(EmberColors.gold)
                            .overlay(
                                Circle()
                                    .strokeBorder(EmberColors.dusk, lineWidth: 2)
                            )
                    }
                }
            }
            .frame(height: 200)
            .chartXScale(domain: startDate...goalDate)
            .chartXAxis {
                AxisMarks(values: xAxisTickDates) { value in
                    AxisValueLabel {
                        if let date = value.as(Date.self) {
                            Text(WeightProjectionWeekAxis.label(for: date, start: startDate))
                                .font(.caption2)
                                .foregroundColor(EmberColors.muted)
                        }
                    }
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                        .foregroundStyle(EmberColors.muted.opacity(0.2))
                    AxisTick(stroke: StrokeStyle(lineWidth: 1))
                        .foregroundStyle(EmberColors.muted.opacity(0.35))
                }
            }
            .chartYAxis {
                AxisMarks(values: .automatic(desiredCount: 5)) { value in
                    AxisValueLabel {
                        if let weight = value.as(Double.self) {
                            Text("\(Int(weight.rounded())) \(unit.label)")
                                .font(.caption2)
                                .foregroundColor(EmberColors.muted)
                        }
                    }
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                        .foregroundStyle(EmberColors.muted.opacity(0.2))
                }
            }
            .chartYScale(domain: unit.fromPounds(weightRange.lowerBound)...unit.fromPounds(weightRange.upperBound))
            
            HStack(spacing: 16) {
                HStack(spacing: 4) {
                    Circle()
                        .fill(EmberColors.ember)
                        .frame(width: 8, height: 8)
                    Text(projectionRateCaption)
                        .font(.caption2)
                        .foregroundColor(EmberColors.muted)
                }
                
                if currentWeightLb != nil {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(EmberColors.gold)
                            .frame(width: 8, height: 8)
                        Text("Current")
                            .font(.caption2)
                            .foregroundColor(EmberColors.muted)
                    }
                }
            }
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 16).fill(EmberColors.lightPlum))
    }
}

/// Compact Home weight trend: peach card, orange line + dots, mock-style callout.
struct HomeWeightTrendChart: View {
    let entries: [WeighIn]
    let startingWeightLb: Double?
    let currentWeightLb: Double?
    let unit: WeightUnit
    var callout: String = "Consistency builds results."

    private enum Palette {
        static let peach = Color(hex: "#FFF1E8")
        static let ink = Color(hex: "#8A5A42")
    }

    private struct TrendPoint: Identifiable {
        let id: String
        let date: Date
        let weightLb: Double
    }

    private var points: [TrendPoint] {
        if entries.count >= 2 {
            return entries
                .sorted { $0.date < $1.date }
                .map { TrendPoint(id: $0.id.uuidString, date: $0.date, weightLb: $0.weightLb) }
        }

        var result: [TrendPoint] = []
        if let start = startingWeightLb {
            let startDate = entries.min(by: { $0.date < $1.date })?.date
                ?? Date().addingTimeInterval(-86_400)
            result.append(TrendPoint(id: "starting", date: startDate, weightLb: start))
        }
        if let current = currentWeightLb {
            result.append(TrendPoint(id: "current", date: Date(), weightLb: current))
        } else if let only = entries.first {
            result.append(TrendPoint(id: only.id.uuidString, date: only.date, weightLb: only.weightLb))
        }
        return result
    }

    private var weightRange: ClosedRange<Double> {
        let values = points.map(\.weightLb)
        guard let minV = values.min(), let maxV = values.max() else {
            return 0...1
        }
        let span = max(maxV - minV, 1)
        let pad = span * 0.28
        return (minV - pad)...(maxV + pad)
    }

    var body: some View {
        VStack(alignment: .trailing, spacing: 8) {
            if points.isEmpty {
                Text(callout)
                    .font(.subheadline)
                    .foregroundColor(Palette.ink.opacity(0.75))
                    .frame(maxWidth: .infinity, minHeight: 92)
                    .multilineTextAlignment(.center)
            } else {
                Chart {
                    ForEach(points) { point in
                        LineMark(
                            x: .value("Date", point.date),
                            y: .value("Weight", unit.fromPounds(point.weightLb))
                        )
                        .interpolationMethod(.catmullRom)
                        .foregroundStyle(EmberColors.ember)
                        .lineStyle(StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))
                    }

                    ForEach(points) { point in
                        PointMark(
                            x: .value("Date", point.date),
                            y: .value("Weight", unit.fromPounds(point.weightLb))
                        )
                        .foregroundStyle(EmberColors.ember)
                        .symbolSize(64)
                    }
                }
                .frame(height: 108)
                .chartXAxis(.hidden)
                .chartYAxis(.hidden)
                .chartLegend(.hidden)
                .chartYScale(domain: unit.fromPounds(weightRange.lowerBound)...unit.fromPounds(weightRange.upperBound))

                Text(callout)
                    .font(.caption)
                    .foregroundColor(Palette.ink.opacity(0.72))
                    .multilineTextAlignment(.trailing)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Palette.peach)
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(points.isEmpty ? "Weight trend. \(callout)" : "Weight trend chart. \(callout)")
    }
}
