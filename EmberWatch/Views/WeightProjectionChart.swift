import SwiftUI
import Charts

struct WeightProjectionChart: View {
    let startingWeightLb: Double
    let goalWeightLb: Double
    let currentWeightLb: Double?
    let unit: WeightUnit
    
    private let lbsPerMonth: Double = 4.0
    
    private struct DataPoint: Identifiable {
        let id = UUID()
        let monthsFromNow: Double
        let weightLb: Double
        let isCurrent: Bool
    }
    
    private var projectionPoints: [DataPoint] {
        var points: [DataPoint] = []
        
        let weightDifference = goalWeightLb - startingWeightLb
        let isGaining = weightDifference > 0
        let monthsToGoal = abs(weightDifference) / lbsPerMonth
        
        // Starting point
        points.append(DataPoint(monthsFromNow: 0, weightLb: startingWeightLb, isCurrent: false))
        
        // Goal point
        points.append(DataPoint(monthsFromNow: monthsToGoal, weightLb: goalWeightLb, isCurrent: false))
        
        return points
    }
    
    private var currentWeightPoint: DataPoint? {
        guard let current = currentWeightLb else { return nil }
        
        let weightDifference = goalWeightLb - startingWeightLb
        
        if abs(weightDifference) < 0.1 { return nil }
        
        let isGaining = weightDifference > 0
        let currentProgress = isGaining ? (current - startingWeightLb) : (startingWeightLb - current)
        let progressRatio = currentProgress / abs(weightDifference)
        let totalMonths = abs(weightDifference) / lbsPerMonth
        let currentMonth = progressRatio * totalMonths
        
        return DataPoint(monthsFromNow: max(0, currentMonth), weightLb: current, isCurrent: true)
    }
    
    private var allPoints: [DataPoint] {
        var points = projectionPoints
        if let current = currentWeightPoint {
            points.append(current)
        }
        return points.sorted { $0.monthsFromNow < $1.monthsFromNow }
    }
    
    private var monthsToGoal: Double {
        abs(goalWeightLb - startingWeightLb) / lbsPerMonth
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
                
                Text("\(Int(monthsToGoal.rounded())) months to goal")
                    .font(.caption)
                    .foregroundColor(EmberColors.muted)
            }
            
            Chart {
                ForEach(projectionPoints) { point in
                    LineMark(
                        x: .value("Month", point.monthsFromNow),
                        y: .value("Weight", unit.fromPounds(point.weightLb))
                    )
                    .foregroundStyle(EmberColors.ember)
                    .lineStyle(StrokeStyle(lineWidth: 3))
                }
                
                ForEach(projectionPoints) { point in
                    PointMark(
                        x: .value("Month", point.monthsFromNow),
                        y: .value("Weight", unit.fromPounds(point.weightLb))
                    )
                    .foregroundStyle(EmberColors.ember)
                    .symbolSize(80)
                }
                
                if let current = currentWeightPoint {
                    PointMark(
                        x: .value("Month", current.monthsFromNow),
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
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: 5)) { value in
                    AxisValueLabel {
                        if let months = value.as(Double.self) {
                            Text(months == 0 ? "Now" : "\(Int(months))m")
                                .font(.caption2)
                                .foregroundColor(EmberColors.muted)
                        }
                    }
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                        .foregroundStyle(EmberColors.muted.opacity(0.2))
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
                    Text("Projection (4 lb/mo)")
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
