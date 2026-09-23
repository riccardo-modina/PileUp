import SwiftUI

/// Breakdown card displaying "Money in" and "Money out" with color square tags and chevrons,
/// ready to navigate to the detailed transactions view.
struct CashFlowBreakdownList: View {
    let income: Double
    let expense: Double
    var onIncomeTap: (() -> Void)? = nil
    var onExpenseTap: (() -> Void)? = nil
    
    private var netAmount: Double {
        income - expense
    }
    
    private func formattedCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "EUR"
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: value)) ?? "€ 0,00"
    }
    
    private func formattedNetCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "EUR"
        formatter.maximumFractionDigits = 2
        let absFormatted = formatter.string(from: NSNumber(value: abs(value))) ?? "€ 0,00"
        return (value >= 0 ? "+" : "-") + absFormatted
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Net Amount Header Section
            VStack(alignment: .leading, spacing: 4) {
                Text("Netto")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(AppTheme.Colors.dynamicSubtext)
                
                CurrencyAmountText(
                    formattedNetCurrency(netAmount),
                    size: 29,
                    weight: .semibold,
                    design: .rounded,
                    color: AppTheme.Colors.dynamicText
                )
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 14)
            
            // Divider between Net and Breakdown rows
            Divider()
                .background(AppTheme.Colors.dynamicBorder.opacity(0.6))
                .padding(.horizontal, 16)
            
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
                .padding(.vertical, 15)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            
            // Subtle Divider
            Divider()
                .background(AppTheme.Colors.dynamicBorder.opacity(0.6))
                .padding(.leading, 52)
                .padding(.trailing, 16)
            
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
                .padding(.vertical, 15)
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
