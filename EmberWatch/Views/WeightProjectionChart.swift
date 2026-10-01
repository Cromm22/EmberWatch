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

/// File-level so stroke constants are not pulled into the SwiftUI View type-checker.
private enum WeightChartStyle {
    static let projectedDash: [CGFloat] = [6, 4]
    static let projectedStroke = StrokeStyle(lineWidth: 2.5, lineCap: .round, dash: projectedDash)
    static let actualStroke = StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round)
    static let gridStroke = StrokeStyle(lineWidth: 0.5)
    static let tickStroke = StrokeStyle(lineWidth: 1)
    static let chartHeight: CGFloat = 180
    static let pointSize: CGFloat = 64
    static let projectedSeries = "Projected"
    static let actualSeries = "Actual"
}

struct WeightProjectionChart: View {
    let startingWeightLb: Double?
    let currentWeightLb: Double?
    let history: [WeighIn]
    let unit: WeightUnit
    
    private struct DataPoint: Identifiable {
        let series: String
        let date: Date
        let displayWeight: Double
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
        let startWeight: Double = WeightThirtyDayWindow.projectedWeightLb(
            on: windowStart,
            start: windowStart,
            baselineLb: baseline
        )
        let endWeight: Double = WeightThirtyDayWindow.projectedWeightLb(
            on: windowEnd,
            start: windowStart,
            baselineLb: baseline
        )
        return [
            makePoint(series: WeightChartStyle.projectedSeries, date: windowStart, weightLb: startWeight),
            makePoint(series: WeightChartStyle.projectedSeries, date: windowEnd, weightLb: endWeight)
        ]
    }
    
    private var actualPoints: [DataPoint] {
        actualEntries.map { entry in
            makePoint(
                series: WeightChartStyle.actualSeries,
                date: calendar.startOfDay(for: entry.date),
                weightLb: entry.weightLb
            )
        }
    }
    
    private var xAxisTickDates: [Date] {
        WeightThirtyDayWindow.tickDates(from: windowStart)
    }
    
    private var xDomain: ClosedRange<Date> {
        windowStart...windowEnd
    }
    
    private var yDomain: ClosedRange<Double> {
        let range: ClosedRange<Double> = weightRangeLb
        let lower: Double = unit.fromPounds(range.lowerBound)
        let upper: Double = unit.fromPounds(range.upperBound)
        return lower...upper
    }
    
    private var windowCaption: String {
        let loss: Double = unit.fromPounds(WeightThirtyDayWindow.lossLb)
        return "−\(WeightManager.format(loss)) \(unit.label) / 30 days"
    }
    
    private var emptyHint: String {
        if baselineWeightLb == nil {
            return "Add a starting or current weight to see the 30-day projection."
        }
        return "Log a weigh-in to compare actual vs projected."
    }
    
    private var weightRangeLb: ClosedRange<Double> {
        var pounds: [Double] = []
        if let baseline = baselineWeightLb {
            pounds.append(baseline)
            pounds.append(baseline - WeightThirtyDayWindow.lossLb)
        }
        pounds.append(contentsOf: actualEntries.map(\.weightLb))
        guard let minV: Double = pounds.min(), let maxV: Double = pounds.max() else {
            return 0...1
        }
        let span: Double = max(maxV - minV, WeightThirtyDayWindow.lossLb)
        let pad: Double = span * 0.15
        let lower: Double = max(0 as Double, minV - pad)
        let upper: Double = maxV + pad
        return lower...upper
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            headerRow
            weightChart
            legendRow
            emptyHintRow
        }
        .padding()
        .background(cardBackground)
    }
    
    private var headerRow: some View {
        HStack {
            Text("Weight Projection")
                .font(.headline)
                .foregroundColor(EmberColors.cream)
            Spacer()
            Text(windowCaption)
                .font(.caption)
                .foregroundColor(EmberColors.muted)
        }
    }
    
    private var weightChart: some View {
        scaledChart
            .chartXAxis { xAxisMarks }
            .chartYAxis { yAxisMarks }
            .accessibilityLabel(accessibilitySummary)
    }
    
    private var scaledChart: some View {
        Chart { allMarks }
            .frame(height: WeightChartStyle.chartHeight)
            .chartLegend(.hidden)
            .chartXScale(domain: xDomain)
            .chartYScale(domain: yDomain)
    }
    
    @ChartContentBuilder
    private var allMarks: some ChartContent {
        ForEach(projectionPoints) { point in
            projectedLine(point)
        }
        ForEach(actualPoints) { point in
            actualLine(point)
        }
        ForEach(actualPoints) { point in
            actualPoint(point)
        }
    }
    
    @ChartContentBuilder
    private func projectedLine(_ point: DataPoint) -> some ChartContent {
        LineMark(
            x: .value("Day", point.date),
            y: .value("Weight", point.displayWeight),
            series: .value("Series", point.series)
        )
        .foregroundStyle(EmberColors.ember)
        .lineStyle(WeightChartStyle.projectedStroke)
    }
    
    @ChartContentBuilder
    private func actualLine(_ point: DataPoint) -> some ChartContent {
        LineMark(
            x: .value("Day", point.date),
            y: .value("Weight", point.displayWeight),
            series: .value("Series", point.series)
        )
        .interpolationMethod(.linear)
        .foregroundStyle(EmberColors.gold)
        .lineStyle(WeightChartStyle.actualStroke)
    }
    
    @ChartContentBuilder
    private func actualPoint(_ point: DataPoint) -> some ChartContent {
        PointMark(
            x: .value("Day", point.date),
            y: .value("Weight", point.displayWeight),
            series: .value("Series", point.series)
        )
        .foregroundStyle(EmberColors.gold)
        .symbolSize(WeightChartStyle.pointSize)
    }
    
    private var gridLineColor: Color { EmberColors.muted.opacity(0.2) }
    private var tickColor: Color { EmberColors.muted.opacity(0.35) }
    
    private var xAxisMarks: some AxisContent {
        AxisMarks(values: xAxisTickDates) { value in
            AxisValueLabel {
                xTickText(value)
            }
            AxisGridLine(stroke: WeightChartStyle.gridStroke)
                .foregroundStyle(gridLineColor)
            AxisTick(stroke: WeightChartStyle.tickStroke)
                .foregroundStyle(tickColor)
        }
    }
    
    @ViewBuilder
    private func xTickText(_ value: AxisValue) -> some View {
        if let date = value.as(Date.self) {
            Text(WeightThirtyDayWindow.label(for: date, start: windowStart))
                .font(.caption2)
                .foregroundColor(EmberColors.muted)
        }
    }
    
    private var yAxisMarks: some AxisContent {
        AxisMarks(values: .automatic(desiredCount: 5)) { value in
            AxisValueLabel {
                yTickText(value)
            }
            AxisGridLine(stroke: WeightChartStyle.gridStroke)
                .foregroundStyle(gridLineColor)
        }
    }
    
    @ViewBuilder
    private func yTickText(_ value: AxisValue) -> some View {
        if let weight = value.as(Double.self) {
            Text(formattedYLabel(weight))
                .font(.caption2)
                .foregroundColor(EmberColors.muted)
        }
    }
    
    private func formattedYLabel(_ weight: Double) -> String {
        "\(WeightManager.format(weight)) \(unit.label)"
    }
    
    private var legendRow: some View {
        HStack(spacing: 16) {
            legendSwatch(color: EmberColors.ember, title: WeightChartStyle.projectedSeries)
            legendSwatch(color: EmberColors.gold, title: WeightChartStyle.actualSeries)
        }
    }
    
    @ViewBuilder
    private var emptyHintRow: some View {
        if actualPoints.isEmpty {
            Text(emptyHint)
                .font(.caption)
                .foregroundColor(EmberColors.muted)
        }
    }
    
    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 16).fill(EmberColors.lightPlum)
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
    
    private func makePoint(series: String, date: Date, weightLb: Double) -> DataPoint {
        DataPoint(
            series: series,
            date: date,
            displayWeight: unit.fromPounds(weightLb)
        )
    }
    
    private var accessibilitySummary: String {
        let loss: Double = unit.fromPounds(WeightThirtyDayWindow.lossLb)
        let pace: String = "Projected loss of \(WeightManager.format(loss)) \(unit.label) over 30 days"
        if actualPoints.isEmpty {
            return "\(pace). \(emptyHint)"
        }
        return "\(pace). \(actualPoints.count) actual weigh-ins in this window."
    }
}
