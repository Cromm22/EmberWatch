import SwiftUI
import Charts

/// Rolling 30-day window for the Home weight graph.
/// Anchored to the first weigh-in of the current cycle, or today when there is none.
/// File-level so these helpers are not MainActor-isolated with SwiftUI views.
enum WeightThirtyDayWindow {
    static let dayCount = 30
    /// Target loss across one window, always stored in pounds.
    static let lossLb = 4.0
    /// Day numbers shown on the X-axis (1-based, inclusive of Day 30).
    static let labeledDayNumbers = [1, 5, 10, 15, 20, 25, 30]
    
    static func windowStart(
        history: [WeighIn],
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> Date {
        let today = calendar.startOfDay(for: now)
        guard let oldest = history.map(\.date).min() else { return today }
        let firstDay = calendar.startOfDay(for: oldest)
        if firstDay > today { return today }
        let elapsed = calendar.dateComponents([.day], from: firstDay, to: today).day ?? 0
        let cycleOffset = (max(0, elapsed) / dayCount) * dayCount
        return calendar.date(byAdding: .day, value: cycleOffset, to: firstDay) ?? today
    }
    
    static func windowEnd(from start: Date, calendar: Calendar = .current) -> Date {
        let startDay = calendar.startOfDay(for: start)
        return calendar.date(byAdding: .day, value: dayCount - 1, to: startDay) ?? startDay
    }
    
    /// Exclusive end of the window (`start + 30 days` at start-of-day).
    static func windowEndExclusive(from start: Date, calendar: Calendar = .current) -> Date {
        let startDay = calendar.startOfDay(for: start)
        return calendar.date(byAdding: .day, value: dayCount, to: startDay) ?? startDay
    }
    
    static func tickDates(from start: Date, calendar: Calendar = .current) -> [Date] {
        let startDay = calendar.startOfDay(for: start)
        return labeledDayNumbers.compactMap { dayNumber in
            calendar.date(byAdding: .day, value: dayNumber - 1, to: startDay)
        }
    }
    
    static func dayNumber(for date: Date, start: Date, calendar: Calendar = .current) -> Int {
        let startDay = calendar.startOfDay(for: start)
        let day = calendar.startOfDay(for: date)
        let days = calendar.dateComponents([.day], from: startDay, to: day).day ?? 0
        return days + 1
    }
    
    static func label(for date: Date, start: Date, calendar: Calendar = .current) -> String {
        "Day \(dayNumber(for: date, start: start, calendar: calendar))"
    }
    
    /// Latest weigh-in per calendar day inside `[start, endExclusive)`.
    static func actualWeighIns(
        from history: [WeighIn],
        start: Date,
        endExclusive: Date,
        calendar: Calendar = .current
    ) -> [WeighIn] {
        let startDay = calendar.startOfDay(for: start)
        let endDay = calendar.startOfDay(for: endExclusive)
        var latestByDay: [Date: WeighIn] = [:]
        for entry in history {
            let day = calendar.startOfDay(for: entry.date)
            guard day >= startDay && day < endDay else { continue }
            if let existing = latestByDay[day] {
                if entry.date >= existing.date {
                    latestByDay[day] = entry
                }
            } else {
                latestByDay[day] = entry
            }
        }
        return latestByDay.values.sorted { $0.date < $1.date }
    }
    
    /// Frozen start-of-window weight so the 4 lb line does not jump on later logs.
    static func baselineWeightLb(
        actuals: [WeighIn],
        windowStart: Date,
        startingWeightLb: Double?,
        currentWeightLb: Double?,
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> Double? {
        let startDay = calendar.startOfDay(for: windowStart)
        if let onStartDay = actuals.first(where: { calendar.isDate($0.date, inSameDayAs: startDay) }) {
            return onStartDay.weightLb
        }
        if calendar.isDate(startDay, inSameDayAs: calendar.startOfDay(for: now)) {
            return currentWeightLb ?? startingWeightLb ?? actuals.first?.weightLb
        }
        return startingWeightLb ?? currentWeightLb ?? actuals.first?.weightLb
    }
    
    static func projectedWeightLb(
        on date: Date,
        start: Date,
        baselineLb: Double,
        calendar: Calendar = .current
    ) -> Double {
        let startDay = calendar.startOfDay(for: start)
        let day = calendar.startOfDay(for: date)
        let elapsed = calendar.dateComponents([.day], from: startDay, to: day).day ?? 0
        let span = Double(max(1, dayCount - 1))
        let progress = min(1, max(0, Double(elapsed) / span))
        return baselineLb - lossLb * progress
    }
}

struct WeightProjectionChart: View {
    let startingWeightLb: Double?
    let currentWeightLb: Double?
    let history: [WeighIn]
    let unit: WeightUnit
    
    private struct DataPoint: Identifiable {
        let series: String
        let date: Date
        let weightLb: Double
        var id: String { "\(series)-\(date.timeIntervalSince1970)" }
    }
    
    private var calendar: Calendar { Calendar.current }
    
    private var windowStart: Date {
        WeightThirtyDayWindow.windowStart(history: history)
    }
    
    private var windowEnd: Date {
        WeightThirtyDayWindow.windowEnd(from: windowStart)
    }
    
    private var windowEndExclusive: Date {
        WeightThirtyDayWindow.windowEndExclusive(from: windowStart)
    }
    
    private var actualEntries: [WeighIn] {
        WeightThirtyDayWindow.actualWeighIns(
            from: history,
            start: windowStart,
            endExclusive: windowEndExclusive
        )
    }
    
    private var baselineWeightLb: Double? {
        WeightThirtyDayWindow.baselineWeightLb(
            actuals: actualEntries,
            windowStart: windowStart,
            startingWeightLb: startingWeightLb,
            currentWeightLb: currentWeightLb
        )
    }
    
    private var projectionPoints: [DataPoint] {
        guard let baseline = baselineWeightLb else { return [] }
        return [
            DataPoint(
                series: "projected",
                date: windowStart,
                weightLb: WeightThirtyDayWindow.projectedWeightLb(
                    on: windowStart,
                    start: windowStart,
                    baselineLb: baseline
                )
            ),
            DataPoint(
                series: "projected",
                date: windowEnd,
                weightLb: WeightThirtyDayWindow.projectedWeightLb(
                    on: windowEnd,
                    start: windowStart,
                    baselineLb: baseline
                )
            )
        ]
    }
    
    private var actualPoints: [DataPoint] {
        actualEntries.map { entry in
            DataPoint(
                series: "actual",
                date: calendar.startOfDay(for: entry.date),
                weightLb: entry.weightLb
            )
        }
    }
    
    private var xAxisTickDates: [Date] {
        WeightThirtyDayWindow.tickDates(from: windowStart)
    }
    
    private var windowCaption: String {
        let loss = unit.fromPounds(WeightThirtyDayWindow.lossLb)
        return "−\(WeightManager.format(loss)) \(unit.label) / 30 days"
    }
    
    private var emptyHint: String {
        if baselineWeightLb == nil {
            return "Add a starting or current weight to see the 30-day projection."
        }
        return "Log a weigh-in to compare actual vs projected."
    }
    
    private var weightRange: ClosedRange<Double> {
        var values = projectionPoints.map(\.weightLb)
        values.append(contentsOf: actualPoints.map(\.weightLb))
        guard let minV = values.min(), let maxV = values.max() else {
            return 0...1
        }
        let span = max(maxV - minV, WeightThirtyDayWindow.lossLb)
        let pad = span * 0.15
        return max(0, minV - pad)...(maxV + pad)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Weight Projection")
                    .font(.headline)
                    .foregroundColor(EmberColors.cream)
                
                Spacer()
                
                Text(windowCaption)
                    .font(.caption)
                    .foregroundColor(EmberColors.muted)
            }
            
            Chart {
                ForEach(projectionPoints) { point in
                    LineMark(
                        x: .value("Day", point.date),
                        y: .value("Weight", unit.fromPounds(point.weightLb)),
                        series: .value("Series", "Projected")
                    )
                    .foregroundStyle(EmberColors.ember)
                    .lineStyle(StrokeStyle(lineWidth: 2.5, dash: [6, 4], lineCap: .round))
                }
                
                ForEach(actualPoints) { point in
                    LineMark(
                        x: .value("Day", point.date),
                        y: .value("Weight", unit.fromPounds(point.weightLb)),
                        series: .value("Series", "Actual")
                    )
                    .interpolationMethod(.linear)
                    .foregroundStyle(EmberColors.gold)
                    .lineStyle(StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))
                }
                
                ForEach(actualPoints) { point in
                    PointMark(
                        x: .value("Day", point.date),
                        y: .value("Weight", unit.fromPounds(point.weightLb)),
                        series: .value("Series", "Actual")
                    )
                    .foregroundStyle(EmberColors.gold)
                    .symbolSize(64)
                }
            }
            .frame(height: 180)
            .chartLegend(.hidden)
            .chartXScale(domain: windowStart...windowEnd)
            .chartXAxis {
                AxisMarks(values: xAxisTickDates) { value in
                    AxisValueLabel {
                        if let date = value.as(Date.self) {
                            Text(WeightThirtyDayWindow.label(for: date, start: windowStart))
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
                            Text("\(WeightManager.format(weight)) \(unit.label)")
                                .font(.caption2)
                                .foregroundColor(EmberColors.muted)
                        }
                    }
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                        .foregroundStyle(EmberColors.muted.opacity(0.2))
                }
            }
            .chartYScale(domain: unit.fromPounds(weightRange.lowerBound)...unit.fromPounds(weightRange.upperBound))
            .accessibilityLabel(accessibilitySummary)
            
            HStack(spacing: 16) {
                legendSwatch(color: EmberColors.ember, title: "Projected")
                legendSwatch(color: EmberColors.gold, title: "Actual")
            }
            
            if actualPoints.isEmpty {
                Text(emptyHint)
                    .font(.caption)
                    .foregroundColor(EmberColors.muted)
            }
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 16).fill(EmberColors.lightPlum))
    }
    
    private func legendSwatch(color: Color, title: String) -> some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(title)
                .font(.caption2)
                .foregroundColor(EmberColors.muted)
        }
    }
    
    private var accessibilitySummary: String {
        let loss = unit.fromPounds(WeightThirtyDayWindow.lossLb)
        let pace = "Projected loss of \(WeightManager.format(loss)) \(unit.label) over 30 days"
        if actualPoints.isEmpty {
            return "\(pace). \(emptyHint)"
        }
        return "\(pace). \(actualPoints.count) actual weigh-ins in this window."
    }
}

