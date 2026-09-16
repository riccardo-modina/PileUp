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
struct CategoryItem: Identifiable, Codable, Hashable {
    let id: Int
    let nome: String
    let tipo: String
    let color: String?
    let is_system: Bool?
    
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
struct AccountItem: Identifiable, Codable, Hashable {
    let id: Int
    let nome: String
    let tipo: String?
    let valuta: String?
    let color: String?
    let is_system: Bool?
    
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
struct MovementPayload: Codable {
    let titolo: String
    let importo: Double
    let data: String // YYYY-MM-DD
    let categoria: Int
    let conto: Int
    let descrizione: String?
}

/// Response returned when creating or updating a movement.
struct MovementResponse: Codable {
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
        self.categoria = try? container.decodeIfPresent(Int.self, forKey: .categoria)
        self.conto = try? container.decodeIfPresent(Int.self, forKey: .conto)
        self.tipo = try? container.decodeIfPresent(String.self, forKey: .tipo)
        self.descrizione = try? container.decodeIfPresent(String.self, forKey: .descrizione)
        
        if let doubleVal = try? container.decodeIfPresent(Double.self, forKey: .importo) {
            self.importo = doubleVal
        } else if let stringVal = try? container.decodeIfPresent(String.self, forKey: .importo) {
            self.importo = Double(stringVal)
        } else {
            self.importo = nil
        }
    }
}

/// Generic container for paginated list endpoints fallback.
struct PaginatedListResponse<T: Codable>: Codable {
    let count: Int?
    let results: [T]
}
