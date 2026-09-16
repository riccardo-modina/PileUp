import SwiftUI

struct CashFlowBarItem: Identifiable {
    let id: String
    let monthNumber: Int
    let year: Int
    let label: String
    let income: Double
    let expense: Double
    let isSelected: Bool
    let isFutureOrEmpty: Bool
}

/// Dual-column bar chart for CashFlow In & Out matching the Origin iOS design.
/// Features flat base on quota 0, top-rounded bars, subtle guide lines,
/// visible previous months history, low placeholder bars for empty/future months,
/// active month pill outline, tap selection, and horizontal swipe navigation.
struct CashFlowDualBarChart: View {
    @ObservedObject var viewModel: DashboardViewModel
    
    // Geometry constants
    private let chartHeight: CGFloat = 160
    private let barWidth: CGFloat = 18
    private let barGap: CGFloat = 4
    
    private let monthSymbols = ["Gen", "Feb", "Mar", "Apr", "Mag", "Giu", "Lug", "Ago", "Set", "Ott", "Nov", "Dic"]
    
    private var selectedMonthAndYear: (month: Int, year: Int) {
        switch viewModel.selectedPeriod {
        case .monthYear(let m, let y):
            return (m, y)
        case .year(let y):
            return (Calendar.current.component(.month, from: Date()), y)
        case .total:
            return (Calendar.current.component(.month, from: Date()), Calendar.current.component(.year, from: Date()))
        }
    }
    
    /// Prepares 4 months window around the active month
    private var barItems: [CashFlowBarItem] {
        let calendar = Calendar.current
        let today = Date()
        let currentYear = calendar.component(.year, from: today)
        let currentMonth = calendar.component(.month, from: today)
        
        let (selM, selY) = selectedMonthAndYear
        
        // Window of 4 months
        var monthsToDisplay: [(m: Int, y: Int)] = []
        
        // Window of 4 months: 2 past months, selected month, and month n+1 (gray placeholder if future)
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
            
            let isFuture = (y > currentYear) || (y == currentYear && m > currentMonth)
            
            // Extract from yearlyMovements cache or incomeMovements
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
            let isEmpty = isFuture || (inc <= 0 && exp <= 0)
            let label = "1 \(monthSymbol)"
            
            return CashFlowBarItem(
                id: "\(y)-\(m)",
                monthNumber: m,
                year: y,
                label: label,
                income: isFuture ? 0 : inc,
                expense: isFuture ? 0 : exp,
                isSelected: isSel,
                isFutureOrEmpty: isEmpty
            )
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
                            
                            HStack(alignment: .bottom, spacing: barGap) {
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
                                selectMonth(item)
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
                            selectMonth(item)
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
        
        // Low placeholder height (8pt) with subtle opacity for empty/future months
        let minPlaceholderHeight: CGFloat = 8
        let ratio = CGFloat(min(max(amount / safeMax, 0.0), 1.0))
        let calculatedHeight = isZero ? minPlaceholderHeight : max(chartHeight * ratio, minPlaceholderHeight)
        
        // Color: soft light grey/subtle tint if empty, or vibrant theme color
        let fillColor = isZero ? AppTheme.Colors.dynamicSubtext.opacity(0.18) : color
        let barOpacity: Double = isSelected ? 1.0 : (isZero ? 0.5 : 0.72)
        
        TopRoundedRectangle(radius: 3)
            .fill(fillColor)
            .opacity(barOpacity)
            .frame(width: barWidth, height: calculatedHeight)
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
        let calendar = Calendar.current
        let today = Date()
        let currentYear = calendar.component(.year, from: today)
        let currentMonth = calendar.component(.month, from: today)
        
        if item.year > currentYear { return false }
        if item.year == currentYear && item.monthNumber > currentMonth { return false }
        return true
    }
    
    private func selectMonth(_ item: CashFlowBarItem) {
        guard canSelect(item) else { return }
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
        withAnimation(.easeInOut(duration: 0.25)) {
            viewModel.selectedPeriod = .monthYear(month: item.monthNumber, year: item.year)
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
