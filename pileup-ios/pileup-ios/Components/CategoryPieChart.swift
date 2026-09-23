import SwiftUI

/// Interactive Donut/Pie Chart component for category distribution.
/// Matches naming convention of CashFlowDualBarChart.
struct CategoryPieChart: View {
    let slices: [CategoryPieSlice]
    let totalAmount: Double
    let title: String
    @Binding var selectedCategoryId: Int?
    
    private let chartDiameter: CGFloat = 250
    private let ringThickness: CGFloat = 36
    
    private var activeSlice: CategoryPieSlice? {
        guard let id = selectedCategoryId else { return nil }
        return slices.first(where: { $0.categoryId == id })
    }
    
    var body: some View {
        ZStack {
            // Tap area covering the entire region around and outside the donut to clear category filter
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture {
                    if selectedCategoryId != nil {
                        HapticHelper.light()
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedCategoryId = nil
                        }
                    }
                }
            
            if slices.isEmpty {
                emptyDonutPlaceholder
            } else {
                ZStack {
                    donutGraphic
                    centerOverlay
                }
                .frame(width: chartDiameter + 10, height: chartDiameter + 10)
            }
        }
        .frame(height: chartDiameter + 24)
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Donut Graphic
    
    private var donutGraphic: some View {
        GeometryReader { _ in
            ZStack {
                ForEach(sliceAngles, id: \.slice.id) { item in
                    let isSelected = selectedCategoryId != nil && selectedCategoryId == item.slice.categoryId
                    let sliceOpacity: Double = (selectedCategoryId == nil || isSelected) ? 1.0 : 0.3
                    let scaleValue: CGFloat = isSelected ? 1.04 : 1.0
                    
                    DonutSliceShape(
                        startAngle: item.startAngle,
                        endAngle: item.endAngle,
                        innerRadiusRatio: 0.70
                    )
                    .fill(item.slice.color)
                    .opacity(sliceOpacity)
                    .scaleEffect(scaleValue, anchor: .center)
                    .animation(.spring(response: 0.35, dampingFraction: 0.75), value: isSelected)
                    .contentShape(
                        DonutSliceShape(
                            startAngle: item.startAngle,
                            endAngle: item.endAngle,
                            innerRadiusRatio: 0.70
                        )
                    )
                    .onTapGesture {
                        HapticHelper.selection()
                        withAnimation(.easeInOut(duration: 0.2)) {
                            if selectedCategoryId == item.slice.categoryId {
                                selectedCategoryId = nil
                            } else {
                                selectedCategoryId = item.slice.categoryId
                            }
                        }
                    }
                }
            }
            .animation(.spring(response: 0.45, dampingFraction: 0.8), value: sliceAngles.map(\.slice.amount))
        }
    }
    
    // MARK: - Center Overlay
    
    private var centerOverlay: some View {
        VStack(spacing: 3) {
            if let slice = activeSlice {
                Text(slice.name.uppercased())
                    .font(.system(size: 11, weight: .bold))
                    .tracking(1.0)
                    .foregroundColor(AppTheme.Colors.dynamicSubtext)
                    .lineLimit(1)
                    .minimumScaleFactor(0.65)
                    .padding(.horizontal, 14)
                
                CurrencyAmountText(
                    formatCurrency(slice.amount),
                    size: 26,
                    weight: .regular,
                    design: .rounded,
                    color: AppTheme.Colors.dynamicText
                )
                .minimumScaleFactor(0.65)
                .lineLimit(1)
                .padding(.horizontal, 8)
                .contentTransition(.numericText())
                .animation(.easeInOut(duration: 0.25), value: slice.amount)
                
                Text(String(format: "%.1f%%", slice.percentage * 100))
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundColor(slice.color)
            } else {
                Text(title.uppercased())
                    .font(.system(size: 11, weight: .bold))
                    .tracking(1.2)
                    .foregroundColor(AppTheme.Colors.dynamicSubtext)
                    .padding(.horizontal, 14)
                
                CurrencyAmountText(
                    formatCurrency(totalAmount),
                    size: 28,
                    weight: .regular,
                    design: .rounded,
                    color: AppTheme.Colors.dynamicText
                )
                .minimumScaleFactor(0.65)
                .lineLimit(1)
                .padding(.horizontal, 8)
                .contentTransition(.numericText())
                .animation(.easeInOut(duration: 0.25), value: totalAmount)
            }
        }
        .frame(width: chartDiameter - ringThickness * 2 - 6, height: chartDiameter - ringThickness * 2 - 6)
        .contentShape(Circle())
        .onTapGesture {
            if selectedCategoryId != nil {
                HapticHelper.light()
                withAnimation(.easeInOut(duration: 0.2)) {
                    selectedCategoryId = nil
                }
            }
        }
    }
    
    // MARK: - Empty State Placeholder
    
    private var emptyDonutPlaceholder: some View {
        ZStack {
            Circle()
                .stroke(AppTheme.Colors.dynamicBorder.opacity(0.4), lineWidth: ringThickness)
                .frame(width: chartDiameter - ringThickness, height: chartDiameter - ringThickness)
            
            VStack(spacing: 4) {
                Text(title.uppercased())
                    .font(.system(size: 11, weight: .bold))
                    .tracking(1.2)
                    .foregroundColor(AppTheme.Colors.dynamicSubtext)
                
                CurrencyAmountText(
                    formatCurrency(0.0),
                    size: 28,
                    weight: .regular,
                    design: .rounded,
                    color: AppTheme.Colors.dynamicText
                )
            }
        }
    }
    
    // MARK: - Calculations
    
    private struct SliceAngleItem: Equatable {
        let slice: CategoryPieSlice
        let startAngle: Angle
        let endAngle: Angle
    }
    
    private var sliceAngles: [SliceAngleItem] {
        var items: [SliceAngleItem] = []
        var currentDegrees: Double = -90.0
        let gapDegrees: Double = slices.count > 1 ? 2.0 : 0.0
        let totalUsableDegrees = 360.0 - (Double(slices.count) * gapDegrees)
        
        for slice in slices {
            let sliceSpan = max(1.0, slice.percentage * totalUsableDegrees)
            let start = Angle(degrees: currentDegrees + (gapDegrees / 2))
            let end = Angle(degrees: currentDegrees + (gapDegrees / 2) + sliceSpan)
            items.append(SliceAngleItem(slice: slice, startAngle: start, endAngle: end))
            currentDegrees += sliceSpan + gapDegrees
        }
        return items
    }
    
    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "€"
        formatter.locale = Locale(identifier: "it_IT")
        return formatter.string(from: NSNumber(value: value)) ?? String(format: "€ %.2f", value)
    }
}

/// Shape representing a single donut arc segment
struct DonutSliceShape: Shape {
    var startAngle: Angle
    var endAngle: Angle
    var innerRadiusRatio: CGFloat = 0.70
    
    var animatableData: AnimatablePair<Double, Double> {
        get {
            AnimatablePair(startAngle.degrees, endAngle.degrees)
        }
        set {
            startAngle = Angle(degrees: newValue.first)
            endAngle = Angle(degrees: newValue.second)
        }
    }
    
    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let outerRadius = min(rect.width, rect.height) / 2
        let innerRadius = outerRadius * innerRadiusRatio
        
        var path = Path()
        path.addArc(
            center: center,
            radius: outerRadius,
            startAngle: startAngle,
            endAngle: endAngle,
            clockwise: false
        )
        path.addArc(
            center: center,
            radius: innerRadius,
            startAngle: endAngle,
            endAngle: startAngle,
            clockwise: true
        )
        path.closeSubpath()
        return path
    }
}
