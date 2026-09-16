import SwiftUI

/// Fast guided wizard view for recording expenses and incomes.
/// Organized into 3 sequential steps with a top progress bar and smooth animated transitions.
struct AddTransactionView: View {
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var viewModel: AddTransactionViewModel
    
    // Discard confirmation alert for unsaved changes
    @State private var showDiscardAlert: Bool = false
    // Automatic focus on amount field in Step 1
    @FocusState private var isAmountFocused: Bool
    // Toggles inline calendar picker if user chooses a custom date
    @State private var showCustomDatePicker: Bool = false
    // Category dropdown menu and search query
    @State private var isCategoryDropdownOpen: Bool = false
    @State private var categorySearchQuery: String = ""
    
    private var searchedCategories: [CategoryItem] {
        let list = viewModel.filteredCategories
        let query = categorySearchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        if query.isEmpty {
            return list
        }
        return list.filter { $0.nome.localizedCaseInsensitiveContains(query) }
    }
    
    // Success animation overlay states
    @State private var showSuccessOverlay: Bool = false
    @State private var checkmarkScale: CGFloat = 0.2
    @State private var pulseRingScale: CGFloat = 0.8
    @State private var pulseRingOpacity: Double = 0.7
    
    init(masterKey: String? = nil) {
        _viewModel = StateObject(wrappedValue: AddTransactionViewModel(masterKey: masterKey))
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                AppTheme.Colors.dynamicBackground
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // 1. Top Navigation & Progress Header
                    headerSection
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                        .padding(.bottom, 12)
                    
                    // 2. Main Step Content with animated transitions
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(spacing: 20) {
                            if viewModel.isLoadingData {
                                loadingPlaceholder
                            } else {
                                switch viewModel.currentStep {
                                case 1:
                                    step1CategoryAndAmount
                                        .transition(.asymmetric(
                                            insertion: .move(edge: .leading).combined(with: .opacity),
                                            removal: .move(edge: .leading).combined(with: .opacity)
                                        ))
                                case 2:
                                    step2DateAndAccount
                                        .transition(.asymmetric(
                                            insertion: .move(edge: .trailing).combined(with: .opacity),
                                            removal: .move(edge: .leading).combined(with: .opacity)
                                        ))
                                case 3:
                                    step3DetailsAndConfirm
                                        .transition(.asymmetric(
                                            insertion: .move(edge: .trailing).combined(with: .opacity),
                                            removal: .move(edge: .trailing).combined(with: .opacity)
                                        ))
                                default:
                                    EmptyView()
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 8)
                        .padding(.bottom, 100) // Spacing above sticky bottom action bar
                    }
                    
                    Spacer(minLength: 0)
                }
                
                // 3. Fixed Bottom Action Button
                VStack {
                    Spacer()
                    bottomActionBar
                        .padding(.horizontal, 20)
                        .padding(.bottom, 16)
                        .background(
                            LinearGradient(
                                colors: [
                                    AppTheme.Colors.dynamicBackground.opacity(0.0),
                                    AppTheme.Colors.dynamicBackground.opacity(0.95),
                                    AppTheme.Colors.dynamicBackground
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                            .ignoresSafeArea()
                        )
                }
                
                // 4. Celebratory Success Overlay Animation
                if showSuccessOverlay {
                    successAnimationOverlay
                        .transition(.opacity)
                        .zIndex(50)
                }
            }
            .navigationBarHidden(true)
            .alert(isPresented: $showDiscardAlert) {
                Alert(
                    title: Text("Modifiche non salvate"),
                    message: Text("Hai inserito dei dati che non sono ancora stati salvati. Se esci ora, andranno persi."),
                    primaryButton: .destructive(Text("Esci")) {
                        presentationMode.wrappedValue.dismiss()
                    },
                    secondaryButton: .cancel(Text("Continua"))
                )
            }
            .onChange(of: viewModel.saveSuccess) {
                if viewModel.saveSuccess {
                    HapticHelper.success()
                    withAnimation(.spring(response: 0.45, dampingFraction: 0.7)) {
                        showSuccessOverlay = true
                    }
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.65)) {
                        checkmarkScale = 1.0
                    }
                    withAnimation(.easeOut(duration: 0.9)) {
                        pulseRingScale = 1.5
                        pulseRingOpacity = 0.0
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.25) {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
            .onAppear {
                if viewModel.currentStep == 1 {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                        isAmountFocused = true
                    }
                }
            }
        }
    }
    
    // MARK: - 1. Header & Progress Section
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            HStack(alignment: .center) {
                // Back button (visible starting from Step 2)
                if viewModel.currentStep > 1 {
                    Button(action: {
                        HapticHelper.light()
                        viewModel.previousStep()
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 14, weight: .semibold))
                            Text("Indietro")
                                .font(.system(size: 14, weight: .medium))
                        }
                        .foregroundColor(AppTheme.Colors.dynamicText)
                    }
                } else {
                    // Placeholder to preserve centered alignment
                    Color.clear
                        .frame(width: 60, height: 20)
                }
                
                Spacer()
                
                // Step counter label
                Text("Passo \(viewModel.currentStep) di 3")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(AppTheme.Colors.dynamicSubtext)
                    .textCase(.uppercase)
                    .tracking(1)
                
                Spacer()
                
                // Dismiss button
                Button(action: {
                    HapticHelper.light()
                    if viewModel.hasUnsavedChanges {
                        showDiscardAlert = true
                    } else {
                        presentationMode.wrappedValue.dismiss()
                    }
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(AppTheme.Colors.dynamicSubtext.opacity(0.8))
                }
            }
            
            // Smooth progress indicator
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(AppTheme.Colors.dynamicBorder.opacity(0.5))
                        .frame(height: 5)
                    
                    Capsule()
                        .fill(AppTheme.Colors.dynamicText)
                        .frame(width: geometry.size.width * CGFloat(viewModel.progress), height: 5)
                        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: viewModel.progress)
                }
            }
            .frame(height: 5)
        }
    }
    
    // MARK: - 2. STEP 1: Type, Category & Amount
    
    private var step1CategoryAndAmount: some View {
        VStack(alignment: .leading, spacing: 22) {
            // A. Segmented Pill for Movement Type
            HStack(spacing: 8) {
                ForEach(MovementType.allCases) { type in
                    Button(action: {
                        HapticHelper.selection()
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                            viewModel.movementType = type
                        }
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: type.iconName)
                                .font(.system(size: 12, weight: .bold))
                            Text(type.title)
                                .font(.system(size: 13, weight: .semibold))
                        }
                        .foregroundColor(viewModel.movementType == type ? .white : AppTheme.Colors.dynamicText)
                        .padding(.vertical, 9)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(viewModel.movementType == type ? type.accentColor : AppTheme.Colors.dynamicCardBackground)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(viewModel.movementType == type ? Color.clear : AppTheme.Colors.dynamicBorder.opacity(0.6), lineWidth: 1)
                        )
                        .shadow(color: viewModel.movementType == type ? type.accentColor.opacity(0.25) : Color.black.opacity(0.02), radius: 4, y: 2)
                    }
                    .buttonStyle(.plain)
                }
            }
            
            // B. Hero Amount Input
            // B. Hero Amount Input
            VStack(alignment: .leading, spacing: 6) {
                Text("IMPORTO")
                    .font(.system(size: 11, weight: .bold))
                    .tracking(1.5)
                    .foregroundColor(AppTheme.Colors.dynamicSubtext)
                
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text("€")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(AppTheme.Colors.dynamicSubtext)
                    
                    TextField("0,00", text: Binding(
                        get: { viewModel.amountString },
                        set: { viewModel.updateAmount($0) }
                    ))
                    .font(.system(size: 42, weight: .bold, design: .rounded))
                    .foregroundColor((viewModel.showLimitError || viewModel.showZeroError) ? AppTheme.Colors.negative : AppTheme.Colors.dynamicText)
                    .keyboardType(.decimalPad)
                    .focused($isAmountFocused)
                    .multilineTextAlignment(.leading)
                    .frame(minWidth: 120)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(AppTheme.Colors.dynamicCardBackground)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(
                            (viewModel.showLimitError || viewModel.showZeroError)
                                ? AppTheme.Colors.negative
                                : (viewModel.parsedAmount > 0 ? viewModel.movementType.accentColor.opacity(0.4) : AppTheme.Colors.dynamicBorder),
                            lineWidth: 1.5
                        )
                )
                .shake(animatableData: viewModel.shakeAmount ? 1 : 0)
                
                // Form input error messages matching frontend StepAmount.vue
                VStack(alignment: .leading, spacing: 4) {
                    if viewModel.showNumericError {
                        InputError(message: "Sono consentiti solo numeri e un separatore decimale", type: .warning)
                    }
                    if viewModel.showDecimalError {
                        InputError(message: "Massimo 4 cifre decimali consentite", type: .warning)
                    }
                    if viewModel.showZeroError {
                        InputError(message: "L'importo deve essere maggiore di zero", type: .error)
                    }
                    if viewModel.showLimitError {
                        InputError(message: "Limite massimo di 10M superato!", type: .error)
                    }
                    
                    Text("Max: 10.000.000 €")
                        .font(.system(size: 11, weight: .regular))
                        .foregroundColor(AppTheme.Colors.dynamicSubtext)
                        .padding(.top, 1)
                }
                .padding(.horizontal, 4)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            // C. Category Selection (Dropdown Menu with Search Bar)
            VStack(alignment: .leading, spacing: 8) {
                Text("CATEGORIA")
                    .font(.system(size: 11, weight: .bold))
                    .tracking(1.5)
                    .foregroundColor(AppTheme.Colors.dynamicSubtext)
                
                VStack(spacing: 0) {
                    // Dropdown Trigger Header
                    Button(action: {
                        HapticHelper.light()
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            isCategoryDropdownOpen.toggle()
                            if isCategoryDropdownOpen {
                                isAmountFocused = false
                            }
                        }
                    }) {
                        HStack(spacing: 12) {
                            if let selected = viewModel.selectedCategory {
                                Circle()
                                    .fill(selected.displayColor)
                                    .frame(width: 14, height: 14)
                                Text(selected.nome)
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(AppTheme.Colors.dynamicText)
                            } else {
                                Circle()
                                    .fill(AppTheme.Colors.dynamicSubtext.opacity(0.3))
                                    .frame(width: 14, height: 14)
                                Text("Seleziona categoria")
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundColor(AppTheme.Colors.dynamicSubtext)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.down")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(AppTheme.Colors.dynamicSubtext)
                                .rotationEffect(.degrees(isCategoryDropdownOpen ? 180 : 0))
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                        .background(AppTheme.Colors.dynamicCardBackground)
                    }
                    .buttonStyle(.plain)
                    
                    // Collapsible Dropdown Content with Search Bar & Filtered List
                    if isCategoryDropdownOpen {
                        Divider()
                            .background(AppTheme.Colors.dynamicBorder)
                        
                        VStack(spacing: 10) {
                            // Search Bar
                            HStack(spacing: 8) {
                                Image(systemName: "magnifyingglass")
                                    .font(.system(size: 14))
                                    .foregroundColor(AppTheme.Colors.dynamicSubtext)
                                
                                TextField("Cerca categoria...", text: $categorySearchQuery)
                                    .font(.system(size: 14))
                                    .foregroundColor(AppTheme.Colors.dynamicText)
                                    .textInputAutocapitalization(.never)
                                    .disableAutocorrection(true)
                                
                                if !categorySearchQuery.isEmpty {
                                    Button(action: {
                                        HapticHelper.light()
                                        categorySearchQuery = ""
                                    }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .font(.system(size: 14))
                                            .foregroundColor(AppTheme.Colors.dynamicSubtext)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 9)
                            .background(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .fill(AppTheme.Colors.dynamicBackground)
                            )
                            
                            // Category Options List
                            if searchedCategories.isEmpty {
                                Text("Nessuna categoria trovata")
                                    .font(.system(size: 13))
                                    .foregroundColor(AppTheme.Colors.dynamicSubtext)
                                    .padding(.vertical, 16)
                                    .frame(maxWidth: .infinity)
                            } else {
                                ScrollView(.vertical, showsIndicators: true) {
                                    VStack(spacing: 2) {
                                        ForEach(searchedCategories) { cat in
                                            let isSelected = viewModel.selectedCategory?.id == cat.id
                                            Button(action: {
                                                HapticHelper.selection()
                                                withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                                                    viewModel.selectedCategory = cat
                                                    isCategoryDropdownOpen = false
                                                    categorySearchQuery = ""
                                                }
                                            }) {
                                                HStack(spacing: 12) {
                                                    Circle()
                                                        .fill(cat.displayColor)
                                                        .frame(width: 10, height: 10)
                                                    
                                                    Text(cat.nome)
                                                        .font(.system(size: 14, weight: isSelected ? .bold : .medium))
                                                        .foregroundColor(AppTheme.Colors.dynamicText)
                                                    
                                                    Spacer()
                                                    
                                                    if isSelected {
                                                        Image(systemName: "checkmark")
                                                            .font(.system(size: 12, weight: .bold))
                                                            .foregroundColor(cat.displayColor)
                                                    }
                                                }
                                                .padding(.horizontal, 12)
                                                .padding(.vertical, 10)
                                                .background(
                                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                                        .fill(isSelected ? cat.displayColor.opacity(0.12) : Color.clear)
                                                )
                                            }
                                            .buttonStyle(.plain)
                                        }
                                    }
                                    .padding(.vertical, 4)
                                }
                                .frame(maxHeight: 200)
                            }
                        }
                        .padding(12)
                        .background(AppTheme.Colors.dynamicCardBackground)
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(viewModel.showCategoryError ? AppTheme.Colors.negative : AppTheme.Colors.dynamicBorder.opacity(0.8), lineWidth: viewModel.showCategoryError ? 1.5 : 1)
                )
                
                if viewModel.showCategoryError {
                    InputError(message: "Seleziona una categoria", type: .error)
                        .padding(.horizontal, 4)
                }
            }
        }
    }
    
    // MARK: - 3. STEP 2: Date & Account
    
    private var step2DateAndAccount: some View {
        VStack(alignment: .leading, spacing: 24) {
            // A. Date
            VStack(alignment: .leading, spacing: 10) {
                Text("QUANDO?")
                    .font(.system(size: 11, weight: .bold))
                    .tracking(1.5)
                    .foregroundColor(AppTheme.Colors.dynamicSubtext)
                
                HStack(spacing: 8) {
                    // Option 1: Today
                    Button(action: {
                        HapticHelper.selection()
                        withAnimation {
                            viewModel.date = Date()
                            showCustomDatePicker = false
                        }
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "calendar")
                                .font(.system(size: 13))
                            Text("Oggi")
                                .font(.system(size: 14, weight: .semibold))
                        }
                        .foregroundColor(Calendar.current.isDateInToday(viewModel.date) && !showCustomDatePicker ? .white : AppTheme.Colors.dynamicText)
                        .padding(.vertical, 12)
                        .padding(.horizontal, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(Calendar.current.isDateInToday(viewModel.date) && !showCustomDatePicker ? AppTheme.Colors.primary : AppTheme.Colors.dynamicCardBackground)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(AppTheme.Colors.dynamicBorder.opacity(0.6), lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                    
                    // Option 2: Yesterday
                    Button(action: {
                        HapticHelper.selection()
                        if let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date()) {
                            withAnimation {
                                viewModel.date = yesterday
                                showCustomDatePicker = false
                            }
                        }
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "clock.arrow.circlepath")
                                .font(.system(size: 13))
                            Text("Ieri")
                                .font(.system(size: 14, weight: .semibold))
                        }
                        .foregroundColor(Calendar.current.isDateInYesterday(viewModel.date) && !showCustomDatePicker ? .white : AppTheme.Colors.dynamicText)
                        .padding(.vertical, 12)
                        .padding(.horizontal, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(Calendar.current.isDateInYesterday(viewModel.date) && !showCustomDatePicker ? AppTheme.Colors.primary : AppTheme.Colors.dynamicCardBackground)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(AppTheme.Colors.dynamicBorder.opacity(0.6), lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                    
                    // Option 3: Other date
                    Button(action: {
                        HapticHelper.selection()
                        withAnimation {
                            showCustomDatePicker.toggle()
                        }
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "calendar.badge.clock")
                                .font(.system(size: 13))
                            Text(showCustomDatePicker || (!Calendar.current.isDateInToday(viewModel.date) && !Calendar.current.isDateInYesterday(viewModel.date)) ? formattedShortDate(viewModel.date) : "Altra")
                                .font(.system(size: 14, weight: .semibold))
                        }
                        .foregroundColor(showCustomDatePicker || (!Calendar.current.isDateInToday(viewModel.date) && !Calendar.current.isDateInYesterday(viewModel.date)) ? .white : AppTheme.Colors.dynamicText)
                        .padding(.vertical, 12)
                        .padding(.horizontal, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(showCustomDatePicker || (!Calendar.current.isDateInToday(viewModel.date) && !Calendar.current.isDateInYesterday(viewModel.date)) ? AppTheme.Colors.primary : AppTheme.Colors.dynamicCardBackground)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(AppTheme.Colors.dynamicBorder.opacity(0.6), lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
                
                // Expanded graphical DatePicker when selected
                if showCustomDatePicker {
                    DatePicker(
                        "Seleziona data",
                        selection: $viewModel.date,
                        in: ...Date(),
                        displayedComponents: .date
                    )
                    .datePickerStyle(.graphical)
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(AppTheme.Colors.dynamicCardBackground)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(AppTheme.Colors.dynamicBorder.opacity(0.6), lineWidth: 1)
                    )
                }
                
                if viewModel.showFutureDateError {
                    InputError(message: "Non è possibile selezionare una data futura — impostata la data di oggi.", type: .error)
                        .padding(.horizontal, 4)
                }
            }
            
            // B. Account Selection
            VStack(alignment: .leading, spacing: 10) {
                Text("DA QUALE CONTO?")
                    .font(.system(size: 11, weight: .bold))
                    .tracking(1.5)
                    .foregroundColor(AppTheme.Colors.dynamicSubtext)
                
                if viewModel.availableAccounts.isEmpty {
                    Text("Nessun conto disponibile.")
                        .font(.system(size: 13))
                        .foregroundColor(AppTheme.Colors.dynamicSubtext)
                } else {
                    VStack(spacing: 8) {
                        ForEach(viewModel.availableAccounts) { acc in
                            let isSelected = viewModel.selectedAccount?.id == acc.id
                            Button(action: {
                                HapticHelper.selection()
                                withAnimation(.spring(response: 0.25, dampingFraction: 0.75)) {
                                    viewModel.selectedAccount = acc
                                }
                            }) {
                                HStack(spacing: 12) {
                                    ZStack {
                                        Circle()
                                            .fill(acc.displayColor.opacity(0.15))
                                            .frame(width: 38, height: 38)
                                        Image(systemName: acc.tipo == "contanti" ? "banknote" : "creditcard")
                                            .font(.system(size: 16))
                                            .foregroundColor(acc.displayColor)
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(acc.nome)
                                            .font(.system(size: 15, weight: .semibold))
                                            .foregroundColor(AppTheme.Colors.dynamicText)
                                        Text(acc.tipo == "contanti" ? "Contanti" : "Conto Corrente")
                                            .font(.system(size: 12))
                                            .foregroundColor(AppTheme.Colors.dynamicSubtext)
                                    }
                                    
                                    Spacer()
                                    
                                    if isSelected {
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.system(size: 20))
                                            .foregroundColor(viewModel.movementType.accentColor)
                                    }
                                }
                                .padding(.horizontal, 14)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .fill(isSelected ? viewModel.movementType.accentColor.opacity(0.08) : AppTheme.Colors.dynamicCardBackground)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .stroke(isSelected ? viewModel.movementType.accentColor : (viewModel.showAccountError ? AppTheme.Colors.negative : AppTheme.Colors.dynamicBorder.opacity(0.6)), lineWidth: isSelected ? 1.5 : 1)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                
                if viewModel.showAccountError {
                    InputError(message: "Seleziona un conto", type: .error)
                        .padding(.horizontal, 4)
                }
            }
        }
    }
    
    // MARK: - 4. STEP 3: Details & Confirmation
    
    private var step3DetailsAndConfirm: some View {
        VStack(alignment: .leading, spacing: 22) {
            // A. Summary Mini Card
            VStack(spacing: 14) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(viewModel.movementType.title.uppercased())
                            .font(.system(size: 10, weight: .bold))
                            .tracking(1.5)
                            .foregroundColor(viewModel.movementType.accentColor)
                        
                        Text("€ " + String(format: "%.2f", viewModel.parsedAmount))
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(AppTheme.Colors.dynamicText)
                    }
                    
                    Spacer()
                    
                    if let cat = viewModel.selectedCategory {
                        HStack(spacing: 6) {
                            Circle()
                                .fill(cat.displayColor)
                                .frame(width: 8, height: 8)
                            Text(cat.nome)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(AppTheme.Colors.dynamicText)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(cat.displayColor.opacity(0.12))
                        .clipShape(Capsule())
                    }
                }
                
                Divider()
                    .background(AppTheme.Colors.dynamicBorder)
                
                HStack {
                    if let acc = viewModel.selectedAccount {
                        HStack(spacing: 6) {
                            Image(systemName: acc.tipo == "contanti" ? "banknote" : "creditcard")
                                .font(.system(size: 12))
                                .foregroundColor(AppTheme.Colors.dynamicSubtext)
                            Text(acc.nome)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(AppTheme.Colors.dynamicText)
                        }
                    }
                    
                    Spacer()
                    
                    HStack(spacing: 6) {
                        Image(systemName: "calendar")
                            .font(.system(size: 12))
                            .foregroundColor(AppTheme.Colors.dynamicSubtext)
                        Text(formattedFullDate(viewModel.date))
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(AppTheme.Colors.dynamicText)
                    }
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(AppTheme.Colors.dynamicCardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(AppTheme.Colors.dynamicBorder.opacity(0.8), lineWidth: 1)
            )
            
            // B. Optional Title / Description with Smart Category Default
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("DESCRIZIONE (OPZIONALE)")
                        .font(.system(size: 11, weight: .bold))
                        .tracking(1.5)
                        .foregroundColor(AppTheme.Colors.dynamicSubtext)
                    
                    Spacer()
                    
                    Text("\(viewModel.customTitle.count)/50")
                        .font(.system(size: 11))
                        .foregroundColor(viewModel.customTitle.count >= 50 ? AppTheme.Colors.negative : AppTheme.Colors.dynamicSubtext)
                }
                
                TextField(viewModel.defaultTitle + " (da categoria)", text: $viewModel.customTitle)
                    .font(.system(size: 15))
                    .padding(14)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(AppTheme.Colors.dynamicCardBackground)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(AppTheme.Colors.dynamicBorder.opacity(0.6), lineWidth: 1)
                    )
                    .onChange(of: viewModel.customTitle) {
                        if viewModel.customTitle.count > 50 {
                            viewModel.customTitle = String(viewModel.customTitle.prefix(50))
                        }
                    }
            }
            
            // C. Optional Notes
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("NOTE (OPZIONALE)")
                        .font(.system(size: 11, weight: .bold))
                        .tracking(1.5)
                        .foregroundColor(AppTheme.Colors.dynamicSubtext)
                    
                    Spacer()
                    
                    Text("\(viewModel.notes.count)/200")
                        .font(.system(size: 11))
                        .foregroundColor(viewModel.notes.count >= 200 ? AppTheme.Colors.negative : AppTheme.Colors.dynamicSubtext)
                }
                
                TextEditor(text: $viewModel.notes)
                    .frame(height: 70)
                    .font(.system(size: 14))
                    .padding(8)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(AppTheme.Colors.dynamicCardBackground)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(AppTheme.Colors.dynamicBorder.opacity(0.6), lineWidth: 1)
                    )
                    .onChange(of: viewModel.notes) {
                        if viewModel.notes.count > 200 {
                            viewModel.notes = String(viewModel.notes.prefix(200))
                        }
                    }
            }
            
            // Server error message if present
            if let err = viewModel.errorMessage {
                Text(err)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(AppTheme.Colors.negative)
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(AppTheme.Colors.negative.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
        }
    }
    
    // MARK: - 5. Bottom Action Bar
    
    private var bottomActionBar: some View {
        VStack(spacing: 8) {
            Button(action: {
                HapticHelper.medium()
                if viewModel.currentStep < 3 {
                    viewModel.nextStep()
                } else {
                    viewModel.submitTransaction()
                }
            }) {
                HStack(spacing: 8) {
                    if viewModel.currentStep < 3 {
                        Text("Continua")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                    } else {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                        Text("Salva Movimento")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(isStepValid ? AppTheme.Colors.primary : AppTheme.Colors.dynamicSubtext.opacity(0.3))
                )
                .shadow(color: isStepValid ? AppTheme.Colors.primary.opacity(0.25) : Color.clear, radius: 10, y: 4)
            }
            .disabled(!isStepValid || viewModel.isSubmitting)
            .buttonStyle(.plain)
        }
    }
    
    // MARK: - Helpers
    
    private var isStepValid: Bool {
        switch viewModel.currentStep {
        case 1: return viewModel.isStep1Valid
        case 2: return viewModel.isStep2Valid
        case 3: return viewModel.canSubmit
        default: return false
        }
    }
    
    private var loadingPlaceholder: some View {
        VStack(spacing: 16) {
            Spacer(minLength: 50)
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: AppTheme.Colors.primary))
                .scaleEffect(1.3)
            Text("Caricamento opzioni...")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(AppTheme.Colors.dynamicSubtext)
            Spacer()
        }
    }
    
    private func formattedShortDate(_ d: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "it_IT")
        f.dateFormat = "d MMM"
        return f.string(from: d)
    }
    
    private func formattedFullDate(_ d: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "it_IT")
        f.dateStyle = .medium
        return f.string(from: d)
    }
    
    // MARK: - Success Overlay View
    
    private var successAnimationOverlay: some View {
        ZStack {
            // Blurred background backdrop
            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                // Animated badge with ripple pulse ring
                ZStack {
                    // Outer pulse ripple ring
                    Circle()
                        .stroke(AppTheme.Colors.willowGreen.opacity(pulseRingOpacity), lineWidth: 3)
                        .frame(width: 100, height: 100)
                        .scaleEffect(pulseRingScale)
                    
                    // Main circle badge with shadow
                    Circle()
                        .fill(AppTheme.Colors.willowGreen)
                        .frame(width: 88, height: 88)
                        .shadow(color: AppTheme.Colors.willowGreen.opacity(0.4), radius: 16, x: 0, y: 8)
                    
                    // Spring-bouncing checkmark
                    Image(systemName: "checkmark")
                        .font(.system(size: 40, weight: .bold))
                        .foregroundColor(AppTheme.Colors.inkBlack)
                        .scaleEffect(checkmarkScale)
                }
                
                VStack(spacing: 8) {
                    Text("Movimento Registrato!")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundColor(AppTheme.Colors.dynamicText)
                    
                    Text("€ \(String(format: "%.2f", viewModel.parsedAmount)) • \(viewModel.selectedCategory?.nome ?? "")")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(AppTheme.Colors.dynamicSubtext)
                }
            }
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(AppTheme.Colors.dynamicCardBackground)
                    .shadow(color: Color.black.opacity(0.12), radius: 24, x: 0, y: 12)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .stroke(AppTheme.Colors.dynamicBorder.opacity(0.6), lineWidth: 1)
            )
            .padding(.horizontal, 36)
            .scaleEffect(checkmarkScale > 0.5 ? 1.0 : 0.85)
            .animation(.spring(response: 0.4, dampingFraction: 0.75), value: checkmarkScale)
        }
    }
}

struct AddTransactionView_Previews: PreviewProvider {
    static var previews: some View {
        AddTransactionView()
    }
}
