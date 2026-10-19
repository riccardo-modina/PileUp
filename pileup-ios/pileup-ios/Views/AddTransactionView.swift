import SwiftUI

/// Fast guided wizard view for recording expenses and incomes.
/// Organized into 3 sequential steps with a top progress bar and smooth animated transitions.
/// Fully responsive in both Dark and Light mode using AppTheme.Colors tokens.
/// Strictly NO strange colored focus or selection borders.
struct AddTransactionView: View {
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var viewModel: AddTransactionViewModel
    
    // Discard confirmation alert for unsaved changes
    @State private var showDiscardAlert: Bool = false
    // Automatic focus on amount field in Step 1
    @FocusState private var isAmountFocused: Bool
    // Toggles inline calendar picker if user chooses a custom date
    @State private var showCustomDatePicker: Bool = false
    // Pending transactions debug sheet & store
    @ObservedObject private var pendingStore = PendingTransactionsStore.shared
    @State private var showPendingDebugSheet: Bool = false

    // Success animation overlay states
    @State private var showSuccessOverlay: Bool = false
    @State private var checkmarkScale: CGFloat = 0.2
    @State private var pulseRingScale: CGFloat = 0.8
    @State private var pulseRingOpacity: Double = 0.7
    // Tracks navigation direction for natural animated transitions (forward vs back swipe)
    @State private var isGoingBack: Bool = false
    
    init(masterKey: String? = nil) {
        _viewModel = StateObject(wrappedValue: AddTransactionViewModel(masterKey: masterKey))
    }
    
    private var stepTransition: AnyTransition {
        .asymmetric(
            insertion: .move(edge: isGoingBack ? .leading : .trailing).combined(with: .opacity),
            removal: .move(edge: isGoingBack ? .trailing : .leading).combined(with: .opacity)
        )
    }
    
    private func handleBack() {
        guard viewModel.currentStep > 1 else { return }
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        HapticHelper.light()
        isGoingBack = true
        viewModel.previousStep()
    }
    
    private func handleNext() {
        isGoingBack = false
        viewModel.nextStep()
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                AppTheme.Colors.formBackground
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
                                        .transition(stepTransition)
                                case 2:
                                    step2DateAndAccount
                                        .transition(stepTransition)
                                case 3:
                                    step3DetailsAndConfirm
                                        .transition(stepTransition)
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
                .simultaneousGesture(
                    DragGesture(minimumDistance: 25)
                        .onEnded { value in
                            let horizontal = value.translation.width
                            let vertical = value.translation.height
                            // Swipe from left to right: horizontal is positive and dominates vertical movement
                            if horizontal > 50 && horizontal > abs(vertical) * 1.3 {
                                handleBack()
                            }
                        }
                )
                
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
            .sheet(isPresented: $showPendingDebugSheet) {
                PendingTransactionsDebugView { selectedTx in
                    // Precompila il form con i dati del movimento selezionato
                    viewModel.updateAmount(String(format: "%.2f", selectedTx.amount))
                    viewModel.customTitle = selectedTx.title
                    viewModel.date = selectedTx.date
                    if let accId = selectedTx.accountId,
                       let acc = viewModel.availableAccounts.first(where: { $0.id == accId }) {
                        viewModel.selectedAccount = acc
                    }
                }
            }
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
        VStack(spacing: 14) {
            HStack(alignment: .center) {
                // Back button (visible starting from Step 2)
                if viewModel.currentStep > 1 {
                    Button(action: {
                        handleBack()
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 14, weight: .semibold))
                            Text("Indietro")
                                .font(.system(size: 14, weight: .medium))
                        }
                        .foregroundColor(AppTheme.Colors.dynamicSubtext)
                    }
                } else {
                    // Tasto debug per movimenti catturati da Intent / Wallet / SMS
                    Button(action: {
                        HapticHelper.light()
                        showPendingDebugSheet = true
                    }) {
                        HStack(spacing: 5) {
                            Image(systemName: "tray.full.fill")
                                .font(.system(size: 12))
                            if !pendingStore.pendingTransactions.isEmpty {
                                Text("\(pendingStore.pendingTransactions.count)")
                                    .font(.system(size: 11, weight: .bold))
                                    .padding(.horizontal, 5)
                                    .padding(.vertical, 1)
                                    .background(AppTheme.Colors.willowGreen)
                                    .foregroundColor(AppTheme.Colors.inkBlack)
                                    .clipShape(Capsule())
                            }
                        }
                        .foregroundColor(AppTheme.Colors.dynamicText)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(
                            Capsule().fill(AppTheme.Colors.dynamicCardBackground)
                        )
                        .overlay(
                            Capsule().stroke(AppTheme.Colors.dynamicBorder.opacity(0.5), lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
                
                Spacer()
                
                // Step counter label
                Text("Passo \(viewModel.currentStep) di 3")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(AppTheme.Colors.dynamicSubtext)
                    .textCase(.uppercase)
                    .tracking(1.5)
                
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
                    Image(systemName: "xmark")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(AppTheme.Colors.dynamicSubtext)
                        .frame(width: 32, height: 32)
                        .background(Circle().fill(AppTheme.Colors.dynamicBorder.opacity(0.4)))
                }
            }
            
            // Smooth progress indicator
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(AppTheme.Colors.dynamicBorder.opacity(0.5))
                        .frame(height: 4)
                    
                    Capsule()
                        .fill(AppTheme.Colors.dynamicText)
                        .frame(width: geometry.size.width * CGFloat(viewModel.progress), height: 4)
                        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: viewModel.progress)
                }
            }
            .frame(height: 4)
        }
    }
    
    // MARK: - 2. STEP 1: Type, Category & Amount
    
    private var step1CategoryAndAmount: some View {
        VStack(alignment: .leading, spacing: 22) {
            // Screen Title & Subtitle (clean modern typography, adapting to light/dark)
            VStack(alignment: .leading, spacing: 6) {
                Text("Nuovo movimento")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundColor(AppTheme.Colors.dynamicText)
                
                Text("Seleziona la tipologia, inserisci l'importo e assegna una categoria.")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(AppTheme.Colors.dynamicSubtext)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.bottom, 4)
            
            // Banner movimenti in sospeso se presenti
            if !pendingStore.pendingTransactions.isEmpty {
                Button(action: {
                    HapticHelper.light()
                    showPendingDebugSheet = true
                }) {
                    HStack(spacing: 10) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(AppTheme.Colors.dynamicPrimary)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(pendingStore.pendingTransactions.count) movimento da confermare")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(AppTheme.Colors.dynamicText)
                            Text("Tocca per esaminare e precompilare il form")
                                .font(.system(size: 11))
                                .foregroundColor(AppTheme.Colors.dynamicSubtext)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(AppTheme.Colors.dynamicSubtext)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(AppTheme.Colors.dynamicCardBackground)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(AppTheme.Colors.dynamicPrimary.opacity(0.35), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
            }
            
            // A. Segmented Pill for Movement Type (clean pills without strange colored strokes)
            HStack(spacing: 8) {
                ForEach(MovementType.allCases) { type in
                    let isSelected = viewModel.movementType == type
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
                        .foregroundColor(isSelected ? AppTheme.Colors.dynamicText : AppTheme.Colors.dynamicSubtext)
                        .padding(.vertical, 10)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(isSelected ? AppTheme.Colors.formCardActive : AppTheme.Colors.dynamicCardBackground)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(AppTheme.Colors.dynamicBorder.opacity(0.5), lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            
            // B. Hero Amount Input (matching the prefix badge + input look in the screenshot)
            VStack(alignment: .leading, spacing: 6) {
                Text("IMPORTO")
                    .font(.system(size: 11, weight: .bold))
                    .tracking(1.5)
                    .foregroundColor(AppTheme.Colors.dynamicSubtext)
                
                HStack(spacing: 10) {
                    // Currency badge (resembling the country flag container in the screenshot)
                    HStack(spacing: 6) {
                        Text("EUR")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundColor(AppTheme.Colors.dynamicText)
                        Text("€")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(AppTheme.Colors.dynamicSubtext)
                    }
                    .padding(.horizontal, 14)
                    .frame(height: 58)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(AppTheme.Colors.dynamicCardBackground)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(AppTheme.Colors.dynamicBorder.opacity(0.5), lineWidth: 1)
                    )
                    
                    // Amount TextField container (clean box, no strange colored border on focus)
                    HStack(spacing: 8) {
                        TextField("0,00", text: Binding(
                            get: { viewModel.amountString },
                            set: { viewModel.updateAmount($0) }
                        ))
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .foregroundColor(AppTheme.Colors.dynamicText)
                        .keyboardType(.decimalPad)
                        .focused($isAmountFocused)
                        .multilineTextAlignment(.leading)
                        
                        if !viewModel.amountString.isEmpty {
                            Button(action: {
                                HapticHelper.light()
                                viewModel.amountString = ""
                                viewModel.updateAmount("")
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 16))
                                    .foregroundColor(AppTheme.Colors.dynamicSubtext)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 16)
                    .frame(height: 58)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(AppTheme.Colors.dynamicCardBackground)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(AppTheme.Colors.dynamicBorder.opacity(0.5), lineWidth: 1)
                    )
                }
                .shake(animatableData: viewModel.shakeAmount ? 1 : 0)
                
                // Form input error messages
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
                    
                    Text("Massimo consentito: 10.000.000 €")
                        .font(.system(size: 11, weight: .regular))
                        .foregroundColor(AppTheme.Colors.dynamicSubtext.opacity(0.7))
                        .padding(.top, 1)
                }
                .padding(.horizontal, 4)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            // C. Category Selection
            CategoryPickerField(
                title: "CATEGORIA",
                placeholder: "Seleziona categoria",
                items: viewModel.filteredCategories.map { CategoryPickerItem(category: $0) },
                selectedId: Binding(
                    get: { viewModel.selectedCategory?.id },
                    set: { newId in
                        if let newId = newId {
                            viewModel.selectedCategory = viewModel.filteredCategories.first(where: { $0.id == newId })
                        } else {
                            viewModel.selectedCategory = nil
                        }
                    }
                ),
                showAllOption: false,
                allowClear: false,
                showError: viewModel.showCategoryError,
                errorMessage: "Seleziona una categoria",
                customBackgroundColor: AppTheme.Colors.dynamicCardBackground,
                customBorderColor: AppTheme.Colors.dynamicBorder.opacity(0.5),
                onTap: {
                    isAmountFocused = false
                }
            )
        }
    }
    
    // MARK: - 3. STEP 2: Date & Account
    
    private var step2DateAndAccount: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Screen Title & Subtitle
            VStack(alignment: .leading, spacing: 6) {
                Text("Quando e dove")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundColor(AppTheme.Colors.dynamicText)
                
                Text("Indica la data del movimento e il conto di riferimento.")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(AppTheme.Colors.dynamicSubtext)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.bottom, 4)
            
            // A. Date
            VStack(alignment: .leading, spacing: 10) {
                Text("QUANDO?")
                    .font(.system(size: 11, weight: .bold))
                    .tracking(1.5)
                    .foregroundColor(AppTheme.Colors.dynamicSubtext)
                
                HStack(spacing: 8) {
                    // Option 1: Today
                    let isToday = Calendar.current.isDateInToday(viewModel.date) && !showCustomDatePicker
                    Button(action: {
                        HapticHelper.selection()
                        withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
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
                        .foregroundColor(isToday ? AppTheme.Colors.dynamicText : AppTheme.Colors.dynamicSubtext)
                        .padding(.vertical, 12)
                        .padding(.horizontal, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(isToday ? AppTheme.Colors.formCardActive : AppTheme.Colors.dynamicCardBackground)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(AppTheme.Colors.dynamicBorder.opacity(0.5), lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                    
                    // Option 2: Yesterday
                    let isYesterday = Calendar.current.isDateInYesterday(viewModel.date) && !showCustomDatePicker
                    Button(action: {
                        HapticHelper.selection()
                        if let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date()) {
                            withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
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
                        .foregroundColor(isYesterday ? AppTheme.Colors.dynamicText : AppTheme.Colors.dynamicSubtext)
                        .padding(.vertical, 12)
                        .padding(.horizontal, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(isYesterday ? AppTheme.Colors.formCardActive : AppTheme.Colors.dynamicCardBackground)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(AppTheme.Colors.dynamicBorder.opacity(0.5), lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                    
                    // Option 3: Other date
                    let isOther = showCustomDatePicker || (!Calendar.current.isDateInToday(viewModel.date) && !Calendar.current.isDateInYesterday(viewModel.date))
                    Button(action: {
                        HapticHelper.selection()
                        withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                            showCustomDatePicker.toggle()
                        }
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "calendar.badge.clock")
                                .font(.system(size: 13))
                            Text(isOther ? formattedShortDate(viewModel.date) : "Altra")
                                .font(.system(size: 14, weight: .semibold))
                        }
                        .foregroundColor(isOther ? AppTheme.Colors.dynamicText : AppTheme.Colors.dynamicSubtext)
                        .padding(.vertical, 12)
                        .padding(.horizontal, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(isOther ? AppTheme.Colors.formCardActive : AppTheme.Colors.dynamicCardBackground)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(AppTheme.Colors.dynamicBorder.opacity(0.5), lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
                
                // Expanded graphical DatePicker when selected (adapts to light/dark automatically)
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
                            .stroke(AppTheme.Colors.dynamicBorder.opacity(0.5), lineWidth: 1)
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
                                HStack(spacing: 14) {
                                    ZStack {
                                        Circle()
                                            .fill(acc.displayColor.opacity(0.18))
                                            .frame(width: 40, height: 40)
                                        Image(systemName: acc.tipo == "contanti" ? "banknote" : "creditcard")
                                            .font(.system(size: 16))
                                            .foregroundColor(acc.displayColor)
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 3) {
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
                                            .foregroundColor(AppTheme.Colors.dynamicText)
                                    }
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 14)
                                .background(
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .fill(isSelected ? AppTheme.Colors.formCardActive : AppTheme.Colors.dynamicCardBackground)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .stroke(AppTheme.Colors.dynamicBorder.opacity(0.5), lineWidth: 1)
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
            // Screen Title & Subtitle
            VStack(alignment: .leading, spacing: 6) {
                Text("Riepilogo e dettagli")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundColor(AppTheme.Colors.dynamicText)
                
                Text("Verifica i dati del movimento e aggiungi note opzionali.")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(AppTheme.Colors.dynamicSubtext)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.bottom, 4)
            
            // A. Summary Mini Card
            VStack(spacing: 14) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(viewModel.movementType.title.uppercased())
                            .font(.system(size: 11, weight: .bold))
                            .tracking(1.5)
                            .foregroundColor(viewModel.movementType.accentColor)
                        
                        Text("€ " + String(format: "%.2f", viewModel.parsedAmount))
                            .font(.system(size: 30, weight: .bold, design: .rounded))
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
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(AppTheme.Colors.formCardActive)
                        .clipShape(Capsule())
                        .overlay(
                            Capsule().stroke(AppTheme.Colors.dynamicBorder.opacity(0.5), lineWidth: 1)
                        )
                    }
                }
                
                Divider()
                    .background(AppTheme.Colors.dynamicBorder.opacity(0.5))
                
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
            .padding(18)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(AppTheme.Colors.dynamicCardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(AppTheme.Colors.dynamicBorder.opacity(0.5), lineWidth: 1)
            )
            
            // B. Optional Title / Description
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
                    .foregroundColor(AppTheme.Colors.dynamicText)
                    .padding(14)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(AppTheme.Colors.dynamicCardBackground)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(AppTheme.Colors.dynamicBorder.opacity(0.5), lineWidth: 1)
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
                    .scrollContentBackground(.hidden)
                    .frame(height: 75)
                    .font(.system(size: 14))
                    .foregroundColor(AppTheme.Colors.dynamicText)
                    .padding(10)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(AppTheme.Colors.dynamicCardBackground)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(AppTheme.Colors.dynamicBorder.opacity(0.5), lineWidth: 1)
                    )
                    .onChange(of: viewModel.notes) {
                        if viewModel.notes.count > 200 {
                            viewModel.notes = String(viewModel.notes.prefix(200))
                        }
                    }
            }
            
            // Server error message if present
            if let err = viewModel.errorMessage {
                ErrorBanner(message: err)
            }
        }
    }
    
    // MARK: - 5. Bottom Action Bar (matching the Revolut button, responsive to dark & light mode)
    
    private var bottomActionBar: some View {
        VStack(spacing: 8) {
            Button(action: {
                HapticHelper.medium()
                if viewModel.currentStep < 3 {
                    handleNext()
                } else {
                    viewModel.submitTransaction()
                }
            }) {
                HStack(spacing: 8) {
                    if viewModel.isSubmitting {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: isStepValid ? AppTheme.Colors.buttonActiveText : AppTheme.Colors.dynamicSubtext))
                    } else if viewModel.currentStep < 3 {
                        Text("Continua")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(isStepValid ? AppTheme.Colors.buttonActiveText : AppTheme.Colors.dynamicSubtext)
                    } else {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 17, weight: .bold))
                            .foregroundColor(isStepValid ? AppTheme.Colors.buttonActiveText : AppTheme.Colors.dynamicSubtext)
                        Text("Salva Movimento")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(isStepValid ? AppTheme.Colors.buttonActiveText : AppTheme.Colors.dynamicSubtext)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(
                    Capsule()
                        .fill(isStepValid ? AppTheme.Colors.buttonActiveBackground : AppTheme.Colors.buttonDisabledBackground)
                )
                .shadow(color: isStepValid ? AppTheme.Colors.buttonActiveBackground.opacity(0.12) : Color.clear, radius: 10, y: 3)
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
                .progressViewStyle(CircularProgressViewStyle(tint: AppTheme.Colors.dynamicText))
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
            AppTheme.Colors.dynamicBackground.opacity(0.85)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                // Animated badge with ripple pulse ring
                ZStack {
                    Circle()
                        .stroke(AppTheme.Colors.willowGreen.opacity(pulseRingOpacity), lineWidth: 3)
                        .frame(width: 100, height: 100)
                        .scaleEffect(pulseRingScale)
                    
                    Circle()
                        .fill(AppTheme.Colors.willowGreen)
                        .frame(width: 88, height: 88)
                        .shadow(color: AppTheme.Colors.willowGreen.opacity(0.4), radius: 16, x: 0, y: 8)
                    
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
                    .shadow(color: Color.black.opacity(0.15), radius: 24, x: 0, y: 12)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .stroke(AppTheme.Colors.dynamicBorder.opacity(0.5), lineWidth: 1)
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
