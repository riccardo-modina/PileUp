import Foundation
import SwiftUI

/// Movement types supported by the application.
enum MovementType: String, CaseIterable, Identifiable, Codable {
    case expense = "uscita"
    case income = "entrata"
    case transfer = "giroconto"
    
    var id: String { rawValue }
    
    var title: String {
        switch self {
        case .expense: return "Spesa"
        case .income: return "Entrata"
        case .transfer: return "Giroconto"
        }
    }
    
    var iconName: String {
        switch self {
        case .expense: return "arrow.up.right"
        case .income: return "arrow.down.left"
        case .transfer: return "arrow.triangle.2.circlepath"
        }
    }
    
    var accentColor: Color {
        switch self {
        case .expense: return AppTheme.Colors.negative
        case .income: return AppTheme.Colors.moneyIn
        case .transfer: return AppTheme.Colors.moneyOut
        }
    }
    
    var backgroundColor: Color {
        accentColor.opacity(0.12)
    }
}

/// Category model used in transaction forms.
nonisolated struct CategoryItem: Identifiable, Codable, Hashable, Sendable {
    let id: Int
    let nome: String
    let tipo: String
    let color: String?
    let is_system: Bool?
    
    @MainActor
    var displayColor: Color {
        if let hex = color, !hex.isEmpty {
            return Color(hex: hex)
        }
        return AppTheme.Colors.primary
    }
    
    var isSystem: Bool {
        is_system ?? false || nome.lowercased().contains("riassociare")
    }
}

/// Account model used in transaction forms.
nonisolated struct AccountItem: Identifiable, Codable, Hashable, Sendable {
    let id: Int
    let nome: String
    let tipo: String?
    let valuta: String?
    let color: String?
    let is_system: Bool?
    
    @MainActor
    var displayColor: Color {
        if let hex = color, !hex.isEmpty {
            return Color(hex: hex)
        }
        return AppTheme.Colors.moneyOut
    }
    
    var isSystem: Bool {
        is_system ?? false || nome.lowercased().contains("riassociare")
    }
}

/// Payload sent to POST /movimenti/.
nonisolated struct MovementPayload: Codable, Sendable {
    let titolo: String
    let importo: Double
    let data: String // YYYY-MM-DD
    let categoria: Int
    let conto: Int
    let descrizione: String?
}

/// Response returned when creating or updating a movement.
nonisolated struct MovementResponse: Codable, Sendable {
    let id: Int?
    let titolo: String?
    let importo: Double?
    let data: String?
    let categoria: Int?
    let conto: Int?
    let tipo: String?
    let descrizione: String?
    
    enum CodingKeys: String, CodingKey {
        case id, titolo, importo, data, categoria, conto, tipo, descrizione
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try? container.decodeIfPresent(Int.self, forKey: .id)
        self.titolo = try? container.decodeIfPresent(String.self, forKey: .titolo)
        self.data = try? container.decodeIfPresent(String.self, forKey: .data)
        self.tipo = try? container.decodeIfPresent(String.self, forKey: .tipo)
        self.descrizione = try? container.decodeIfPresent(String.self, forKey: .descrizione)
        
        // Flexible decoding for categoria: could be Int or CategoryItem object
        if let catId = try? container.decodeIfPresent(Int.self, forKey: .categoria) {
            self.categoria = catId
        } else if let catObj = try? container.decodeIfPresent(CategoryItem.self, forKey: .categoria) {
            self.categoria = catObj.id
        } else {
            self.categoria = nil
        }
        
        // Flexible decoding for conto: could be Int or AccountItem object
        if let accId = try? container.decodeIfPresent(Int.self, forKey: .conto) {
            self.conto = accId
        } else if let accObj = try? container.decodeIfPresent(AccountItem.self, forKey: .conto) {
            self.conto = accObj.id
        } else {
            self.conto = nil
        }
        
        if let doubleVal = try? container.decodeIfPresent(Double.self, forKey: .importo) {
            self.importo = doubleVal
        } else if let stringVal = try? container.decodeIfPresent(String.self, forKey: .importo) {
            self.importo = Double(stringVal)
        } else {
            self.importo = nil
        }
    }
}

/// Detailed movement model returned by GET /movimenti/ with nested category and account.
nonisolated struct MovementItem: Identifiable, Codable, Sendable {
    let id: Int
    let titolo: String
    let importo: Double
    let data: String
    let tipo: String
    let descrizione: String?
    let categoria: CategoryItem?
    let conto: AccountItem?
    
    enum CodingKeys: String, CodingKey {
        case id, titolo, importo, data, tipo, descrizione, categoria, conto
    }
    
    init(
        id: Int,
        titolo: String,
        importo: Double,
        data: String,
        tipo: String,
        descrizione: String? = nil,
        categoria: CategoryItem? = nil,
        conto: AccountItem? = nil
    ) {
        self.id = id
        self.titolo = titolo
        self.importo = importo
        self.data = data
        self.tipo = tipo
        self.descrizione = descrizione
        self.categoria = categoria
        self.conto = conto
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(Int.self, forKey: .id)
        self.titolo = (try? container.decode(String.self, forKey: .titolo)) ?? ""
        self.data = (try? container.decode(String.self, forKey: .data)) ?? ""
        self.tipo = (try? container.decode(String.self, forKey: .tipo)) ?? "uscita"
        self.descrizione = try? container.decodeIfPresent(String.self, forKey: .descrizione)
        
        // Handle amount as number or string
        if let doubleVal = try? container.decodeIfPresent(Double.self, forKey: .importo) {
            self.importo = doubleVal
        } else if let stringVal = try? container.decodeIfPresent(String.self, forKey: .importo) {
            self.importo = Double(stringVal) ?? 0.0
        } else {
            self.importo = 0.0
        }
        
        // Flexible decoding for categoria
        if let catObj = try? container.decodeIfPresent(CategoryItem.self, forKey: .categoria) {
            self.categoria = catObj
        } else {
            self.categoria = nil
        }
        
        // Flexible decoding for conto
        if let accObj = try? container.decodeIfPresent(AccountItem.self, forKey: .conto) {
            self.conto = accObj
        } else {
            self.conto = nil
        }
    }
    
    var categoryName: String {
        categoria?.nome ?? "Senza Categoria"
    }
    
    var categoryColorHex: String {
        categoria?.color ?? "#9E9E9E"
    }
    
    @MainActor
    var categoryDisplayColor: Color {
        if let colorHex = categoria?.color, !colorHex.isEmpty {
            return Color(hex: colorHex)
        }
        return AppTheme.Colors.primary
    }
    
    var accountName: String {
        conto?.nome ?? "Conto"
    }
    
    var formattedAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "€"
        formatter.locale = Locale(identifier: "it_IT")
        return formatter.string(from: NSNumber(value: importo)) ?? String(format: "€ %.2f", importo)
    }
    
    var isExpense: Bool {
        tipo == "uscita"
    }
    
    var isIncome: Bool {
        tipo == "entrata"
    }
}

/// Category slice model for the Category Pie/Donut Chart.
struct CategoryPieSlice: Identifiable, Equatable {
    let id: String
    let categoryId: Int?
    let name: String
    let amount: Double
    let percentage: Double
    let color: Color
    let hexColor: String
    let count: Int
    
    static func == (lhs: CategoryPieSlice, rhs: CategoryPieSlice) -> Bool {
        lhs.id == rhs.id && lhs.amount == rhs.amount && lhs.percentage == rhs.percentage
    }
}

/// Generic container for paginated list endpoints fallback.
nonisolated struct PaginatedListResponse<T: Codable & Sendable>: Codable, Sendable {
    let count: Int?
    let next: String?
    let previous: String?
    let results: [T]
}
