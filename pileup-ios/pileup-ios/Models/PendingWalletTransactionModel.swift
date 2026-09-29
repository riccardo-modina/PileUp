import Foundation

/// Represents a transaction intercepted from Apple Wallet pending user review/approval.
struct PendingWalletTransactionModel: Identifiable, Codable, Sendable, Equatable {
    let id: UUID
    /// From merchant name
    var title: String
    var amount: Double
    var date: Date
    var accountId: Int?
    var categoryId: Int?
    var notes: String?
    
    init(
        id: UUID = UUID(),
        title: String,
        amount: Double,
        date: Date = Date(),
        accountId: Int? = nil,
        categoryId: Int? = nil,
        notes: String? = nil
    ) {
        self.id = id
        self.title = title
        self.amount = amount
        self.date = date
        self.accountId = accountId
        self.categoryId = categoryId
        self.notes = notes
    }
}
