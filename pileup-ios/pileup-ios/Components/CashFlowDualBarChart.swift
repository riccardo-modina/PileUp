import SwiftUI

struct CashFlowBarItem: Identifiable {
    let id: String
    let label: String
    let income: Double
    let expense: Double
    let isSelected: Bool
    let isFutureOrEmpty: Bool
    var monthNumber: Int? = nil
    var year: Int? = nil
}

/// Dual-column bar chart for CashFlow In & Out matching the Origin iOS design.
/// Supports 4 months window in Month mode, 4 years window in Year mode,
/// and 1 centered dual column in Total mode.
struct CashFlowDualBarChart: View {
    @Environment(\.colorScheme) private var colorScheme
    @ObservedObject var viewModel: DashboardViewModel
    
    // Geometry constants
    private let chartHeight: CGFloat = 160
    
    private var isTotalMode: Bool {
        viewModel.selectedPeriod.isTotal
    }
    
    private var currentBarWidth: CGFloat {
        isTotalMode ? 28 : 18
    }
    
    private var currentBarGap: CGFloat {
        isTotalMode ? 6 : 4
    }
    
    private let monthSymbols = ["Gen", "Feb", "Mar", "Apr", "Mag", "Giu", "Lug", "Ago", "Set", "Ott", "Nov", "Dic"]
    
    /// Prepares bar items based on selected period:
    /// - Month mode: 4 visible months (2 past, selected, 1 next/placeholder)
    /// - Year mode: 4 visible years (2 past, selected, 1 next/placeholder)
    /// - Total mode: 1 single column with total expenses and total income
    private var barItems: [CashFlowBarItem] {
        switch viewModel.selectedPeriod {
        case .monthYear(let selM, let selY):
            var monthsToDisplay: [(m: Int, y: Int)] = []
            let startOffset = -2
            
            for offset in 0..<4 {
                let relOffset = startOffset + offset
                var targetM = selM + relOffset
                var targetY = selY
                
                while targetM < 1 {
                    targetM += 12
                    targetY -= 1
                }
                while targetM > 12 {
                    targetM -= 12
                    targetY += 1
                }
                monthsToDisplay.append((targetM, targetY))
            }
            
            return monthsToDisplay.map { (m, y) in
                let monthSymbol = monthSymbols[max(0, min(m - 1, 11))]
                let monthStr2Digits = String(format: "%02d", m)
                let monthStr1Digit = "\(m)"
                
                let incomeList = viewModel.yearlyMovements[y]?.income ?? viewModel.incomeMovements
                let expenseList = viewModel.yearlyMovements[y]?.spending ?? viewModel.expenseMovements
                
                var inc = incomeList.first(where: {
                    $0.month.caseInsensitiveCompare(monthSymbol) == .orderedSame || $0.month == monthStr2Digits || $0.month == monthStr1Digit
                })?.amount ?? 0.0
                
                var exp = expenseList.first(where: {
                    $0.month.caseInsensitiveCompare(monthSymbol) == .orderedSame || $0.month == monthStr2Digits || $0.month == monthStr1Digit
                })?.amount ?? 0.0
                
                // If it's the currently selected month and movements are empty, fallback to monthly totals
                if m == selM && y == selY {
                    if inc == 0 && viewModel.monthlyIncome > 0 {
                        inc = viewModel.monthlyIncome
                    }
                    if exp == 0 && viewModel.monthlyExpense > 0 {
                        exp = viewModel.monthlyExpense
                    }
                }
                
                let isSel = (m == selM && y == selY)
                let hasData = (inc > 0 || exp > 0)
                let isEmpty = !hasData
                let label = "1 \(monthSymbol)"
                
                return CashFlowBarItem(
                    id: "\(y)-\(m)",
                    label: label,
                    income: inc,
                    expense: exp,
                    isSelected: isSel,
                    isFutureOrEmpty: isEmpty,
                    monthNumber: m,
                    year: y
                )
            }
            
        case .year(let selY):
            var yearsToDisplay: [Int] = []
            let startOffset = -2
            
            for offset in 0..<4 {
                let targetY = selY + startOffset + offset
                yearsToDisplay.append(targetY)
            }
            
            return yearsToDisplay.map { y in
                let isSel = (y == selY)
                
                var inc: Double = 0.0
                var exp: Double = 0.0
                
                if let totals = viewModel.yearlyTotals[y] {
                    inc = totals.income
                    exp = totals.expense
                }
                
                if y == selY {
                    if inc == 0 && viewModel.monthlyIncome > 0 {
                        inc = viewModel.monthlyIncome
                    }
                    if exp == 0 && viewModel.monthlyExpense > 0 {
                        exp = viewModel.monthlyExpense
                    }
                }
                
                let hasData = (inc > 0 || exp > 0)
                let isEmpty = !hasData
                let label = "\(y)"
                
                return CashFlowBarItem(
                    id: "year-\(y)",
                    label: label,
                    income: inc,
                    expense: exp,
                    isSelected: isSel,
                    isFutureOrEmpty: isEmpty,
                    monthNumber: nil,
                    year: y
                )
            }
            
        case .total:
            let inc = viewModel.monthlyIncome
            let exp = viewModel.monthlyExpense
            let isEmpty = (inc <= 0 && exp <= 0)
            
            return [
                CashFlowBarItem(
                    id: "total",
                    label: "Totale",
                    income: inc,
                    expense: exp,
                    isSelected: true,
                    isFutureOrEmpty: isEmpty,
                    monthNumber: nil,
                    year: nil
                )
            ]
        }
    }
    
    private var maxAmount: Double {
        let maxVal = barItems.map { max($0.income, $0.expense) }.max() ?? 1000
        return max(maxVal, 1000)
    }
    
    private func formatCompactCurrency(_ value: Double) -> String {
        if value >= 1000 {
            let k = value / 1000.0
            if k.truncatingRemainder(dividingBy: 1) == 0 {
                return String(format: "%.0fk", k)
            } else {
                return String(format: "%.1fk", k)
            }
        }
        return "\(Int(value))"
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Chart Canvas + Y Axis (Upper guides and Bars)
            ZStack(alignment: .bottomLeading) {
                // Background Guide Lines & Upper Y-Axis Labels
                VStack(spacing: 0) {
                    guideLineRow(label: formatCompactCurrency(maxAmount))
                    Spacer()
                    guideLineRow(label: formatCompactCurrency(maxAmount / 2))
                    Spacer()
                }
                .frame(height: chartHeight)
                
                // Bars Layer (sitting cleanly at the bottom edge)
                HStack(alignment: .bottom, spacing: 0) {
                    ForEach(barItems) { item in
                        VStack(spacing: 0) {
                            Spacer()
                            
                            HStack(alignment: .bottom, spacing: currentBarGap) {
                                // Money In Bar
                                barColumn(
                                    amount: item.income,
                                    maxAmount: maxAmount,
                                    color: AppTheme.Colors.moneyIn,
                                    isSelected: item.isSelected,
                                    isEmpty: item.isFutureOrEmpty
                                )
                                
                                // Money Out Bar
                                barColumn(
                                    amount: item.expense,
                                    maxAmount: maxAmount,
                                    color: AppTheme.Colors.moneyOut,
                                    isSelected: item.isSelected,
                                    isEmpty: item.isFutureOrEmpty
                                )
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            if !item.isFutureOrEmpty || canSelect(item) {
                                selectItem(item)
                            }
                        }
                    }
                    
                    // Reserve space matching Y-axis label column
                    Spacer()
                        .frame(width: 44)
                }
                .frame(height: chartHeight)
            }
            .frame(height: chartHeight)
            .padding(.horizontal, 16)
            
            // Base Guide Line at quota 0 (sitting directly underneath the bars, flush with their bottom)
            HStack(alignment: .center, spacing: 8) {
                Rectangle()
                    .fill(AppTheme.Colors.dynamicBorder.opacity(0.8))
                    .frame(height: 1)
                
                Text("0")
                    .font(.system(size: 11, weight: .regular))
                    .foregroundColor(AppTheme.Colors.dynamicSubtext)
                    .frame(width: 36, alignment: .trailing)
            }
            .frame(height: 1)
            .padding(.horizontal, 16)
            
            // X-Axis Labels (directly under baseline)
            HStack(spacing: 0) {
                ForEach(barItems) { item in
                    Button(action: {
                        if !item.isFutureOrEmpty || canSelect(item) {
                            selectItem(item)
                        }
                    }) {
                        Text(item.label)
                            .font(.system(size: 12, weight: item.isSelected ? .semibold : .medium))
                            .foregroundColor(item.isSelected ? AppTheme.Colors.dynamicText : AppTheme.Colors.dynamicSubtext.opacity(item.isFutureOrEmpty ? 0.45 : 0.8))
                            .padding(.horizontal, 9)
                            .padding(.vertical, 4)
                            .background(
                                Group {
                                    if item.isSelected {
                                        Capsule()
                                            .stroke(AppTheme.Colors.dynamicText.opacity(0.85), lineWidth: 1)
                                    }
                                }
                            )
                    }
                    .buttonStyle(.plain)
                    .frame(maxWidth: .infinity)
                }
                
                // Reserve space for Y-axis alignment
                Spacer()
                    .frame(width: 44)
            }
            .padding(.horizontal, 16)
            .padding(.top, 10)
        }
        .contentShape(Rectangle())
    }
    
    @ViewBuilder
    private func barColumn(amount: Double, maxAmount: Double, color: Color, isSelected: Bool, isEmpty: Bool) -> some View {
        let safeMax = maxAmount > 0 ? maxAmount : 1.0
        let isZero = amount <= 0 || isEmpty
        
        // Low placeholder height (8pt) with subtle opacity for empty/future periods
        let minPlaceholderHeight: CGFloat = 8
        let ratio = CGFloat(min(max(amount / safeMax, 0.0), 1.0))
        let calculatedHeight = isZero ? minPlaceholderHeight : max(chartHeight * ratio, minPlaceholderHeight)
        
        // Color: soft light grey/subtle tint if empty, or vibrant theme color
        let fillColor = isZero ? AppTheme.Colors.dynamicSubtext.opacity(0.18) : color
        let isDark = colorScheme == .dark
        
        // In Dark mode: avoid murky darkening caused by 0.72 blending into dark background.
        // Instead, use clear frosted transparency (0.42) with a crisp luminous stroke so it looks transparent, not dark.
        let barOpacity: Double = isSelected ? 1.0 : (isZero ? 0.35 : (isDark ? 0.42 : 0.72))
        
        TopRoundedRectangle(radius: 3)
            .fill(fillColor)
            .opacity(barOpacity)
            .frame(width: currentBarWidth, height: calculatedHeight)
            .overlay(
                Group {
                    if isDark && !isSelected && !isZero {
                        TopRoundedRectangle(radius: 3)
                            .stroke(color.opacity(0.65), lineWidth: 1)
                    }
                }
            )
            .animation(.spring(response: 0.35, dampingFraction: 0.8), value: calculatedHeight)
    }
    
    @ViewBuilder
    private func guideLineRow(label: String) -> some View {
        HStack(spacing: 8) {
            Line()
                .stroke(
                    AppTheme.Colors.dynamicBorder.opacity(0.6),
                    style: StrokeStyle(lineWidth: 0.8, dash: [4, 4])
                )
                .frame(height: 1)
            
            Text(label)
                .font(.system(size: 11, weight: .regular))
                .foregroundColor(AppTheme.Colors.dynamicSubtext)
                .frame(width: 36, alignment: .trailing)
        }
    }
    
    private func canSelect(_ item: CashFlowBarItem) -> Bool {
        // If it has real data (income or expense), allow selection!
        if item.income > 0 || item.expense > 0 {
            return true
        }
        
        let calendar = Calendar.current
        let today = Date()
        let currentYear = calendar.component(.year, from: today)
        let currentMonth = calendar.component(.month, from: today)
        
        switch viewModel.selectedPeriod {
        case .monthYear:
            guard let y = item.year, let m = item.monthNumber else { return false }
            if y > currentYear { return false }
            if y == currentYear && m > currentMonth { return false }
            return true
        case .year:
            guard let y = item.year else { return false }
            return y <= currentYear
        case .total:
            return false
        }
    }
    
    private func selectItem(_ item: CashFlowBarItem) {
        guard canSelect(item) else { return }
        HapticHelper.light()
        withAnimation(.easeInOut(duration: 0.25)) {
            switch viewModel.selectedPeriod {
            case .monthYear:
                if let m = item.monthNumber, let y = item.year {
                    viewModel.selectedPeriod = .monthYear(month: m, year: y)
                }
            case .year:
                if let y = item.year {
                    viewModel.selectedPeriod = .year(y)
                }
            case .total:
                break
            }
        }
    }
}

/// Helper shape for drawing dotted horizontal guide lines
struct Line: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        return path
    }
}
