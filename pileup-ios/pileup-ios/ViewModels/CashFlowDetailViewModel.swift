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
            recalculateFilteredMovements()
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
    @Published var isLoadingBackground: Bool = false
    @Published var hasMore: Bool = false
    @Published var errorMessage: String? = nil
    
    // MARK: - Dependencies
    private let transactionAPI: TransactionAPIProtocol
    private let categoryAPI: CategoryAPIProtocol
    private var currentPage: Int = 1
    private var currentFetchTask: Task<Void, Never>?
    
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
        currentFetchTask?.cancel()
        
        currentFetchTask = Task { [weak self] in
            guard let self = self else { return }
            
            if reset {
                self.isLoading = true
                self.currentPage = 1
                self.errorMessage = nil
            }
            
            // Extract year and month params
            var yearParam: String? = nil
            var monthParam: String? = nil
            
            switch self.period {
            case .monthYear(let m, let y):
                yearParam = "\(y)"
                monthParam = "\(m)"
            case .year(let y):
                yearParam = "\(y)"
                monthParam = nil
            case .total:
                yearParam = "Totale"
                monthParam = nil
            }
            
            // 1. Load categories if not yet loaded
            if self.categories.isEmpty {
                do {
                    let allCats = try await self.categoryAPI.getAllCategories()
                    self.categories = allCats.filter { $0.tipo == self.movementType.rawValue }
                } catch {
                    print("Notice: could not prefetch categories: \(error)")
                }
            }
            
            // 2. Fetch movements
            do {
                let response = try await self.transactionAPI.getPaginatedMovements(
                    page: self.currentPage,
                    pageSize: "500",
                    year: yearParam,
                    month: monthParam,
                    tipo: self.movementType.rawValue,
                    categoria: nil
                )
                
                // Decrypt titles using masterKey
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
                self.calculatePieSlices()
                self.recalculateFilteredMovements()
                self.isLoading = false
            } catch {
                if !Task.isCancelled {
                    self.errorMessage = "Errore nel caricamento: \(error.localizedDescription)"
                    self.isLoading = false
                }
            }
        }
    }
    
    // MARK: - Calculations
    
    private func calculatePieSlices() {
        var categoryMap: [String: (id: Int?, name: String, amount: Double, color: Color, hex: String, count: Int)] = [:]
        var total: Double = 0.0
        
        for item in movements {
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
                    let index = abs(catKey.hashValue) % fallbackPalette.count
                    color = fallbackPalette[index]
                }
                categoryMap[catKey] = (id: catId, name: catName, amount: item.importo, color: color, hex: hex, count: 1)
            }
        }
        
        self.periodTotal = total
        
        // Build slices sorted by amount descending
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
        
        self.pieSlices = slices.sorted { $0.amount > $1.amount }
    }
    
    private func recalculateFilteredMovements() {
        var list = movements
        
        // Filter by Category
        if let catId = selectedCategoryId {
            list = list.filter { $0.categoria?.id == catId }
        }
        
        // Filter by Search text
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
            calculatePieSlices()
            recalculateFilteredMovements()
            
            HapticHelper.success()
            
            // Notify other screens to update
            NotificationCenter.default.post(name: NSNotification.Name("TransactionsUpdated"), object: nil)
        } catch {
            print("Failed to delete movement: \(error)")
            HapticHelper.error()
            self.errorMessage = "Impossibile eliminare: \(error.localizedDescription)"
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
