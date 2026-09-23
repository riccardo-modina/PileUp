import Foundation
import SwiftUI
import Combine

@MainActor
final class CashFlowDetailViewModel: ObservableObject {
    // MARK: - Inputs
    @Published var movementType: MovementType
    @Published var period: DataPeriod {
        didSet {
            onPeriodChanged?(period)
            loadData(reset: true)
        }
    }
    
    var onPeriodChanged: ((DataPeriod) -> Void)? = nil
    
    // MARK: - State
    @Published var movements: [MovementItem] = []
    @Published var categories: [CategoryItem] = []
    @Published var selectedCategoryId: Int? = nil {
        didSet {
            if oldValue != selectedCategoryId {
                loadMovements(reset: true)
            }
        }
    }
    @Published var searchText: String = "" {
        didSet {
            recalculateFilteredMovements()
        }
    }
    
    @Published var filteredMovements: [MovementItem] = []
    @Published var pieSlices: [CategoryPieSlice] = []
    @Published var periodTotal: Double = 0.0
    
    @Published var isLoading: Bool = false
    @Published var isLoadingMore: Bool = false
    @Published var hasMore: Bool = false
    @Published var errorMessage: String? = nil
    
    // MARK: - Dependencies
    private let transactionAPI: TransactionAPIProtocol
    private let categoryAPI: CategoryAPIProtocol
    private let pageSize: Int = 10
    private var currentPage: Int = 1
    private var currentMovementsTask: Task<Void, Never>?
    private var currentStatsTask: Task<Void, Never>?
    
    // Fallback curated palette for categories without hex colors
    private let fallbackPalette: [Color] = [
        Color(hex: "#3B82F6"), // Blue
        Color(hex: "#10B981"), // Emerald
        Color(hex: "#F59E0B"), // Amber
        Color(hex: "#8B5CF6"), // Purple
        Color(hex: "#EC4899"), // Pink
        Color(hex: "#14B8A6"), // Teal
        Color(hex: "#F97316"), // Orange
        Color(hex: "#6366F1"), // Indigo
        Color(hex: "#EF4444"), // Red
        Color(hex: "#84CC16")  // Lime
    ]
    
    init(
        movementType: MovementType = .expense,
        period: DataPeriod = .total,
        onPeriodChanged: ((DataPeriod) -> Void)? = nil,
        transactionAPI: TransactionAPIProtocol = TransactionAPI.shared,
        categoryAPI: CategoryAPIProtocol = CategoryAPI.shared
    ) {
        self.movementType = movementType
        self.period = period
        self.onPeriodChanged = onPeriodChanged
        self.transactionAPI = transactionAPI
        self.categoryAPI = categoryAPI
    }
    
    // MARK: - Title & Format Helpers
    
    var viewTitle: String {
        movementType == .income ? "Dettaglio Entrate" : "Dettaglio Uscite"
    }
    
    var themeColor: Color {
        movementType == .income ? AppTheme.Colors.moneyIn : AppTheme.Colors.moneyOut
    }
    
    var periodFormattedString: String {
        switch period {
        case .monthYear(let m, let y):
            let monthsShort = ["Gen", "Feb", "Mar", "Apr", "Mag", "Giu", "Lug", "Ago", "Set", "Ott", "Nov", "Dic"]
            let mName = monthsShort[max(0, min(m - 1, 11))]
            return "\(mName) \(y)"
        case .year(let y):
            return "\(y)"
        case .total:
            return "Tutto lo storico"
        }
    }
    
    var formattedPeriodTotal: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "€"
        formatter.locale = Locale(identifier: "it_IT")
        return formatter.string(from: NSNumber(value: periodTotal)) ?? String(format: "€ %.2f", periodTotal)
    }
    
    // MARK: - Data Fetching
    
    func loadData(reset: Bool = true) {
        let (yearParam, monthParam) = extractPeriodParams()
        
        fetchChartStats(yearParam: yearParam, monthParam: monthParam)
        loadMovements(reset: true)
    }
    
    private func extractPeriodParams() -> (year: String?, month: String?) {
        switch period {
        case .monthYear(let m, let y):
            return ("\(y)", "\(m)")
        case .year(let y):
            return ("\(y)", nil)
        case .total:
            return ("Totale", nil)
        }
    }
    
    // MARK: - Chart Stats (Full month distribution without crypto decryption)
    private func fetchChartStats(yearParam: String?, monthParam: String?) {
        currentStatsTask?.cancel()
        currentStatsTask = Task { [weak self] in
            guard let self = self else { return }
            do {
                let response = try await self.transactionAPI.getPaginatedMovements(
                    page: 1,
                    pageSize: "500",
                    year: yearParam,
                    month: monthParam,
                    tipo: self.movementType.rawValue,
                    categoria: nil
                )
                
                guard !Task.isCancelled else { return }
                
                var categoryMap: [String: (id: Int?, name: String, amount: Double, color: Color, hex: String, count: Int)] = [:]
                var total: Double = 0.0
                
                for item in response.results {
                    total += item.importo
                    let catKey = item.categoria != nil ? "\(item.categoria!.id)" : "unclassified"
                    let catName = item.categoria?.nome ?? "Senza Categoria"
                    let catId = item.categoria?.id
                    let hex = item.categoria?.color ?? ""
                    
                    if var existing = categoryMap[catKey] {
                        existing.amount += item.importo
                        existing.count += 1
                        categoryMap[catKey] = existing
                    } else {
                        let color: Color
                        if !hex.isEmpty {
                            color = Color(hex: hex)
                        } else {
                            let index = abs(catKey.hashValue) % self.fallbackPalette.count
                            color = self.fallbackPalette[index]
                        }
                        categoryMap[catKey] = (id: catId, name: catName, amount: item.importo, color: color, hex: hex, count: 1)
                    }
                }
                
                var slices: [CategoryPieSlice] = []
                for (key, val) in categoryMap {
                    let percentage = total > 0 ? (val.amount / total) : 0.0
                    slices.append(
                        CategoryPieSlice(
                            id: key,
                            categoryId: val.id,
                            name: val.name,
                            amount: val.amount,
                            percentage: percentage,
                            color: val.color,
                            hexColor: val.hex,
                            count: val.count
                        )
                    )
                }
                
                self.periodTotal = total
                self.pieSlices = slices.sorted { $0.amount > $1.amount }
            } catch {
                print("Notice: could not load chart stats: \(error)")
            }
        }
    }
    
    // MARK: - Movements Paginated Loading (10 items per page)
    func loadMovements(reset: Bool = false) {
        if reset {
            currentMovementsTask?.cancel()
            currentPage = 1
            hasMore = true
            isLoading = true
            movements = []
            filteredMovements = []
        } else {
            guard hasMore && !isLoading && !isLoadingMore else { return }
            isLoadingMore = true
        }
        
        let targetPage = currentPage
        let catFilter = selectedCategoryId
        let (yearParam, monthParam) = extractPeriodParams()
        
        currentMovementsTask = Task { [weak self] in
            guard let self = self else { return }
            
            do {
                let response = try await self.transactionAPI.getPaginatedMovements(
                    page: targetPage,
                    pageSize: "\(self.pageSize)",
                    year: yearParam,
                    month: monthParam,
                    tipo: self.movementType.rawValue,
                    categoria: catFilter
                )
                
                guard !Task.isCancelled else { return }
                
                let masterKey = KeychainManager.shared.getMasterKey()
                let decryptedList = response.results.map { item -> MovementItem in
                    var decryptedTitle = item.titolo
                    var decryptedDesc = item.descrizione
                    
                    if let key = masterKey, !key.isEmpty {
                        if let decT = CryptoHelper.decryptData(item.titolo, key: key) {
                            decryptedTitle = decT
                        }
                        if let desc = item.descrizione, let decD = CryptoHelper.decryptData(desc, key: key) {
                            decryptedDesc = decD
                        }
                    }
                    
                    return MovementItem(
                        id: item.id,
                        titolo: decryptedTitle,
                        importo: item.importo,
                        data: item.data,
                        tipo: item.tipo,
                        descrizione: decryptedDesc,
                        categoria: item.categoria,
                        conto: item.conto
                    )
                }
                
                if reset {
                    self.movements = decryptedList
                } else {
                    self.movements.append(contentsOf: decryptedList)
                }
                
                self.hasMore = response.next != nil
                self.recalculateFilteredMovements()
                self.isLoading = false
                self.isLoadingMore = false
            } catch {
                if !Task.isCancelled {
                    self.errorMessage = ErrorHandler.format(error)
                    self.isLoading = false
                    self.isLoadingMore = false
                }
            }
        }
    }
    
    func loadMoreMovements() {
        guard hasMore && !isLoading && !isLoadingMore else { return }
        currentPage += 1
        loadMovements(reset: false)
    }
    
    private func recalculateFilteredMovements() {
        var list = movements
        
        // Filter by Search text if present
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if !query.isEmpty {
            list = list.filter { item in
                item.titolo.lowercased().contains(query) ||
                (item.descrizione?.lowercased().contains(query) ?? false) ||
                item.categoryName.lowercased().contains(query) ||
                item.accountName.lowercased().contains(query)
            }
        }
        
        self.filteredMovements = list
    }
    
    // MARK: - Actions
    
    func deleteMovement(_ item: MovementItem) async {
        do {
            try await transactionAPI.deleteMovement(id: item.id)
            
            // Remove locally
            movements.removeAll { $0.id == item.id }
            recalculateFilteredMovements()
            periodTotal = max(0, periodTotal - item.importo)
            
            HapticHelper.success()
            
            let (yearParam, monthParam) = extractPeriodParams()
            fetchChartStats(yearParam: yearParam, monthParam: monthParam)
            
            // Notify other screens to update
            NotificationCenter.default.post(name: NSNotification.Name("TransactionsUpdated"), object: nil)
        } catch {
            print("Failed to delete movement: \(error)")
            HapticHelper.error()
            self.errorMessage = ErrorHandler.format(error)
        }
    }
    
    func selectCategoryFilter(_ id: Int?) {
        if selectedCategoryId == id {
            selectedCategoryId = nil
        } else {
            selectedCategoryId = id
        }
    }
    
    // MARK: - Period Controls
    
    func nextPeriod() {
        guard period.canMoveForward() else { return }
        period.adjust(by: 1)
    }
    
    func previousPeriod() {
        guard !period.isTotal else { return }
        period.adjust(by: -1)
    }
}
