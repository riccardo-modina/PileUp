import Foundation
import Combine

enum DataPeriod: Equatable {
    case monthYear(month: Int, year: Int)
    case year(Int)
    case total
    
    var description: String {
        switch self {
        case .monthYear(let month, let year):
            return String(format: "%02d/%d", month, year)
        case .year(let year):
            return "\(year)"
        case .total:
            return "Totale"
        }
    }
    
    var isTotal: Bool {
        if case .total = self { return true }
        return false
    }
    
    func canMoveForward() -> Bool {
        let calendar = Calendar.current
        let today = Date()
        let currentYear = calendar.component(.year, from: today)
        let currentMonth = calendar.component(.month, from: today)
        
        switch self {
        case .monthYear(let month, let year):
            if year > currentYear { return false }
            if year == currentYear && month >= currentMonth { return false }
            return true
        case .year(let year):
            return year < currentYear
        case .total:
            return false
        }
    }
    
    mutating func adjust(by offset: Int) {
        let calendar = Calendar.current
        let today = Date()
        let currentYear = calendar.component(.year, from: today)
        let currentMonth = calendar.component(.month, from: today)
        
        switch self {
        case .monthYear(let month, let year):
            var newMonth = month + offset
            var newYear = year
            
            while newMonth > 12 {
                newMonth -= 12
                newYear += 1
            }
            while newMonth < 1 {
                newMonth += 12
                newYear -= 1
            }
            
            // Prevent future dates
            if newYear > currentYear || (newYear == currentYear && newMonth > currentMonth) {
                return
            }
            
            self = .monthYear(month: newMonth, year: newYear)
            
        case .year(let year):
            let newYear = year + offset
            if newYear > currentYear {
                return
            }
            self = .year(newYear)
            
        case .total:
            break
        }
    }
}

class DashboardViewModel: ObservableObject {
    @Published var monthlyIncome: Double = 0.0
    @Published var monthlyExpense: Double = 0.0
    @Published var incomeMovements: [MonthlyStat] = []
    @Published var expenseMovements: [MonthlyStat] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    
    @Published var selectedPeriod: DataPeriod = {
        let calendar = Calendar.current
        let today = Date()
        return .monthYear(
            month: calendar.component(.month, from: today),
            year: calendar.component(.year, from: today)
        )
    }() {
        didSet {
            // Immediately sync figures for the newly selected month from existing movements
            syncCurrentMonthFiguresFromMovements()
            // Automatically fetch fresh stats from server when period changes
            if oldValue != selectedPeriod {
                fetchMonthlyStats()
            }
        }
    }
    
    private let monthSymbols = ["Gen", "Feb", "Mar", "Apr", "Mag", "Giu", "Lug", "Ago", "Set", "Ott", "Nov", "Dic"]
    
    // Cache per contenere i movimenti mensili per ciascun anno richiesto
    @Published var yearlyMovements: [Int: (income: [MonthlyStat], spending: [MonthlyStat])] = [:]
    
    init() {
        fetchMonthlyStats()
    }
    
    private func syncCurrentMonthFiguresFromMovements() {
        guard case .monthYear(let m, let y) = selectedPeriod else { return }
        let currentSymbol = monthSymbols[max(0, min(m - 1, 11))]
        let m2 = String(format: "%02d", m)
        let m1 = "\(m)"
        
        let incomeList = yearlyMovements[y]?.income ?? incomeMovements
        let expenseList = yearlyMovements[y]?.spending ?? expenseMovements
        
        if let incStat = incomeList.first(where: { $0.month.caseInsensitiveCompare(currentSymbol) == .orderedSame || $0.month == m2 || $0.month == m1 }) {
            self.monthlyIncome = incStat.amount
        }
        if let expStat = expenseList.first(where: { $0.month.caseInsensitiveCompare(currentSymbol) == .orderedSame || $0.month == m2 || $0.month == m1 }) {
            self.monthlyExpense = expStat.amount
        }
    }
    
    /// Computes the 4 visible months around the selected month
    func visibleMonths(for month: Int, year: Int) -> [(month: Int, year: Int)] {
        let startOffset = -2
        
        var list: [(month: Int, year: Int)] = []
        for offset in 0..<4 {
            let relOffset = startOffset + offset
            var targetM = month + relOffset
            var targetY = year
            while targetM < 1 {
                targetM += 12
                targetY -= 1
            }
            while targetM > 12 {
                targetM -= 12
                targetY += 1
            }
            list.append((month: targetM, year: targetY))
        }
        return list
    }
    
    func fetchVisibleMonths(year: Int, months: [String]) {
        let endpoint = "stats/monthly/?year=\(year)&months=\(months.joined(separator: ","))"
        Task { @MainActor in
            do {
                let response: MonthlyStatsResponse = try await NetworkManager.shared.request(endpoint: endpoint, method: "GET")
                var existing = self.yearlyMovements[year] ?? (income: [], spending: [])
                for inc in response.income {
                    if let idx = existing.income.firstIndex(where: { $0.month == inc.month }) {
                        existing.income[idx] = inc
                    } else {
                        existing.income.append(inc)
                    }
                }
                for exp in response.spending {
                    if let idx = existing.spending.firstIndex(where: { $0.month == exp.month }) {
                        existing.spending[idx] = exp
                    } else {
                        existing.spending.append(exp)
                    }
                }
                self.yearlyMovements[year] = existing
            } catch {
                print("Failed to fetch visible months for year \(year): \(error)")
            }
        }
    }
    
    func fetchMonthlyStats() {
        isLoading = true
        errorMessage = nil
        
        let endpoint = "stats/monthly/"
        var queryItems: [URLQueryItem] = []
        let selectedYear: Int
        
        switch selectedPeriod {
        case .monthYear(let month, let year):
            selectedYear = year
            queryItems.append(URLQueryItem(name: "year", value: "\(year)"))
            
            // Query only the 4 visible months (no unnecessary 12-month calculation)
            let visible = visibleMonths(for: month, year: year)
            let currentYearMonths = visible.filter { $0.year == year }.map { "\($0.month)" }
            if !currentYearMonths.isEmpty {
                queryItems.append(URLQueryItem(name: "months", value: currentYearMonths.joined(separator: ",")))
            }
            
            // If visible months span across the previous year boundary, fetch only those specific visible months
            let prevYearMonths = visible.filter { $0.year == year - 1 }.map { "\($0.month)" }
            if !prevYearMonths.isEmpty {
                fetchVisibleMonths(year: year - 1, months: prevYearMonths)
            }
        case .year(let year):
            selectedYear = year
            queryItems.append(URLQueryItem(name: "year", value: "\(year)"))
        case .total:
            selectedYear = Calendar.current.component(.year, from: Date())
            queryItems.append(URLQueryItem(name: "year", value: "Totale"))
        }
        
        var urlComponents = URLComponents(string: endpoint)
        urlComponents?.queryItems = queryItems
        let finalEndpoint = urlComponents?.url?.absoluteString ?? endpoint
        
        Task { @MainActor in
            do {
                let response: MonthlyStatsResponse = try await NetworkManager.shared.request(endpoint: finalEndpoint, method: "GET")
                self.isLoading = false
                
                var existing = self.yearlyMovements[selectedYear] ?? (income: [], spending: [])
                for inc in response.income {
                    if let idx = existing.income.firstIndex(where: { $0.month == inc.month }) {
                        existing.income[idx] = inc
                    } else {
                        existing.income.append(inc)
                    }
                }
                for exp in response.spending {
                    if let idx = existing.spending.firstIndex(where: { $0.month == exp.month }) {
                        existing.spending[idx] = exp
                    } else {
                        existing.spending.append(exp)
                    }
                }
                self.yearlyMovements[selectedYear] = existing
                self.incomeMovements = existing.income
                self.expenseMovements = existing.spending
                
                if case .monthYear(let m, _) = self.selectedPeriod {
                    let currentSymbol = self.monthSymbols[max(0, min(m - 1, 11))]
                    let m2 = String(format: "%02d", m)
                    let m1 = "\(m)"
                    
                    self.monthlyIncome = response.income.first(where: {
                        $0.month.caseInsensitiveCompare(currentSymbol) == .orderedSame || $0.month == m2 || $0.month == m1
                    })?.amount ?? 0.0
                    
                    self.monthlyExpense = response.spending.first(where: {
                        $0.month.caseInsensitiveCompare(currentSymbol) == .orderedSame || $0.month == m2 || $0.month == m1
                    })?.amount ?? 0.0
                } else {
                    self.monthlyIncome = response.monthlyIncome
                    self.monthlyExpense = response.monthlyExpense
                }
            } catch {
                self.isLoading = false
                self.errorMessage = "Error fetching stats: \(error.localizedDescription)"
            }
        }
    }
    
    func nextPeriod() {
        if selectedPeriod.canMoveForward() {
            selectedPeriod.adjust(by: 1)
        }
    }
    
    func previousPeriod() {
        if !selectedPeriod.isTotal {
            selectedPeriod.adjust(by: -1)
        }
    }
}
