import Foundation
import Combine

/// Thread-safe manager for local persistence of transactions intercepted from Apple Wallet.
/// Stores data in an encrypted JSON file with hardware protection permitting writes even when the screen is locked.
final class PendingTransactionsStore: ObservableObject {
    static let shared = PendingTransactionsStore()
    
    /// Reactive list of pending transactions for the app UI
    @Published private(set) var pendingTransactions: [PendingWalletTransactionModel] = []
    
    /// Serial queue to synchronize reads and writes between background processes (AppIntent) and foreground (UI)
    private let queue = DispatchQueue(label: "com.pileup.pendingTransactionsStore", qos: .userInitiated)
    
    /// File name for the pending transactions queue
    private let fileName = "pending_wallet_transactions.json"
    
    /// File name for the lightweight offline accounts cache (used for card -> account matching)
    private let accountsCacheFileName = "cached_wallet_accounts.json"
    
    private init() {
        loadFromDisk()
    }
    
    // MARK: - On-Disk File Paths
    
    private var applicationSupportDirectory: URL {
        let urls = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)
        let dir = urls[0]
        if !FileManager.default.fileExists(atPath: dir.path) {
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true, attributes: nil)
        }
        return dir
    }
    
    private var fileURL: URL {
        applicationSupportDirectory.appendingPathComponent(fileName)
    }
    
    private var accountsCacheURL: URL {
        applicationSupportDirectory.appendingPathComponent(accountsCacheFileName)
    }
    
    // MARK: - Core Operations (Thread-Safe)
    
    /// Adds a new transaction intercepted from Apple Wallet.
    /// Automatically performs deduplication (120-second window) and card -> account matching.
    /// Returns `true` if the transaction was saved, `false` if it was discarded as a duplicate.
    @discardableResult
    func addTransaction(
        amount: Double,
        merchant: String,
        date: Date = Date(),
        cardName: String? = nil
    ) -> Bool {
        return queue.sync {
            let cleanMerchant = merchant.trimmingCharacters(in: .whitespacesAndNewlines)
            guard amount > 0, !cleanMerchant.isEmpty else { return false }
            
            // Check if is duplicate
            let isDuplicate = pendingTransactions.contains { existing in
                abs(existing.date.timeIntervalSince(date)) < 120 &&
                existing.amount == amount &&
                existing.title.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == cleanMerchant.lowercased()
            }
            
            if isDuplicate {
                return false
            }
            
            // Search possible match between card name and an account
            let matchedAccountId = findMatchingAccountId(forCard: cardName)
            
            let newTransaction = PendingWalletTransactionModel(
                title: cleanMerchant,
                amount: amount,
                date: date,
                accountId: matchedAccountId,
                categoryId: nil,
                notes: nil
            )
            
            var updatedList = pendingTransactions
            updatedList.append(newTransaction)
            
            saveToDisk(updatedList)
            
            // Notify application of new transaction added
            DispatchQueue.main.async {
                self.pendingTransactions = updatedList
                NotificationCenter.default.post(name: NSNotification.Name("PendingTransactionsUpdated"), object: nil)
            }
            
            return true
        }
    }
    
    /// Updates an existing transaction (e.g. when user selects a category or modifies the title).
    func updateTransaction(_ transaction: PendingWalletTransactionModel) {
        queue.sync {
            guard let index = pendingTransactions.firstIndex(where: { $0.id == transaction.id }) else { return }
            var updatedList = pendingTransactions
            updatedList[index] = transaction
            saveToDisk(updatedList)
            
            DispatchQueue.main.async {
                self.pendingTransactions = updatedList
                NotificationCenter.default.post(name: NSNotification.Name("PendingTransactionsUpdated"), object: nil)
            }
        }
    }
    
    /// Removes an approved or discarded transaction from local cache.
    func removeTransaction(id: UUID) {
        queue.sync {
            var updatedList = pendingTransactions
            updatedList.removeAll { $0.id == id }
            saveToDisk(updatedList)
            
            DispatchQueue.main.async {
                self.pendingTransactions = updatedList
                NotificationCenter.default.post(name: NSNotification.Name("PendingTransactionsUpdated"), object: nil)
            }
        }
    }
    
    /// Clears all pending transactions.
    func clearAll() {
        queue.sync {
            saveToDisk([])
            DispatchQueue.main.async {
                self.pendingTransactions = []
                NotificationCenter.default.post(name: NSNotification.Name("PendingTransactionsUpdated"), object: nil)
            }
        }
    }
    
    // MARK: - Accounts Cache for Card -> Account Smart Matching
    
    /// Checks if the local accounts cache already exists on disk.
    var isAccountsCachePresent: Bool {
        guard FileManager.default.fileExists(atPath: accountsCacheURL.path),
              let data = try? Data(contentsOf: accountsCacheURL),
              !data.isEmpty else {
            return false
        }
        return true
    }
    
    /// Ensures that the accounts cache is populated upon app launch.
    /// If cache does not exist yet (or when force = true), downloads accounts via AccountAPI and stores them.
    func ensureAccountsCache(accountAPI: AccountAPIProtocol = AccountAPI.shared, force: Bool = false) async {
        if !force && isAccountsCachePresent {
            return
        }
        do {
            let accounts = try await accountAPI.getAllAccounts()
            updateAccountsCache(accounts)
        } catch {
            // Silently fallback if network request fails
        }
    }
    
    /// Saves a lightweight offline copy of user accounts to allow background AppIntent to match cards immediately.
    /// NOTE: Call this in the future after creating, modifying, or deleting an account.
    func updateAccountsCache(_ accounts: [AccountItem]) {
        queue.async {
            struct SimpleAccount: Codable {
                let id: Int
                let nome: String
            }
            let simplified = accounts.map { SimpleAccount(id: $0.id, nome: $0.nome) }
            do {
                let data = try JSONEncoder().encode(simplified)
                try data.write(to: self.accountsCacheURL, options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
            } catch {
                // Silently fallback on disk write failure
            }
        }
    }
    
    /// Searches for a match between Apple Pay card name and a PileUp account.
    private func findMatchingAccountId(forCard cardName: String?) -> Int? {
        guard let card = cardName?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased(), !card.isEmpty else {
            return nil
        }
        
        guard let data = try? Data(contentsOf: accountsCacheURL),
              let accounts = try? JSONDecoder().decode([SimpleAccountCache].self, from: data) else {
            return nil
        }
        
        // Match condition: e.g. card "Revolut" matches account "Revolut", or account "Carta Intesa" matches "Intesa"
        for acc in accounts {
            let accLower = acc.nome.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            if accLower == card || accLower.contains(card) || card.contains(accLower) {
                return acc.id
            }
        }
        return nil
    }
    
    // MARK: - On-Disk Persistence
    
    private func saveToDisk(_ list: [PendingWalletTransactionModel]) {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(list)
            
            // Atomic write protected with complete protection until first user authentication (accessible with screen locked)
            try data.write(to: fileURL, options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
        } catch {
            // Silently fallback on disk write failure
        }
    }
    
    private func loadFromDisk() {
        queue.sync {
            guard FileManager.default.fileExists(atPath: fileURL.path) else { return }
            do {
                let data = try Data(contentsOf: fileURL)
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                let list = try decoder.decode([PendingWalletTransactionModel].self, from: data)
                DispatchQueue.main.async {
                    self.pendingTransactions = list
                }
            } catch {
                // Silently fallback on disk read failure
            }
        }
    }
}

/// Lightweight model used internally for the accounts cache
private struct SimpleAccountCache: Codable {
    let id: Int
    let nome: String
}
