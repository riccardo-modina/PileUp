import AppIntents
import Foundation

/// Intent of LogWalletTransaction shortcut
@available(iOS 16.0, *)
public struct LogWalletTransactionIntent: AppIntent {
    public static var title: LocalizedStringResource = "Registra Movimento di Spesa"
    
    public static var description = IntentDescription(
        "Intercetta e salva un movimento di spesa in PileUp da notifiche push bancarie, messaggi o automazioni personalizzate."
    )
    
    /// Optional explicit amount passed from Apple Pay / Wallet
    @Parameter(title: "Importo", description: "Importo della spesa (es. 14.50)")
    public var amount: Double?
    
    /// Optional merchant name
    @Parameter(title: "Esercente", description: "Nome dell'esercente o negozio")
    public var merchant: String?
    
    /// Optional card name (e.g. Revolut, Intesa)
    @Parameter(title: "Carta", description: "Nome o ultime cifre della carta")
    public var cardName: String?
    
    /// Optional transaction date
    @Parameter(title: "Data", description: "Data e ora dell'operazione")
    public var date: Date?
    
    /// Optional raw text from notification or SMS alert
    @Parameter(title: "Testo Notifica / SMS", description: "Testo completo della notifica bancaria da analizzare")
    public var rawNotificationText: String?
    
    public init() {}
    
    public init(
        amount: Double? = nil,
        merchant: String? = nil,
        cardName: String? = nil,
        date: Date? = nil,
        rawNotificationText: String? = nil
    ) {
        self.amount = amount
        self.merchant = merchant
        self.cardName = cardName
        self.date = date
        self.rawNotificationText = rawNotificationText
    }
    
    @MainActor
    public func perform() async throws -> some IntentResult & ProvidesDialog {
        let txDate = date ?? Date()
        
        // Scenario 1: Structured parameters provided (e.g. from Apple Pay / Wallet automation)
        if let amt = amount, amt > 0, let merch = merchant, !merch.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            let cleanMerchant = merch.trimmingCharacters(in: .whitespacesAndNewlines)
            let added = PendingTransactionsStore.shared.addTransaction(
                amount: amt,
                merchant: cleanMerchant,
                date: txDate,
                cardName: cardName
            )
            
            if added {
                return .result(dialog: "Spesa di \(String(format: "%.2f", amt)) € presso \(cleanMerchant) registrata in PileUp.")
            } else {
                return .result(dialog: "Transazione duplicata ignorata.")
            }
        }
        
        // Scenario 2: Generic notification or SMS text provided
        if let rawText = rawNotificationText, !rawText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            if let parsed = BankNotificationParser.shared.parse(text: rawText, knownBankName: cardName) {
                let added = PendingTransactionsStore.shared.addTransaction(
                    amount: parsed.amount,
                    merchant: parsed.merchant,
                    date: txDate,
                    cardName: parsed.paymentProvider ?? cardName
                )
                
                if added {
                    return .result(dialog: "Spesa rilevata: \(String(format: "%.2f", parsed.amount)) € presso \(parsed.merchant).")
                } else {
                    return .result(dialog: "Transazione duplicata ignorata.")
                }
            }
        }
        
        return .result(dialog: "Nessun dato di spesa valido trovato.")
    }
}

