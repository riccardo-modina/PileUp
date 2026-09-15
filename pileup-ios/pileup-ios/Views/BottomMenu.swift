import SwiftUI

enum AppTab: String, CaseIterable, Identifiable {
    case home
    case cashflow
    case investments
    case menu
    
    var id: String { rawValue }
    
    var title: String {
        switch self {
        case .home: return "Home"
        case .cashflow: return "Movimenti"
        case .investments: return "Investimenti"
        case .menu: return "Menu"
        }
    }
    
    var icon: String {
        switch self {
        case .home: return "house"
        case .cashflow: return "chart.bar"
        case .investments: return "chart.line.uptrend.xyaxis"
        case .menu: return "line.3.horizontal"
        }
    }
    
    var selectedIcon: String {
        switch self {
        case .home: return "house.fill"
        case .cashflow: return "chart.bar.fill"
        case .investments: return "chart.line.uptrend.xyaxis"
        case .menu: return "line.3.horizontal"
        }
    }
}

/// Floating bottom navigation bar matching the design system.
/// Contains 4 tabs and an elevated center "+" button.
struct BottomMenu: View {
    @Binding var selectedTab: AppTab
    let onAddTapped: () -> Void
    let onMenuTapped: () -> Void
    
    var body: some View {
        ZStack(alignment: .top) {
            // Navigation Bar Pill Container
            HStack(spacing: 0) {
                // Left 2 items: Home, CashFlow
                HStack(spacing: 0) {
                    tabButton(for: .home)
                    tabButton(for: .cashflow)
                }
                .frame(maxWidth: .infinity)
                
                // Gap for the elevated center button
                Spacer()
                    .frame(width: 64)
                
                // Right 2 items: Investimenti, Menu
                HStack(spacing: 0) {
                    tabButton(for: .investments)
                    tabButton(for: .menu)
                }
                .frame(maxWidth: .infinity)
            }
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .fill(AppTheme.Colors.dynamicCardBackground)
                    .shadow(color: Color.black.opacity(0.06), radius: 14, x: 0, y: 4)
                    .overlay(
                        RoundedRectangle(cornerRadius: 26, style: .continuous)
                            .stroke(AppTheme.Colors.dynamicBorder.opacity(0.8), lineWidth: 1)
                    )
            )
            
            // Center "+" Button (lowered down)
            Button(action: {
                let generator = UIImpactFeedbackGenerator(style: .medium)
                generator.impactOccurred()
                onAddTapped()
            }) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [AppTheme.Colors.prussianBlue, AppTheme.Colors.prussianBlueDark],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 54, height: 54)
                        .shadow(color: AppTheme.Colors.prussianBlue.opacity(0.35), radius: 8, x: 0, y: 4)
                    
                    Image(systemName: "plus")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            .offset(y: -10) // Lowered down
        }
    }
    
    @ViewBuilder
    private func tabButton(for tab: AppTab) -> some View {
        let isSelected = selectedTab == tab
        let activeColor = AppTheme.Colors.dynamicText
        let inactiveColor = AppTheme.Colors.dynamicSubtext
        
        Button(action: {
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
            if tab == .menu {
                onMenuTapped()
            } else {
                selectedTab = tab
            }
        }) {
            VStack(spacing: 4) {
                Image(systemName: isSelected ? tab.selectedIcon : tab.icon)
                    .font(.system(size: 19))
                    .foregroundColor(isSelected ? activeColor : inactiveColor)
                    .frame(height: 22)
                
                Text(tab.title)
                    .font(.montserrat(size: 8.5, weight: isSelected ? .semibold : .medium))
                    .textCase(.uppercase)
                    .tracking(0.2)
                    .lineLimit(1)
                    .minimumScaleFactor(0.55)
                    .foregroundColor(isSelected ? activeColor : inactiveColor)
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

/// Backwards compatibility alias
typealias CustomBottomBar = BottomMenu

struct BottomMenu_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.gray.opacity(0.2).ignoresSafeArea()
            BottomMenu(
                selectedTab: .constant(.home),
                onAddTapped: {},
                onMenuTapped: {}
            )
            .padding(.horizontal, 16)
        }
    }
}
