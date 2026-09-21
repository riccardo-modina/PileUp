import SwiftUI
/// Implements dual-column bar chart with quota 0 baseline
/// period navigation with swipe gestures, and full dynamic palette support.
struct CashFlowView: View {
    @ObservedObject var dashboardViewModel: DashboardViewModel
    @Environment(\.presentationMode) var presentationMode
    
    @State private var activeDetailType: MovementType? = nil
    
    private let monthNamesShort = ["Gen", "Feb", "Mar", "Apr", "Mag", "Giu", "Lug", "Ago", "Set", "Ott", "Nov", "Dic"]
    
    /// Generates human-friendly date range (e.g. "1 Mag - 31 Mag")
    private var dateRangeText: String {
        switch dashboardViewModel.selectedPeriod {
        case .monthYear(let m, let y):
            let calendar = Calendar.current
            var components = DateComponents()
            components.year = y
            components.month = m
            components.day = 1
            let monthName = monthNamesShort[max(0, min(m - 1, 11))]
            
            if let date = calendar.date(from: components),
               let range = calendar.range(of: .day, in: .month, for: date) {
                let lastDay = range.count
                return "1 \(monthName) - \(lastDay) \(monthName)"
            }
            return "1 \(monthName) - 30 \(monthName)"
            
        case .year(let y):
            return "1 Gen - 31 Dic \(y)"
        case .total:
            return "Tutto lo storico"
        }
    }
    
    var body: some View {
        ZStack {
            AppTheme.Colors.dynamicBackground
                .ignoresSafeArea()
            
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    
                    // Top Navigation Row
                    HStack {
                        // Back chevron button
                        Button(action: {
                            presentationMode.wrappedValue.dismiss()
                        }) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(AppTheme.Colors.dynamicText)
                                .frame(width: 38, height: 38)
                                .background(
                                    Circle()
                                        .fill(AppTheme.Colors.dynamicCardBackground)
                                        .shadow(color: Color.black.opacity(0.04), radius: 4, x: 0, y: 2)
                                )
                                .overlay(
                                    Circle()
                                        .stroke(AppTheme.Colors.dynamicBorder.opacity(0.6), lineWidth: 1)
                                )
                        }
                        .buttonStyle(.plain)
                        
                        Spacer()
                        
                        // Single Period Selector Chip
                        PeriodSelectorChip(selectedPeriod: $dashboardViewModel.selectedPeriod)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    
                    // Title
                    Text("Entrate & Uscite")
                        .font(.system(size: 32, weight: .bold, design: .default))
                        .foregroundColor(AppTheme.Colors.dynamicText)
                        .padding(.horizontal, 20)
                        .padding(.top, 4)
                    
                    // Dual-Column Bar Chart
                    CashFlowDualBarChart(viewModel: dashboardViewModel)
                        .padding(.top, 6)
                    
                    // Date Navigator (< 1 Mag - 31 Mag >)
                    HStack {
                        Button(action: {
                            HapticHelper.light()
                            withAnimation(.easeInOut(duration: 0.25)) {
                                dashboardViewModel.previousPeriod()
                            }
                        }) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(AppTheme.Colors.dynamicText)
                                .frame(width: 36, height: 36)
                                .background(
                                    Circle()
                                        .fill(AppTheme.Colors.dynamicCardBackground)
                                )
                                .overlay(
                                    Circle()
                                        .stroke(AppTheme.Colors.dynamicBorder.opacity(0.6), lineWidth: 1)
                                )
                        }
                        .buttonStyle(.plain)
                        .disabled(dashboardViewModel.selectedPeriod.isTotal)
                        .opacity(dashboardViewModel.selectedPeriod.isTotal ? 0.3 : 1)
                        
                        Spacer()
                        
                        Text(dateRangeText)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(AppTheme.Colors.dynamicText)
                        
                        Spacer()
                        
                        Button(action: {
                            HapticHelper.light()
                            withAnimation(.easeInOut(duration: 0.25)) {
                                dashboardViewModel.nextPeriod()
                            }
                        }) {
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(AppTheme.Colors.dynamicText)
                                .frame(width: 36, height: 36)
                                .background(
                                    Circle()
                                        .fill(AppTheme.Colors.dynamicCardBackground)
                                )
                                .overlay(
                                    Circle()
                                        .stroke(AppTheme.Colors.dynamicBorder.opacity(0.6), lineWidth: 1)
                                )
                        }
                        .buttonStyle(.plain)
                        .disabled(!dashboardViewModel.selectedPeriod.canMoveForward())
                        .opacity(!dashboardViewModel.selectedPeriod.canMoveForward() ? 0.3 : 1)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    
                    // Unified Cash Flow Card (Netto + Entrate/Uscite breakdown)
                    CashFlowBreakdownList(
                        income: dashboardViewModel.monthlyIncome,
                        expense: dashboardViewModel.monthlyExpense,
                        onIncomeTap: {
                            HapticHelper.light()
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                                activeDetailType = .income
                            }
                        },
                        onExpenseTap: {
                            HapticHelper.light()
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                                activeDetailType = .expense
                            }
                        }
                    )
                    .padding(.horizontal, 20)
                    .padding(.top, 4)
                    .animation(.spring(response: 0.35, dampingFraction: 0.8), value: dashboardViewModel.selectedPeriod)
                    
                    // Safe bottom padding for floating BottomMenu
                    Spacer(minLength: 120)
                }
            }
            .contentShape(Rectangle())
            .offset(x: activeDetailType == nil ? 0 : -60)
            .opacity(activeDetailType == nil ? 1 : 0.4)
            .animation(.spring(response: 0.35, dampingFraction: 0.85), value: activeDetailType)
            // Horizontal swipe gesture active across the entire screen (when detail is not active)
            .simultaneousGesture(
                DragGesture(minimumDistance: 25)
                    .onEnded { value in
                        guard activeDetailType == nil else { return }
                        guard abs(value.translation.width) > abs(value.translation.height) else { return }
                        // Swipe left -> Next period
                        if value.translation.width < -35 {
                            if dashboardViewModel.selectedPeriod.canMoveForward() {
                                HapticHelper.light()
                                withAnimation(.easeInOut(duration: 0.25)) {
                                    dashboardViewModel.nextPeriod()
                                }
                            }
                        }
                        // Swipe right -> Previous period
                        else if value.translation.width > 35 {
                            if !dashboardViewModel.selectedPeriod.isTotal {
                                HapticHelper.light()
                                withAnimation(.easeInOut(duration: 0.25)) {
                                    dashboardViewModel.previousPeriod()
                                }
                            }
                        }
                    }
            )
            
            // Detail View (Slides in from right towards left, exits left to right)
            if let detailType = activeDetailType {
                CashFlowDetailView(
                    movementType: detailType,
                    period: $dashboardViewModel.selectedPeriod,
                    onBack: {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                            activeDetailType = nil
                        }
                    }
                )
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing),
                    removal: .move(edge: .trailing)
                ))
                .zIndex(20)
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: activeDetailType)
        .navigationBarHidden(true)
        .onAppear {
            dashboardViewModel.fetchMonthlyStats()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ResetCashFlowDetail"))) { _ in
            if activeDetailType != nil {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                    activeDetailType = nil
                }
            }
        }
    }
}

struct CashFlowView_Previews: PreviewProvider {
    static var previews: some View {
        CashFlowView(dashboardViewModel: DashboardViewModel())
    }
}
