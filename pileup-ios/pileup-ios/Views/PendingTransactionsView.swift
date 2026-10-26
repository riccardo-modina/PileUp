import SwiftUI

/// View to review, confirm, or discard transactions received from Apple Wallet and Bank Shortcuts.
struct PendingTransactionsView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject private var store = PendingTransactionsStore.shared
    
    // Callback to populate the AddTransactionView form with a selected pending transaction
    var onSelectTransaction: ((PendingWalletTransactionModel) -> Void)? = nil
    
    @State private var showClearConfirmation: Bool = false
    @State private var transactionToDelete: PendingWalletTransactionModel? = nil
    
    var body: some View {
        NavigationView {
            ZStack {
                AppTheme.Colors.dynamicBackground
                    .ignoresSafeArea()
                
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 20) {
                        // 1. Info / Status Header
                        headerInfoCard
                        
                        // 2. Pending Transactions List
                        pendingTransactionsSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 36)
                }
            }
            .navigationTitle("Movimenti da confermare")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if !store.pendingTransactions.isEmpty {
                        Button("Svuota") {
                            HapticHelper.warning()
                            showClearConfirmation = true
                        }
                        .foregroundColor(AppTheme.Colors.negative)
                        .font(.system(size: 14, weight: .medium))
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Chiudi") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(AppTheme.Colors.dynamicText)
                    .font(.system(size: 15, weight: .semibold))
                }
            }
            .alert(isPresented: $showClearConfirmation) {
                Alert(
                    title: Text("Svuota movimenti"),
                    message: Text("Vuoi davvero eliminare tutti i movimenti in attesa di conferma?"),
                    primaryButton: .destructive(Text("Svuota")) {
                        HapticHelper.warning()
                        store.clearAll()
                    },
                    secondaryButton: .cancel(Text("Annulla"))
                )
            }
            .alert(item: $transactionToDelete) { tx in
                Alert(
                    title: Text("Elimina movimento"),
                    message: Text("Vuoi eliminare \"\(tx.title)\" di \(String(format: "%.2f €", tx.amount)) dalla coda?"),
                    primaryButton: .destructive(Text("Elimina")) {
                        HapticHelper.warning()
                        store.removeTransaction(id: tx.id)
                    },
                    secondaryButton: .cancel(Text("Annulla"))
                )
            }
        }
    }
    
    // MARK: - 1. Info Header
    
    private var headerInfoCard: some View {
        HStack(spacing: 14) {
            Image(systemName: "tray.full.fill")
                .font(.system(size: 22))
                .foregroundColor(AppTheme.Colors.dynamicPrimary)
                .frame(width: 44, height: 44)
                .background(Circle().fill(AppTheme.Colors.dynamicPrimary.opacity(0.15)))
            
            VStack(alignment: .leading, spacing: 3) {
                Text("\(store.pendingTransactions.count) movimenti in coda")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(AppTheme.Colors.dynamicText)
            }
            
            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(AppTheme.Colors.dynamicCardBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(AppTheme.Colors.dynamicBorder.opacity(0.5), lineWidth: 1)
        )
    }
    
    // MARK: - 2. Pending List
    
    private var pendingTransactionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("LISTA MOVIMENTI CATTURATI")
                .font(.system(size: 11, weight: .bold))
                .tracking(1.5)
                .foregroundColor(AppTheme.Colors.dynamicSubtext)
            
            if store.pendingTransactions.isEmpty {
                VStack(spacing: 14) {
                    Image(systemName: "tray")
                        .font(.system(size: 42))
                        .foregroundColor(AppTheme.Colors.dynamicSubtext.opacity(0.5))
                    
                    Text("Nessun movimento in sospeso")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(AppTheme.Colors.dynamicText)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 44)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(AppTheme.Colors.dynamicCardBackground)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(AppTheme.Colors.dynamicBorder.opacity(0.4), lineWidth: 1)
                )
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(store.pendingTransactions.enumerated()), id: \.element.id) { index, tx in
                        VStack(spacing: 0) {
                            transactionCard(tx)
                            
                            if index < store.pendingTransactions.count - 1 {
                                Divider()
                                    .background(AppTheme.Colors.dynamicBorder.opacity(0.5))
                                    .padding(.horizontal, 16)
                            }
                        }
                    }
                }
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(AppTheme.Colors.dynamicCardBackground)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(AppTheme.Colors.dynamicBorder.opacity(0.5), lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
        }
    }
    
    private func transactionCard(_ tx: PendingWalletTransactionModel) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            // Line 1: Title (Bold)
            Text(tx.title)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(AppTheme.Colors.dynamicText)
                .lineLimit(1)
            
            // Line 2: Account or Subtitle (Subtext)
            HStack(spacing: 4) {
                if let accId = tx.accountId {
                    Image(systemName: "creditcard")
                        .font(.system(size: 11))
                    Text("Conto ID: \(accId)")
                        .font(.system(size: 13, weight: .regular))
                } else {
                    Text("Nessun conto abbinato")
                        .font(.system(size: 13, weight: .regular))
                }
            }
            .foregroundColor(AppTheme.Colors.dynamicSubtext)
            .lineLimit(1)
            
            // Line 3: Date & Amount on left, Actions lowered and widened on right
            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(formattedDate(tx.date))
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(AppTheme.Colors.dynamicSubtext)
                    
                    Text(String(format: "%.2f €", tx.amount))
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundColor(AppTheme.Colors.dynamicPrimary)
                }
                
                Spacer()
                
                // Actions (Trash + Conferma)
                HStack(spacing: 10) {
                    // Discard with confirmation
                    Button(action: {
                        HapticHelper.light()
                        transactionToDelete = tx
                    }) {
                        Image(systemName: "trash")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(AppTheme.Colors.negative)
                            .frame(width: 36, height: 36)
                            .background(Circle().fill(AppTheme.Colors.negative.opacity(0.12)))
                    }
                    .buttonStyle(.plain)
                    
                    // Confirm & Apply (stessa altezza di 36pt del cestino e testo forzato su singola riga)
                    Button(action: {
                        HapticHelper.success()
                        onSelectTransaction?(tx)
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 13, weight: .semibold))
                            Text("Conferma")
                                .font(.system(size: 13, weight: .bold))
                                .lineLimit(1)
                                .layoutPriority(1)
                        }
                        .fixedSize(horizontal: true, vertical: false)
                        .foregroundColor(AppTheme.Colors.buttonActiveText)
                        .padding(.horizontal, 16)
                        .frame(height: 36)
                        .background(Capsule().fill(AppTheme.Colors.buttonActiveBackground))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.top, 4)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .contentShape(Rectangle())
        .onTapGesture {
            HapticHelper.light()
            onSelectTransaction?(tx)
            presentationMode.wrappedValue.dismiss()
        }
    }
    
    private func formattedDate(_ d: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "it_IT")
        f.dateFormat = "d MMM, HH:mm"
        return f.string(from: d)
    }
}

struct PendingTransactionsView_Previews: PreviewProvider {
    static var previews: some View {
        PendingTransactionsView()
    }
}
