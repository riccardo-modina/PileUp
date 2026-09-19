import Foundation
import SwiftUI
import Combine
import UIKit

@MainActor
class AddTransactionViewModel: ObservableObject {
    // MARK: - Navigation / Wizard State
    @Published var currentStep: Int = 1 // 1: Category & Amount, 2: Date & Account, 3: Details & Confirmation
    
    // MARK: - Step 1: Type, Category & Amount
    @Published var movementType: MovementType = .expense {
        didSet {
            // Reset selected category if it does not match the newly selected movement type
            if let cat = selectedCategory, cat.tipo != movementType.rawValue {
                selectedCategory = nil
            }
            // Auto-select first available category if none is currently selected
            autoSelectFirstCategoryIfNeeded()
        }
    }
    @Published var selectedCategory: CategoryItem? = nil {
        didSet {
            if selectedCategory != nil {
                showCategoryError = false
            }
        }
    }
    @Published var amountString: String = ""
    
    // MARK: - Validation & Feedback States (Matching Frontend useCurrencyInput.js and Form Steps)
    @Published var showNumericError: Bool = false     // "Sono consentiti solo numeri e un separatore decimale"
    @Published var showDecimalError: Bool = false     // "Massimo 4 cifre decimali consentite"
    @Published var showZeroError: Bool = false        // "L'importo deve essere maggiore di zero"
    @Published var showLimitError: Bool = false       // "Limite massimo di 10M superato!"
    @Published var showCategoryError: Bool = false    // "Seleziona una categoria"
    @Published var showAccountError: Bool = false     // "Seleziona un conto"
    @Published var showFutureDateError: Bool = false  // "Non è possibile selezionare una data futura — impostata la data di oggi."
    
    // MARK: - Step 2: Date & Account
    @Published var date: Date = Date() {
        didSet {
            // Prevent future dates matching frontend
            if date > Date() {
                date = Date()
                showFutureDateError = true
                HapticHelper.warning()
            } else {
                showFutureDateError = false
            }
        }
    }
    @Published var selectedAccount: AccountItem? = nil {
        didSet {
            if selectedAccount != nil {
                showAccountError = false
            }
        }
    }
    
    // MARK: - Step 3: Details
    @Published var customTitle: String = ""
    @Published var notes: String = ""
    
    // MARK: - Data Source Lists
    @Published var categories: [CategoryItem] = []
    @Published var accounts: [AccountItem] = []
    
    // MARK: - Loading & Feedback States
    @Published var isLoadingData: Bool = false
    @Published var isSubmitting: Bool = false
    @Published var errorMessage: String? = nil
    @Published var saveSuccess: Bool = false
    @Published var shakeAmount: Bool = false
    
    // E2EE Master Key passed from AuthViewModel or Keychain
    var masterKey: String? = nil
    
    private let categoryAPI: CategoryAPIProtocol
    private let accountAPI: AccountAPIProtocol
    private let transactionAPI: TransactionAPIProtocol
    
    init(
        masterKey: String? = nil,
        categoryAPI: CategoryAPIProtocol = CategoryAPI.shared,
        accountAPI: AccountAPIProtocol = AccountAPI.shared,
        transactionAPI: TransactionAPIProtocol = TransactionAPI.shared
    ) {
        self.masterKey = masterKey
        self.categoryAPI = categoryAPI
        self.accountAPI = accountAPI
        self.transactionAPI = transactionAPI
        fetchCategoriesAndAccounts()
    }
    
    // MARK: - Real-Time Amount Sanitization & Input Controls
    
    /// Sanitizes raw input, removes illegal characters (letters/symbols), strips redundant leading zeroes
    /// (e.g. "09" -> "9"), enforces max 4 decimal places and max 10.000.000 limit, matching frontend useCurrencyInput.js.
    func updateAmount(_ newValue: String) {
        let original = newValue.trimmingCharacters(in: .whitespaces)
        if original.isEmpty {
            amountString = ""
            showNumericError = false
            showDecimalError = false
            showZeroError = false
            showLimitError = false
            return
        }
        
        // 1. Check for invalid characters (letters, symbols)
        let allowed = CharacterSet(charactersIn: "0123456789.,")
        let hasInvalidChars = original.unicodeScalars.contains { !allowed.contains($0) }
        
        let filtered = original.filter { "0123456789.,".contains($0) }
        
        // 2. Count decimal separators (. and ,)
        let separatorsCount = filtered.filter { $0 == "." || $0 == "," }.count
        let hasMultipleSeparators = separatorsCount > 1
        
        if hasInvalidChars || hasMultipleSeparators {
            showNumericError = true
            HapticHelper.warning()
        } else {
            showNumericError = false
        }
        
        // Retain only the first separator (convert all to comma ",")
        var seenSeparator = false
        var singleSepString = ""
        for ch in filtered {
            if ch == "." || ch == "," {
                if !seenSeparator {
                    seenSeparator = true
                    singleSepString.append(",")
                }
            } else {
                singleSepString.append(ch)
            }
        }
        var processed = singleSepString
        
        // If input starts with separator, e.g. ",5", prefix with "0"
        if processed.hasPrefix(",") {
            processed = "0" + processed
        }
        
        // 3. Leading zeroes handling (e.g. "09" -> "9", "007" -> "7", "00" -> "0")
        // If there's no comma and it starts with 0 followed by digits, normalize
        if !processed.contains(",") {
            if processed.hasPrefix("0") && processed.count > 1 {
                let trimmed = processed.drop(while: { $0 == "0" })
                processed = trimmed.isEmpty ? "0" : String(trimmed)
            }
        }
        
        // 4. Decimals limit: maximum 4 decimals allowed
        if let commaIndex = processed.firstIndex(of: ",") {
            let decimals = processed[processed.index(after: commaIndex)...]
            if decimals.count > 4 {
                showDecimalError = true
                HapticHelper.warning()
                let allowedDecimals = decimals.prefix(4)
                processed = String(processed[..<processed.index(after: commaIndex)]) + allowedDecimals
            } else {
                showDecimalError = false
            }
        } else {
            showDecimalError = false
        }
        
        // 5. Numerical range checks (Zero and 10M limit)
        let cleanForDouble = processed.replacingOccurrences(of: ",", with: ".")
        if let doubleVal = Double(cleanForDouble) {
            if doubleVal <= 0 && processed != "0," && !processed.hasPrefix("0,0") {
                showZeroError = true
            } else {
                showZeroError = false
            }
            
            if doubleVal > 10_000_000 {
                showLimitError = true
                HapticHelper.warning()
            } else {
                showLimitError = false
            }
        } else {
            showZeroError = false
            showLimitError = false
        }
        
        amountString = processed
    }
    
    // MARK: - Computed Properties
    
    /// Categories filtered by current movement type and excluding system fallback items.
    var filteredCategories: [CategoryItem] {
        categories.filter { $0.tipo == movementType.rawValue && !$0.isSystem }
    }
    
    /// Valid user accounts excluding the system fallback account.
    var availableAccounts: [AccountItem] {
        accounts.filter { !$0.isSystem }
    }
    
    /// Parsed amount value converted to Double.
    var parsedAmount: Double {
        let clean = amountString
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: ",", with: ".")
        return Double(clean) ?? 0.0
    }
    
    /// Placeholder and default title inferred from the selected category.
    var defaultTitle: String {
        if let cat = selectedCategory {
            return cat.nome
        }
        return "Nuovo Movimento"
    }
    
    /// Final title sent with the payload.
    var effectiveTitle: String {
        let trimmed = customTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? defaultTitle : trimmed
    }
    
    /// Progress ratio for the header bar (0.33, 0.66, 1.0).
    var progress: Double {
        switch currentStep {
        case 1: return 0.33
        case 2: return 0.66
        case 3: return 1.0
        default: return 0.33
        }
    }
    
    /// Checks validity for Step 1 (valid category, amount > 0, within limit, no format errors).
    var isStep1Valid: Bool {
        selectedCategory != nil && parsedAmount > 0 && parsedAmount <= 10_000_000 && !showNumericError && !showDecimalError
    }
    
    /// Checks validity for Step 2 (account selected).
    var isStep2Valid: Bool {
        selectedAccount != nil
    }
    
    /// Overall readiness check prior to final submission.
    var canSubmit: Bool {
        isStep1Valid && isStep2Valid && !isSubmitting
    }
    
    /// Checks whether user has inputted any data (used for dirty-check discard prompt).
    var hasUnsavedChanges: Bool {
        !amountString.isEmpty || selectedCategory != nil || !customTitle.isEmpty || !notes.isEmpty
    }
    
    // MARK: - Data Fetching
    
    func fetchCategoriesAndAccounts() {
        isLoadingData = true
        errorMessage = nil
        
        Task {
            do {
                // Fetch categories and accounts in parallel via dedicated APIs
                async let catDataTask = self.categoryAPI.getAllCategories()
                async let accDataTask = self.accountAPI.getAllAccounts()
                
                let (fetchedCats, fetchedAccs) = try await (catDataTask, accDataTask)
                
                self.categories = fetchedCats
                self.accounts = fetchedAccs
                self.isLoadingData = false
                
                // Auto-select first matching category if available
                self.autoSelectFirstCategoryIfNeeded()
                
                // Auto-select first available account if unset
                if self.selectedAccount == nil {
                    self.selectedAccount = self.availableAccounts.first
                }
            } catch {
                self.isLoadingData = false
                self.errorMessage = "Impossibile caricare categorie e conti: \(error.localizedDescription)"
            }
        }
    }
    
    private func autoSelectFirstCategoryIfNeeded() {
        if selectedCategory == nil, let first = filteredCategories.first {
            selectedCategory = first
        }
    }
    
    // MARK: - Navigation Control
    
    func nextStep() {
        errorMessage = nil
        if currentStep == 1 {
            var hasStep1Error = false
            if selectedCategory == nil {
                showCategoryError = true
                hasStep1Error = true
            }
            if amountString.isEmpty || parsedAmount <= 0 {
                showZeroError = true
                hasStep1Error = true
            }
            if parsedAmount > 10_000_000 {
                showLimitError = true
                hasStep1Error = true
            }
            if showNumericError || showDecimalError {
                hasStep1Error = true
            }
            if hasStep1Error {
                triggerShake()
                return
            }
            withAnimation(.spring(response: 0.38, dampingFraction: 0.82)) {
                currentStep = 2
            }
        } else if currentStep == 2 {
            if selectedAccount == nil {
                showAccountError = true
                triggerShake()
                return
            }
            withAnimation(.spring(response: 0.38, dampingFraction: 0.82)) {
                currentStep = 3
            }
        }
    }
    
    func previousStep() {
        errorMessage = nil
        if currentStep > 1 {
            withAnimation(.spring(response: 0.38, dampingFraction: 0.82)) {
                currentStep -= 1
            }
        }
    }
    
    func triggerShake() {
        HapticHelper.warning()
        shakeAmount = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            self.shakeAmount = false
        }
    }
    
    // MARK: - Submission & E2EE
    
    func submitTransaction() {
        guard canSubmit else { return }
        guard let category = selectedCategory, let account = selectedAccount else { return }
        
        isSubmitting = true
        errorMessage = nil
        
        // Format date to ISO yyyy-MM-dd
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        let dateString = formatter.string(from: date)
        
        // End-to-End Encryption (E2EE) for title and description
        var encryptedTitle = effectiveTitle
        var encryptedDescription: String? = notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : notes
        
        // Use provided masterKey or fallback to Keychain
        let key = masterKey ?? KeychainManager.shared.getMasterKey()
        if let key = key, !key.isEmpty {
            if let encT = CryptoHelper.encryptData(encryptedTitle, key: key) {
                encryptedTitle = encT
            }
            if let desc = encryptedDescription, let encD = CryptoHelper.encryptData(desc, key: key) {
                encryptedDescription = encD
            }
        }
        
        let payload = MovementPayload(
            titolo: encryptedTitle,
            importo: parsedAmount,
            data: dateString,
            categoria: category.id,
            conto: account.id,
            descrizione: encryptedDescription
        )
        
        Task {
            do {
                let _ = try await self.transactionAPI.createMovement(payload: payload)
                
                self.isSubmitting = false
                self.saveSuccess = true
                
                // Success haptic feedback
                HapticHelper.success()
                
                // Notify observers to refresh dashboard figures and charts
                NotificationCenter.default.post(name: NSNotification.Name("TransactionsUpdated"), object: nil)
            } catch {
                self.isSubmitting = false
                print("Error saving movement: \(error)")
                self.errorMessage = "Errore durante il salvataggio: \(error.localizedDescription)"
                HapticHelper.error()
            }
        }
    }
}
