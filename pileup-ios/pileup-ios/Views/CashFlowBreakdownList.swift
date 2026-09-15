import SwiftUI

/// Breakdown card displaying "Money in" and "Money out" with color square tags and chevrons,
/// ready to navigate to the detailed transactions view.
struct CashFlowBreakdownList: View {
    let income: Double
    let expense: Double
    var onIncomeTap: (() -> Void)? = nil
    var onExpenseTap: (() -> Void)? = nil
    
    private func formattedCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "EUR"
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: value)) ?? "€ 0,00"
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Money In Row
            Button(action: {
                let generator = UIImpactFeedbackGenerator(style: .light)
                generator.impactOccurred()
                onIncomeTap?()
            }) {
                HStack(spacing: 14) {
                    // Mint Green Rounded Square Icon
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(AppTheme.Colors.moneyIn)
                        .frame(width: 22, height: 22)
                    
                    Text("Entrate")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(AppTheme.Colors.dynamicText)
                    
                    Spacer()
                    
                    Text("+\(formattedCurrency(income))")
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundColor(AppTheme.Colors.dynamicText)
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(AppTheme.Colors.dynamicSubtext.opacity(0.7))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            
            // Subtle Divider
            Divider()
                .background(AppTheme.Colors.dynamicBorder.opacity(0.6))
                .padding(.leading, 52)
            
            // Money Out Row
            Button(action: {
                let generator = UIImpactFeedbackGenerator(style: .light)
                generator.impactOccurred()
                onExpenseTap?()
            }) {
                HStack(spacing: 14) {
                    // Powder Blue Rounded Square Icon
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(AppTheme.Colors.moneyOut)
                        .frame(width: 22, height: 22)
                    
                    Text("Uscite")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(AppTheme.Colors.dynamicText)
                    
                    Spacer()
                    
                    Text("-\(formattedCurrency(expense))")
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundColor(AppTheme.Colors.dynamicText)
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(AppTheme.Colors.dynamicSubtext.opacity(0.7))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(AppTheme.Colors.dynamicCardBackground)
                .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(AppTheme.Colors.dynamicBorder.opacity(0.6), lineWidth: 1)
        )
    }
}

struct CashFlowBreakdownList_Previews: PreviewProvider {
    static var previews: some View {
        CashFlowBreakdownList(income: 2450.00, expense: 1840.00)
            .padding()
            .background(AppTheme.Colors.dynamicBackground)
    }
}
