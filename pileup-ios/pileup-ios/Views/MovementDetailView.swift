import SwiftUI

/// Comprehensive modal detail and edit view for a financial transaction.
/// Supports inspecting details, updating/modifying data (with E2EE encryption),
/// and deleting the movement with confirmation.
struct MovementDetailView: View {
    @Environment(\.presentationMode) var presentationMode
    let movement: MovementItem
    var onUpdated: (() -> Void)? = nil
    var onDeleted: (() -> Void)? = nil
    
    // MARK: - State
    @State private var isEditing: Bool = false
    @State private var showDeleteConfirmation: Bool = false
    @State private var showDiscardAlert: Bool = false
    @State private var isDeleting: Bool = false
    @State private var isSaving: Bool = false
    @State private var errorMessage: String? = nil
    
    // Edit Form State
    @State private var editType: MovementType = .expense
    @State private var editAmountString: String = ""
    @State private var editTitle: String = ""
    @State private var editDate: Date = Date()
    @State private var editNotes: String = ""
    @State private var selectedCategory: CategoryItem? = nil
    @State private var selectedAccount: AccountItem? = nil
    
    // Lists for pickers
    @State private var categories: [CategoryItem] = []
    @State private var accounts: [AccountItem] = []
    @State private var isLoadingData: Bool = false
    
    private let transactionAPI: TransactionAPIProtocol = TransactionAPI.shared
    private let categoryAPI: CategoryAPIProtocol = CategoryAPI.shared
    private let accountAPI: AccountAPIProtocol = AccountAPI.shared
    
    var body: some View {
        NavigationView {
            ZStack {
                AppTheme.Colors.dynamicBackground
                    .ignoresSafeArea()
                    .contentShape(Rectangle())
                    .onTapGesture {
                        hideKeyboard()
                    }
                
                if isEditing {
                    editContent
                } else {
                    detailContent
                }
                
                // Custom confirmation sheet for delete
                if showDeleteConfirmation {
                    ConfirmationBottomSheet(
                        icon: "trash.fill",
                        iconColor: AppTheme.Colors.negative,
                        iconBackgroundColor: AppTheme.Colors.negative.opacity(0.12),
                        title: "Elimina Movimento",
                        message: "Sei sicuro di voler eliminare '\(movement.titolo)', \(movement.formattedAmount)? Questa azione non può essere annullata.",
                        confirmTitle: "Elimina",
                        isDestructive: true,
                        isLoading: isDeleting,
                        onConfirm: {
                            deleteTransaction()
                        },
                        cancelTitle: "Annulla",
                        onCancel: {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                showDeleteConfirmation = false
                            }
                        }
                    )
                }
                
                // Custom confirmation sheet for exit when editing
                if showDiscardAlert {
                    ConfirmationBottomSheet(
                        icon: "exclamationmark.triangle.fill",
                        iconColor: Color.orange,
                        iconBackgroundColor: Color.orange.opacity(0.12),
                        title: "Modifiche non salvate",
                        message: "Sei sicuro di voler uscire? Tutte le modifiche apportate andranno perse.",
                        confirmTitle: "Esci senza salvare",
                        isDestructive: true,
                        isLoading: false,
                        onConfirm: {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                showDiscardAlert = false
                            }
                            presentationMode.wrappedValue.dismiss()
                        },
                        cancelTitle: "Continua a modificare",
                        onCancel: {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                showDiscardAlert = false
                            }
                        }
                    )
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if isEditing {
                        Button("Annulla") {
                            hideKeyboard()
                            if hasUnsavedChanges {
                                HapticHelper.warning()
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                    showDiscardAlert = true
                                }
                            } else {
                                presentationMode.wrappedValue.dismiss()
                            }
                        }
                        .foregroundColor(AppTheme.Colors.dynamicText)
                    } else {
                        Button(action: {
                            HapticHelper.light()
                            presentationMode.wrappedValue.dismiss()
                        }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(AppTheme.Colors.dynamicSubtext)
                        }
                    }
                }
                
                ToolbarItem(placement: .principal) {
                    Text(isEditing ? "Modifica Movimento" : "Dettaglio Movimento")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(AppTheme.Colors.dynamicText)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    if isEditing {
                        Button(action: saveChanges) {
                            if isSaving {
                                ProgressView()
                                    .scaleEffect(0.85)
                            } else {
                                Text("Salva")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(AppTheme.Colors.dynamicPrimary)
                            }
                        }
                        .disabled(isSaving || !isFormValid)
                    }
                }
            }
            .onAppear {
                initializeData()
            }
        }
    }
    
    // MARK: - Read-Only Detail View
    
    private var detailContent: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 24) {
                // Top Hero Card
                VStack(spacing: 10) {
                    // Badge & Amount Group
                    VStack(spacing: 4) {
                        Text(movement.isIncome ? "Entrata" : "Spesa")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(movement.isIncome ? AppTheme.Colors.moneyIn : AppTheme.Colors.moneyOut)
                        
                        Text("\(movement.isIncome ? "+" : "-") \(movement.formattedAmount)")
                            .font(.system(size: 34, weight: .bold, design: .rounded))
                            .foregroundColor(movement.isIncome ? AppTheme.Colors.moneyIn : AppTheme.Colors.dynamicText)
                    }
                    
                    // Title Display
                    Text(movement.titolo.isEmpty ? movement.categoryName : movement.titolo)
                        .font(.system(size: 17, weight: .medium))
                        .foregroundColor(AppTheme.Colors.dynamicSubtext)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
                .background(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(AppTheme.Colors.dynamicCardBackground)
                        .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 3)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(AppTheme.Colors.dynamicBorder.opacity(0.6), lineWidth: 1)
                )
                
                // Detailed Breakdown List
                VStack(spacing: 0) {
                    infoRow(icon: "calendar", label: "Data", value: formatFullDate(movement.data))
                    Divider().background(AppTheme.Colors.dynamicBorder.opacity(0.5)).padding(.leading, 44)
                    
                    infoRow(
                        icon: "tag.fill",
                        label: "Categoria",
                        value: movement.categoryName,
                        badgeColor: movement.categoryDisplayColor
                    )
                    Divider().background(AppTheme.Colors.dynamicBorder.opacity(0.5)).padding(.leading, 44)
                    
                    infoRow(icon: "creditcard.fill", label: "Conto", value: movement.accountName)
                    
                    if let desc = movement.descrizione, !desc.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Divider().background(AppTheme.Colors.dynamicBorder.opacity(0.5)).padding(.leading, 44)
                        infoRow(icon: "note.text", label: "Note", value: desc)
                    }
                }
                .background(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(AppTheme.Colors.dynamicCardBackground)
                        .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 3)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(AppTheme.Colors.dynamicBorder.opacity(0.6), lineWidth: 1)
                )
                
                // Action Buttons
                VStack(spacing: 12) {
                    // Edit button
                    Button(action: {
                        HapticHelper.light()
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isEditing = true
                        }
                    }) {
                        HStack {
                            Image(systemName: "pencil")
                                .font(.system(size: 15, weight: .semibold))
                            Text("Modifica Movimento")
                                .font(.system(size: 15, weight: .semibold))
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(AppTheme.Colors.dynamicCardBackground)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(AppTheme.Colors.dynamicBorder, lineWidth: 1)
                        )
                        .foregroundColor(AppTheme.Colors.dynamicText)
                    }
                    
                    // Delete button
                    Button(action: {
                        HapticHelper.warning()
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            showDeleteConfirmation = true
                        }
                    }) {
                        HStack {
                            if isDeleting {
                                ProgressView()
                                    .scaleEffect(0.85)
                            } else {
                                Image(systemName: "trash")
                                    .font(.system(size: 15, weight: .semibold))
                                Text("Elimina Movimento")
                                    .font(.system(size: 15, weight: .semibold))
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(AppTheme.Colors.negative.opacity(0.08))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(AppTheme.Colors.negative.opacity(0.2), lineWidth: 1)
                        )
                        .foregroundColor(AppTheme.Colors.negative)
                    }
                    .disabled(isDeleting)
                }
                .padding(.top, 8)
                
                if let err = errorMessage {
                    Text(err)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(AppTheme.Colors.negative)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 16)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 32)
        }
    }
    
    private func infoRow(icon: String, label: String, value: String, badgeColor: Color? = nil) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(AppTheme.Colors.dynamicSubtext)
                .frame(width: 24, height: 24)
            
            Text(label)
                .font(.system(size: 15, weight: .regular))
                .foregroundColor(AppTheme.Colors.dynamicSubtext)
            
            Spacer()
            
            HStack(spacing: 8) {
                if let color = badgeColor {
                    Circle()
                        .fill(color)
                        .frame(width: 10, height: 10)
                }
                Text(value)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(AppTheme.Colors.dynamicText)
                    .multilineTextAlignment(.trailing)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }
    
    // MARK: - Edit Form View
    
    private var editContent: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 20) {
                // Movement Type Picker
                Picker("Tipo Movimento", selection: $editType) {
                    Text("Spesa").tag(MovementType.expense)
                    Text("Entrata").tag(MovementType.income)
                }
                .pickerStyle(.segmented)
                .onChange(of: editType) { _, newType in
                    hideKeyboard()
                    // Adjust category when switching type
                    if let cat = selectedCategory, cat.tipo != newType.rawValue {
                        selectedCategory = filteredCategories.first
                    }
                }
                .padding(.top, 8)
                
                // Form Fields Group
                VStack(spacing: 16) {
                    // Amount Field
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Importo (€)")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(AppTheme.Colors.dynamicSubtext)
                        
                        HStack {
                            Text("€")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(AppTheme.Colors.dynamicSubtext)
                            
                            TextField("0,00", text: $editAmountString)
                                .font(.system(size: 22, weight: .bold, design: .rounded))
                                .foregroundColor(AppTheme.Colors.dynamicText)
                                .keyboardType(.decimalPad)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(AppTheme.Colors.dynamicCardBackground)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(AppTheme.Colors.dynamicBorder, lineWidth: 1)
                        )
                    }
                    
                    // Title Field
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Titolo / Descrizione breve")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(AppTheme.Colors.dynamicSubtext)
                        
                        TextField("Es. Spesa al supermercato", text: $editTitle)
                            .font(.system(size: 15, weight: .regular))
                            .foregroundColor(AppTheme.Colors.dynamicText)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(AppTheme.Colors.dynamicCardBackground)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(AppTheme.Colors.dynamicBorder, lineWidth: 1)
                            )
                    }
                    
                    // Date Field
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Data")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(AppTheme.Colors.dynamicSubtext)
                        
                        ZStack(alignment: .leading) {
                            HStack(spacing: 12) {
                                Image(systemName: "calendar")
                                    .font(.system(size: 16))
                                    .foregroundColor(AppTheme.Colors.dynamicSubtext)
                                
                                Text(formatDisplayDate(editDate))
                                    .font(.system(size: 15, weight: .regular))
                                    .foregroundColor(AppTheme.Colors.dynamicText)
                                
                                Spacer()
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(AppTheme.Colors.dynamicCardBackground)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(AppTheme.Colors.dynamicBorder, lineWidth: 1)
                            )
                            
                            // Native DatePicker overlay (invisible pill, responsive to taps)
                            DatePicker(
                                "",
                                selection: $editDate,
                                in: ...Date(),
                                displayedComponents: [.date]
                            )
                            .datePickerStyle(.compact)
                            .labelsHidden()
                            .blendMode(.destinationOver)
                            .opacity(0.015)
                            .scaleEffect(CGSize(width: 3.5, height: 1.2), anchor: .leading)
                            .padding(.leading, 14)
                        }
                    }
                    
                    // Category Picker
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Categoria")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(AppTheme.Colors.dynamicSubtext)
                        
                        CustomPickerField(
                            title: nil,
                            placeholder: "Seleziona categoria",
                            sheetTitle: "Seleziona Categoria",
                            searchPlaceholder: "Cerca categoria...",
                            items: filteredCategories.map { CustomPickerItem(category: $0) },
                            selectedId: Binding(
                                get: { selectedCategory?.id },
                                set: { newId in
                                    if let newId = newId {
                                        selectedCategory = filteredCategories.first(where: { $0.id == newId })
                                    } else {
                                        selectedCategory = nil
                                    }
                                }
                            ),
                            showAllOption: false,
                            allowClear: false,
                            onTap: {
                                hideKeyboard()
                            }
                        )
                    }
                    
                    // Account Picker
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Conto")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(AppTheme.Colors.dynamicSubtext)
                        
                        CustomPickerField(
                            title: nil,
                            placeholder: "Seleziona conto",
                            sheetTitle: "Seleziona Conto",
                            searchPlaceholder: "Cerca conto...",
                            items: availableAccounts.map { CustomPickerItem(account: $0) },
                            selectedId: Binding(
                                get: { selectedAccount?.id },
                                set: { newId in
                                    if let newId = newId {
                                        selectedAccount = availableAccounts.first(where: { $0.id == newId })
                                    } else {
                                        selectedAccount = nil
                                    }
                                }
                            ),
                            showAllOption: false,
                            allowClear: false,
                            onTap: {
                                hideKeyboard()
                            }
                        )
                    }
                    
                    // Notes Field
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Note (opzionali)")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(AppTheme.Colors.dynamicSubtext)
                        
                        TextField("Aggiungi eventuali dettagli...", text: $editNotes, axis: .vertical)
                            .lineLimit(3...5)
                            .font(.system(size: 15, weight: .regular))
                            .foregroundColor(AppTheme.Colors.dynamicText)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(AppTheme.Colors.dynamicCardBackground)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(AppTheme.Colors.dynamicBorder, lineWidth: 1)
                            )
                    }
                }
                
                if let err = errorMessage {
                    Text(err)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(AppTheme.Colors.negative)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 16)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 32)
            .frame(maxWidth: .infinity)
            .background(
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture {
                        hideKeyboard()
                    }
            )
        }
        .scrollDismissesKeyboard(.interactively)
        .background(
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture {
                    hideKeyboard()
                }
        )
    }
    
    // MARK: - Validation & Helpers
    
    private var filteredCategories: [CategoryItem] {
        categories.filter { $0.tipo == editType.rawValue && !$0.isSystem }
    }
    
    private var availableAccounts: [AccountItem] {
        accounts.filter { !$0.isSystem }
    }
    
    private var parsedAmount: Double {
        let clean = editAmountString
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: ",", with: ".")
        return Double(clean) ?? 0.0
    }
    
    private var isFormValid: Bool {
        parsedAmount > 0 && selectedCategory != nil && selectedAccount != nil
    }
    
    private var hasUnsavedChanges: Bool {
        let originalType = MovementType(rawValue: movement.tipo) ?? .expense
        if editType != originalType { return true }
        
        let originalAmountStr = String(format: "%.2f", movement.importo).replacingOccurrences(of: ".", with: ",")
        if editAmountString.trimmingCharacters(in: .whitespaces) != originalAmountStr && abs(parsedAmount - movement.importo) > 0.001 {
            return true
        }
        
        if editTitle.trimmingCharacters(in: .whitespacesAndNewlines) != movement.titolo.trimmingCharacters(in: .whitespacesAndNewlines) {
            return true
        }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        let editDateStr = formatter.string(from: editDate)
        if editDateStr != movement.data {
            return true
        }
        
        if selectedCategory?.id != movement.categoria?.id {
            return true
        }
        
        if selectedAccount?.id != movement.conto?.id {
            return true
        }
        
        let currentNotes = editNotes.trimmingCharacters(in: .whitespacesAndNewlines)
        let origNotes = movement.descrizione?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if currentNotes != origNotes {
            return true
        }
        
        return false
    }
    
    private func initializeData() {
        resetEditFields()
        fetchCategoriesAndAccounts()
    }
    
    private func resetEditFields() {
        editType = movement.isIncome ? .income : .expense
        editAmountString = String(format: "%.2f", movement.importo).replacingOccurrences(of: ".", with: ",")
        editTitle = movement.titolo
        editNotes = movement.descrizione ?? ""
        selectedCategory = movement.categoria
        selectedAccount = movement.conto
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        if let d = formatter.date(from: movement.data) {
            editDate = d
        } else {
            editDate = Date()
        }
    }
    
    private func fetchCategoriesAndAccounts() {
        isLoadingData = true
        Task {
            do {
                async let catTask = categoryAPI.getAllCategories()
                async let accTask = accountAPI.getAllAccounts()
                let (cats, accs) = try await (catTask, accTask)
                
                await MainActor.run {
                    self.categories = cats
                    self.accounts = accs
                    self.isLoadingData = false
                    
                    // Match selected category and account to fetched objects by id
                    if let curCatId = movement.categoria?.id,
                       let matchedCat = cats.first(where: { $0.id == curCatId }) {
                        self.selectedCategory = matchedCat
                    }
                    if let curAccId = movement.conto?.id,
                       let matchedAcc = accs.first(where: { $0.id == curAccId }) {
                        self.selectedAccount = matchedAcc
                    }
                }
            } catch {
                await MainActor.run {
                    self.isLoadingData = false
                }
            }
        }
    }
    
    // MARK: - Actions
    
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
    private func saveChanges() {
        hideKeyboard()
        guard isFormValid else { return }
        guard let cat = selectedCategory, let acc = selectedAccount else { return }
        
        isSaving = true
        errorMessage = nil
        
        let dateForm = DateFormatter()
        dateForm.dateFormat = "yyyy-MM-dd"
        dateForm.locale = Locale(identifier: "en_US_POSIX")
        let dateStr = dateForm.string(from: editDate)
        
        var effectiveTitle = editTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        if effectiveTitle.isEmpty {
            effectiveTitle = cat.nome
        }
        
        var effectiveDesc: String? = editNotes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : editNotes
        
        // E2EE Encryption
        if let key = KeychainManager.shared.getMasterKey(), !key.isEmpty {
            if let encT = CryptoHelper.encryptData(effectiveTitle, key: key) {
                effectiveTitle = encT
            }
            if let desc = effectiveDesc, let encD = CryptoHelper.encryptData(desc, key: key) {
                effectiveDesc = encD
            }
        }
        
        let payload = MovementPayload(
            titolo: effectiveTitle,
            importo: parsedAmount,
            data: dateStr,
            categoria: cat.id,
            conto: acc.id,
            descrizione: effectiveDesc
        )
        
        Task {
            do {
                let _ = try await transactionAPI.updateMovement(id: movement.id, payload: payload)
                
                await MainActor.run {
                    isSaving = false
                    HapticHelper.success()
                    NotificationCenter.default.post(name: NSNotification.Name("TransactionsUpdated"), object: nil)
                    onUpdated?()
                    presentationMode.wrappedValue.dismiss()
                }
            } catch {
                await MainActor.run {
                    isSaving = false
                    errorMessage = ErrorHandler.format(error)
                    HapticHelper.error()
                }
            }
        }
    }
    
    private func deleteTransaction() {
        isDeleting = true
        errorMessage = nil
        
        Task {
            do {
                try await transactionAPI.deleteMovement(id: movement.id)
                
                await MainActor.run {
                    isDeleting = false
                    HapticHelper.success()
                    NotificationCenter.default.post(name: NSNotification.Name("TransactionsUpdated"), object: nil)
                    onDeleted?()
                    presentationMode.wrappedValue.dismiss()
                }
            } catch {
                await MainActor.run {
                    isDeleting = false
                    errorMessage = ErrorHandler.format(error)
                    HapticHelper.error()
                }
            }
        }
    }
    
    private func formatFullDate(_ raw: String) -> String {
        let inFormatter = DateFormatter()
        inFormatter.dateFormat = "yyyy-MM-dd"
        inFormatter.locale = Locale(identifier: "en_US_POSIX")
        guard let date = inFormatter.date(from: raw) else { return raw }
        
        let outFormatter = DateFormatter()
        outFormatter.locale = Locale(identifier: "it_IT")
        outFormatter.dateFormat = "EEEE d MMMM yyyy"
        return outFormatter.string(from: date).capitalized
    }
    
    private func formatDisplayDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "it_IT")
        formatter.dateFormat = "d MMMM yyyy"
        return formatter.string(from: date).capitalized
    }
}
