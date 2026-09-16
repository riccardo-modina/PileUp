import SwiftUI

/// Main container view hosting the 4 tab screens and the floating CustomBottomBar.
struct MainTabView: View {
    @ObservedObject var authViewModel: AuthViewModel
    
    @State private var selectedTab: AppTab = .home
    @State private var showAddTransaction: Bool = false
    @State private var showMenuSheet: Bool = false
    
    // Shared DashboardViewModel so all tabs share synchronized period & statistics
    @StateObject private var dashboardViewModel = DashboardViewModel()
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottom) {
                // Tab Contents
                Group {
                    switch selectedTab {
                    case .home, .menu:
                        DashboardView(authViewModel: authViewModel, viewModel: dashboardViewModel)
                    case .cashflow:
                        CashFlowView(dashboardViewModel: dashboardViewModel)
                    case .investments:
                        InvestmentsView()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .onChange(of: selectedTab) {
                    if showMenuSheet {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            showMenuSheet = false
                        }
                    }
                }
                
                // Dimmed Backdrop when menu is open
                if showMenuSheet {
                    Color.black.opacity(0.35)
                        .edgesIgnoringSafeArea(.all)
                        .transition(.opacity)
                        .onTapGesture {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                showMenuSheet = false
                            }
                        }
                        .zIndex(15)
                }
                
                // In-View Menu Drawer sliding up to 3/4 of the screen above bottom bar
                if showMenuSheet {
                    MenuView(authViewModel: authViewModel, onClose: {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            showMenuSheet = false
                        }
                    })
                    .frame(height: max(geometry.size.height * 0.75, 450))
                    .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                    .shadow(color: Color.black.opacity(0.18), radius: 25, x: 0, y: -6)
                    .padding(.horizontal, 10)
                    .padding(.bottom, 94) // Resting cleanly above the floating bottom menu
                    .transition(.asymmetric(
                        insertion: .move(edge: .bottom).combined(with: .opacity),
                        removal: .move(edge: .bottom).combined(with: .opacity)
                    ))
                    .gesture(
                        DragGesture()
                            .onEnded { value in
                                if value.translation.height > 60 {
                                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                        showMenuSheet = false
                                    }
                                }
                            }
                    )
                    .zIndex(25)
                }
                
                // Progressive blur background behind floating bar (matches frontend mobile-blur-bg)
                VStack {
                    Spacer()
                    Rectangle()
                        .fill(.ultraThinMaterial)
                        .mask(
                            LinearGradient(
                                colors: [.clear, .black.opacity(0.8), .black],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(height: 110)
                        .edgesIgnoringSafeArea(.bottom)
                        .allowsHitTesting(false)
                }
                .zIndex(5)
                
                // Floating Bottom Menu with 4 items and central "+" button
                BottomMenu(
                    selectedTab: $selectedTab,
                    onAddTapped: {
                        showAddTransaction = true
                    },
                    onMenuTapped: {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            showMenuSheet.toggle()
                        }
                    }
                )
                .padding(.horizontal, 16)
                .padding(.bottom, 20)
                .zIndex(30)
            }
        }
        .sheet(isPresented: $showAddTransaction) {
            AddTransactionView(masterKey: authViewModel.masterKey)
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("TransactionsUpdated"))) { _ in
            dashboardViewModel.fetchMonthlyStats()
        }
    }
}

struct MainTabView_Previews: PreviewProvider {
    static var previews: some View {
        MainTabView(authViewModel: AuthViewModel())
    }
}
