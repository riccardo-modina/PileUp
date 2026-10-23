import SwiftUI

/// Native detail screen for Income/Expense with built-in Swift Charts donut,
/// category quick-filters, and the list of decrypted movements.
struct CashFlowDetailView: View {
    @Environment(\.presentationMode) var presentationMode
    @Binding var period: DataPeriod
    @StateObject var viewModel: CashFlowDetailViewModel
    var onBack: (() -> Void)? = nil
    
    @State private var itemToDelete: MovementItem? = nil
    @State private var showDeleteConfirmation: Bool = false
    @State private var selectedMovementForDetail: MovementItem? = nil
    @State private var dragOffset: CGFloat = 0
    
    init(
        movementType: MovementType,
        period: Binding<DataPeriod>,
        onBack: (() -> Void)? = nil
    ) {
        self._period = period
        self.onBack = onBack
        
        let initialPeriod = period.wrappedValue
        _viewModel = StateObject(
            wrappedValue: CashFlowDetailViewModel(
                movementType: movementType,
                period: initialPeriod,
                onPeriodChanged: { newPeriod in
                    period.wrappedValue = newPeriod
                }
            )
        )
    }
    
    var body: some View {
        ZStack {
            AppTheme.Colors.dynamicBackground
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                headerBar
                
                if let err = viewModel.errorMessage {
                    ErrorBanner(message: err)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 6)
                }
                
                if viewModel.isLoading && viewModel.movements.isEmpty {
                    loadingView
                } else {
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(spacing: 16) {
                            chartAndPeriodSection
                            
                            if !viewModel.pieSlices.isEmpty {
                                categoryDropdownSection
                            }
                            
                            movementsSection
                            
                            Spacer(minLength: 120)
                        }
                        .padding(.top, 6)
                    }
                    .refreshable {
                        viewModel.loadData(reset: true)
                    }
                }
            }
            
            // Custom confirmation sheet for delete
            if showDeleteConfirmation, let item = itemToDelete {
                ConfirmationBottomSheet(
                    icon: "trash.fill",
                    iconColor: AppTheme.Colors.negative,
                    iconBackgroundColor: AppTheme.Colors.negative.opacity(0.12),
                    title: "Elimina Movimento",
                    message: "Sei sicuro di voler eliminare '\(item.titolo)', \(item.formattedAmount)? Questa azione non può essere annullata.",
                    confirmTitle: "Elimina",
                    isDestructive: true,
                    isLoading: false,
                    onConfirm: {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            showDeleteConfirmation = false
                        }
                        Task { await viewModel.deleteMovement(item) }
                    },
                    cancelTitle: "Annulla",
                    onCancel: {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            showDeleteConfirmation = false
                        }
                    }
                )
            }
        }
        .simultaneousGesture(
            DragGesture(minimumDistance: 15)
                .onEnded { value in
                    // Screen dismissal on swipe from left to right (sx -> dx)
                    if (value.startLocation.x < 70 && value.translation.width > 45) && abs(value.translation.height) < 90 {
                        HapticHelper.light()
                        if let onBack = onBack {
                            onBack()
                        } else {
                            presentationMode.wrappedValue.dismiss()
                        }
                    }
                }
        )
        .onAppear {
            viewModel.loadData(reset: true)
        }
        .onChange(of: period) {
            if viewModel.period != period {
                viewModel.period = period
            }
        }
        .sheet(item: $selectedMovementForDetail) { item in
            MovementDetailView(
                movement: item,
                onUpdated: {
                    viewModel.loadData(reset: true)
                },
                onDeleted: {
                    viewModel.loadData(reset: true)
                }
            )
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("TransactionsUpdated"))) { _ in
            viewModel.loadData(reset: true)
        }
    }
    
    // MARK: - Header Bar
    
    private var headerBar: some View {
        HStack {
            Button(action: {
                HapticHelper.light()
                if let onBack = onBack {
                    onBack()
                } else {
                    presentationMode.wrappedValue.dismiss()
                }
            }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(AppTheme.Colors.dynamicText)
                    .frame(width: 38, height: 38)
                    .background(Circle().fill(AppTheme.Colors.dynamicCardBackground).shadow(color: Color.black.opacity(0.04), radius: 4, x: 0, y: 2))
                    .overlay(Circle().stroke(AppTheme.Colors.dynamicBorder.opacity(0.6), lineWidth: 1))
            }
            .buttonStyle(.plain)
            
            Spacer()
            
            Text(viewModel.viewTitle)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(AppTheme.Colors.dynamicText)
            
            Spacer()
            
            PeriodSelectorChip(selectedPeriod: $viewModel.period)
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 12)
    }
    
    // MARK: - Chart & Period Section (Directly on background)
    
    private var chartAndPeriodSection: some View {
        VStack(spacing: 12) {
            // Period Navigation (< SET 2026 >)
            HStack {
                Button(action: {
                    HapticHelper.light()
                    withAnimation(.easeInOut(duration: 0.25)) { viewModel.previousPeriod() }
                }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(AppTheme.Colors.dynamicText)
                        .frame(width: 36, height: 36)
                        .background(
                            Circle()
                                .fill(AppTheme.Colors.dynamicCardBackground)
                                .shadow(color: Color.black.opacity(0.04), radius: 4, x: 0, y: 1)
                        )
                        .overlay(
                            Circle()
                                .stroke(AppTheme.Colors.dynamicBorder.opacity(0.6), lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
                .disabled(viewModel.period.isTotal)
                .opacity(viewModel.period.isTotal ? 0.3 : 1)
                
                Spacer()
                
                Text(viewModel.periodFormattedString.uppercased())
                    .font(.system(size: 14, weight: .bold))
                    .tracking(1.5)
                    .foregroundColor(AppTheme.Colors.dynamicText)
                
                Spacer()
                
                Button(action: {
                    HapticHelper.light()
                    withAnimation(.easeInOut(duration: 0.25)) { viewModel.nextPeriod() }
                }) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(AppTheme.Colors.dynamicText)
                        .frame(width: 36, height: 36)
                        .background(
                            Circle()
                                .fill(AppTheme.Colors.dynamicCardBackground)
                                .shadow(color: Color.black.opacity(0.04), radius: 4, x: 0, y: 1)
                        )
                        .overlay(
                            Circle()
                                .stroke(AppTheme.Colors.dynamicBorder.opacity(0.6), lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
                .disabled(!viewModel.period.canMoveForward())
                .opacity(!viewModel.period.canMoveForward() ? 0.3 : 1)
            }
            .padding(.horizontal, 20)
            
            // Enlarged Pie Chart directly on background with swipe animation
            CategoryPieChart(
                slices: viewModel.pieSlices,
                totalAmount: viewModel.periodTotal,
                title: viewModel.movementType == .income ? "Totale Entrate" : "Totale Spese",
                selectedCategoryId: $viewModel.selectedCategoryId
            )
            .padding(.vertical, 4)
            .offset(x: dragOffset)
            .scaleEffect(1.0 - min(abs(dragOffset) / 800.0, 0.08))
            .opacity(1.0 - min(Double(abs(dragOffset)) / 220.0, 0.35))
            .animation(.spring(response: 0.35, dampingFraction: 0.8), value: dragOffset == 0)
            .id(viewModel.periodFormattedString)
            .transition(.asymmetric(
                insertion: .scale(scale: 0.94).combined(with: .opacity),
                removal: .scale(scale: 1.04).combined(with: .opacity)
            ))
        }
        .contentShape(Rectangle())
        .highPriorityGesture(
            DragGesture(minimumDistance: 15)
                .onChanged { value in
                    if abs(value.translation.width) > abs(value.translation.height) {
                        dragOffset = value.translation.width * 0.45
                    }
                }
                .onEnded { value in
                    let translation = value.translation.width
                    let isHorizontal = abs(translation) > abs(value.translation.height)
                    
                    if isHorizontal && translation < -35 && viewModel.period.canMoveForward() {
                        // Swipe Left -> Next Period
                        HapticHelper.light()
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
                            dragOffset = 0
                            viewModel.nextPeriod()
                        }
                    } else if isHorizontal && translation > 35 && !viewModel.period.isTotal {
                        // Swipe Right -> Previous Period
                        HapticHelper.light()
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
                            dragOffset = 0
                            viewModel.previousPeriod()
                        }
                    } else {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                            dragOffset = 0
                        }
                    }
                }
        )
    }
    

    
    // MARK: - Category Dropdown Section (Reusable Component)
    
    private var categoryDropdownSection: some View {
        CategoryPickerField(
            title: "Filtra per categoria",
            items: viewModel.pieSlices.map { CategoryPickerItem(slice: $0) },
            selectedId: $viewModel.selectedCategoryId,
            showAllOption: true,
            allOptionLabel: "Tutti i movimenti"
        )
        .id(viewModel.periodFormattedString)
        .padding(.horizontal, 20)
    }
    
    // MARK: - Movements Section
    
    private var movementsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("MOVIMENTI")
                    .font(.system(size: 12, weight: .bold))
                    .tracking(1.2)
                    .foregroundColor(AppTheme.Colors.dynamicSubtext)
                
                Spacer()
                
                if viewModel.selectedCategoryId != nil {
                    Button(action: {
                        withAnimation { viewModel.selectedCategoryId = nil }
                    }) {
                        Text("Rimuovi filtro")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(AppTheme.Colors.primary)
                    }
                }
            }
            .padding(.horizontal, 22)
            
            if viewModel.filteredMovements.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "tray")
                        .font(.system(size: 36))
                        .foregroundColor(AppTheme.Colors.dynamicSubtext.opacity(0.5))
                        .padding(.top, 24)
                    Text("Nessun movimento trovato")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(AppTheme.Colors.dynamicSubtext)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 30)
            } else {
                VStack(spacing: 0) {
                    LazyVStack(spacing: 0) {
                        ForEach(Array(viewModel.filteredMovements.enumerated()), id: \.element.id) { index, item in
                            VStack(spacing: 0) {
                                movementRow(item)
                                    .onAppear {
                                        if item.id == viewModel.filteredMovements.last?.id {
                                            viewModel.loadMoreMovements()
                                        }
                                    }
                                
                                if index < viewModel.filteredMovements.count - 1 {
                                    Divider()
                                        .background(AppTheme.Colors.dynamicBorder.opacity(0.5))
                                        .padding(.horizontal, 16)
                                }
                            }
                        }
                        
                        if viewModel.isLoadingMore {
                            HStack {
                                Spacer()
                                ProgressView()
                                    .scaleEffect(0.9)
                                    .padding(.vertical, 14)
                                Spacer()
                            }
                        }
                    }
                }
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(AppTheme.Colors.dynamicCardBackground)
                        .shadow(color: Color.black.opacity(0.02), radius: 6, x: 0, y: 2)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(AppTheme.Colors.dynamicBorder.opacity(0.5), lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .padding(.horizontal, 20)
            }
        }
    }
    
    // MARK: - Movement Row
    
    private func movementSubtitle(for item: MovementItem) -> String {
        let account = item.conto?.nome ?? "Conto"
        if let desc = item.descrizione?.trimmingCharacters(in: .whitespacesAndNewlines), !desc.isEmpty {
            return "\(account) • \(desc)"
        }
        return account
    }
    
    private func movementRow(_ item: MovementItem) -> some View {
        Button(action: {
            HapticHelper.light()
            selectedMovementForDetail = item
        }) {
            VStack(alignment: .leading, spacing: 5) {
                // Line 1: Title (Bold, prominent)
                Text(item.titolo.isEmpty ? item.categoryName : item.titolo)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(AppTheme.Colors.dynamicText)
                    .lineLimit(1)
                
                // Line 2: Subtitle (Account • Description)
                Text(movementSubtitle(for: item))
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(AppTheme.Colors.dynamicSubtext)
                    .lineLimit(1)
                
                // Line 3: Category dot + Category name · Date on Left, Amount on Right
                HStack(alignment: .center, spacing: 6) {
                    Circle()
                        .fill(item.categoryDisplayColor)
                        .frame(width: 8, height: 8)
                    
                    Text(item.categoryName)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(AppTheme.Colors.dynamicText.opacity(0.85))
                        .lineLimit(1)
                    
                    Text("·")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(AppTheme.Colors.dynamicSubtext.opacity(0.6))
                    
                    Text(formatMovementDate(item.data))
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(AppTheme.Colors.dynamicSubtext)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    Text("\(item.isIncome ? "+" : "-") \(item.formattedAmount)")
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundColor(item.isIncome ? AppTheme.Colors.moneyIn : AppTheme.Colors.dynamicText)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .contentShape(Rectangle())
        }
        .buttonStyle(MovementRowButtonStyle())
        .contextMenu {
            Button(role: .destructive, action: {
                itemToDelete = item
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    showDeleteConfirmation = true
                }
            }) {
                Label("Elimina Movimento", systemImage: "trash")
            }
        }
    }
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView().scaleEffect(1.2)
            Text("Caricamento movimenti...")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(AppTheme.Colors.dynamicSubtext)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func formatMovementDate(_ raw: String) -> String {
        let inFormatter = DateFormatter()
        inFormatter.dateFormat = "yyyy-MM-dd"
        inFormatter.locale = Locale(identifier: "en_US_POSIX")
        guard let date = inFormatter.date(from: raw) else { return raw }
        
        let outFormatter = DateFormatter()
        outFormatter.locale = Locale(identifier: "it_IT")
        outFormatter.dateFormat = "d MMM yyyy"
        return outFormatter.string(from: date)
    }
    
    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "€"
        formatter.locale = Locale(identifier: "it_IT")
        return formatter.string(from: NSNumber(value: value)) ?? String(format: "€ %.2f", value)
    }
}

/// Subtle press animation providing clear tactile/visual feedback on card taps in the unified list.
struct MovementRowButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(configuration.isPressed ? AppTheme.Colors.dynamicText.opacity(0.04) : Color.clear)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

