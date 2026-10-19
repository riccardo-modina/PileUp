import SwiftUI

/// Debug view to inspect, test, and apply transactions received from Apple Wallet and Bank SMS Shortcuts.
struct PendingTransactionsDebugView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject private var store = PendingTransactionsStore.shared
    
    // Callback to populate the AddTransactionView form with a selected pending transaction
    var onSelectTransaction: ((PendingWalletTransactionModel) -> Void)? = nil
    
    // Simulator states
    @State private var simulationText: String = "Fineco - SMS Gratuito: Autorizzato utilizzo Carta ***1111 Importo: 6,99 EUR, per: PAYPAL *2CO.COM. Info:"
    @State private var simulationCard: String = ""
    @State private var parseResultStatus: String? = nil
    
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
                        
                        // 3. In-App Notification / SMS Simulator
                        simulatorSection
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
                            store.clearAll()
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
                
                Text("Ricevuti in background dall'AppIntent / Shortcuts di iOS.")
                    .font(.system(size: 12))
                    .foregroundColor(AppTheme.Colors.dynamicSubtext)
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
                VStack(spacing: 12) {
                    Image(systemName: "tray")
                        .font(.system(size: 36))
                        .foregroundColor(AppTheme.Colors.dynamicSubtext.opacity(0.5))
                        .padding(.top, 20)
                    
                    Text("Nessun movimento in sospeso")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(AppTheme.Colors.dynamicText)
                    
                    Text("Quando l'AppIntent riceve un SMS o pagamento Wallet, apparirà qui.")
                        .font(.system(size: 13))
                        .foregroundColor(AppTheme.Colors.dynamicSubtext)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                        .padding(.bottom, 20)
                }
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(AppTheme.Colors.dynamicCardBackground)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(AppTheme.Colors.dynamicBorder.opacity(0.4), lineWidth: 1)
                )
            } else {
                VStack(spacing: 12) {
                    ForEach(store.pendingTransactions) { tx in
                        transactionCard(tx)
                    }
                }
            }
        }
    }
    
    private func transactionCard(_ tx: PendingWalletTransactionModel) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(tx.title)
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(AppTheme.Colors.dynamicText)
                    
                    Text(formattedDate(tx.date))
                        .font(.system(size: 12))
                        .foregroundColor(AppTheme.Colors.dynamicSubtext)
                }
                
                Spacer()
                
                Text(String(format: "%.2f €", tx.amount))
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(AppTheme.Colors.dynamicPrimary)
            }
            
            Divider()
                .background(AppTheme.Colors.dynamicBorder.opacity(0.4))
            
            HStack {
                if let accId = tx.accountId {
                    HStack(spacing: 4) {
                        Image(systemName: "creditcard")
                            .font(.system(size: 11))
                        Text("Conto ID: \(accId)")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .foregroundColor(AppTheme.Colors.dynamicSubtext)
                } else {
                    Text("Nessun conto abbinato")
                        .font(.system(size: 12))
                        .foregroundColor(AppTheme.Colors.dynamicSubtext.opacity(0.7))
                }
                
                Spacer()
                
                // Actions
                HStack(spacing: 10) {
                    // Discard
                    Button(action: {
                        HapticHelper.light()
                        store.removeTransaction(id: tx.id)
                    }) {
                        Image(systemName: "trash")
                            .font(.system(size: 13))
                            .foregroundColor(AppTheme.Colors.negative)
                            .padding(8)
                            .background(Circle().fill(AppTheme.Colors.negative.opacity(0.12)))
                    }
                    .buttonStyle(.plain)
                    
                    // Apply to Form
                    Button(action: {
                        HapticHelper.success()
                        onSelectTransaction?(tx)
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        HStack(spacing: 5) {
                            Image(systemName: "arrow.down.doc.fill")
                                .font(.system(size: 12))
                            Text("Usa")
                                .font(.system(size: 13, weight: .bold))
                        }
                        .foregroundColor(AppTheme.Colors.buttonActiveText)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 7)
                        .background(Capsule().fill(AppTheme.Colors.buttonActiveBackground))
                    }
                    .buttonStyle(.plain)
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
                .stroke(AppTheme.Colors.dynamicBorder.opacity(0.5), lineWidth: 1)
        )
    }
    
    // MARK: - 3. Simulator
    
    private var simulatorSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("🧪 SIMULATORE RAPIDO SMS / INTENT")
                    .font(.system(size: 11, weight: .bold))
                    .tracking(1.5)
                    .foregroundColor(AppTheme.Colors.dynamicSubtext)
                
                Spacer()
                
                Text("Solo Debug")
                    .font(.system(size: 10, weight: .semibold))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(AppTheme.Colors.willowGreen.opacity(0.15))
                    .foregroundColor(AppTheme.Colors.willowGreen)
                    .clipShape(Capsule())
            }
            
            VStack(alignment: .leading, spacing: 12) {
                Text("Incolla un SMS per testare subito il parsing del modello e l'aggiunta in coda senza uscire dall'app:")
                    .font(.system(size: 12))
                    .foregroundColor(AppTheme.Colors.dynamicSubtext)
                
                // Fast preset buttons
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        presetButton(title: "Fineco", text: "Fineco - SMS Gratuito: Autorizzato utilizzo Carta ***1111 Importo: 6,99 EUR, per: PAYPAL *2CO.COM. Info:")
                        presetButton(title: "PayPal", text: "Hai inviato 20,00 € EUR a Lorenzo Riva")
                        presetButton(title: "Carta", text: "Spesi 20,00 € presso PAYPAL *lorenzoriva22")
                        presetButton(title: "Nexi", text: "Nexi Informa: autorizzata spesa di EUR 18,20 con carta che termina per 4321 presso MEDIAWORLD MILANO")
                        presetButton(title: "HYPE", text: "HYPE: Hai pagato 15,20 € a PIZZERIA DA LUIGI con la tua carta")
                    }
                }
                
                TextEditor(text: $simulationText)
                    .frame(height: 70)
                    .font(.system(size: 13))
                    .scrollContentBackground(.hidden)
                    .padding(8)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(AppTheme.Colors.dynamicBorder.opacity(0.15))
                    )
                
                if let status = parseResultStatus {
                    Text(status)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(AppTheme.Colors.dynamicPrimary)
                }
                
                Button(action: simulateIncomingSMS) {
                    HStack(spacing: 6) {
                        Image(systemName: "bolt.fill")
                        Text("Analizza con CoreML e Aggiungi")
                    }
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(AppTheme.Colors.buttonActiveText)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(AppTheme.Colors.buttonActiveBackground)
                    )
                }
                .buttonStyle(.plain)
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
    }
    
    private func presetButton(title: String, text: String) -> some View {
        Button(action: {
            HapticHelper.light()
            simulationText = text
        }) {
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(AppTheme.Colors.dynamicText)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(
                    Capsule().fill(AppTheme.Colors.formCardActive)
                )
                .overlay(
                    Capsule().stroke(AppTheme.Colors.dynamicBorder.opacity(0.5), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
    
    private func simulateIncomingSMS() {
        HapticHelper.medium()
        if let parsed = BankNotificationParser.shared.parse(text: simulationText, knownBankName: simulationCard.isEmpty ? nil : simulationCard) {
            let success = store.addTransaction(
                amount: parsed.amount,
                merchant: parsed.merchant,
                date: Date(),
                cardName: parsed.paymentProvider
            )
            if success {
                parseResultStatus = "✅ Rilevato: \(String(format: "%.2f", parsed.amount)) € presso \(parsed.merchant) (\(parsed.paymentProvider ?? "nessun provider"))"
            } else {
                parseResultStatus = "⚠️ Rilevato ma già presente in coda (duplicato ignorato)."
            }
        } else {
            parseResultStatus = "❌ Nessuna spesa o esercente valido estratto dal testo."
        }
    }
    
    private func formattedDate(_ d: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "it_IT")
        f.dateFormat = "d MMM, HH:mm"
        return f.string(from: d)
    }
}
