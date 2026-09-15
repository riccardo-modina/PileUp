import SwiftUI

/// Clean, minimal card displaying the Net Cash Flow of the active period.
struct CashFlowNetCard: View {
    let income: Double
    let expense: Double
    
    private var netAmount: Double {
        income - expense
    }
    
    private func formattedCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "EUR"
        formatter.maximumFractionDigits = 2
        let absFormatted = formatter.string(from: NSNumber(value: abs(value))) ?? "€ 0,00"
        return (value >= 0 ? "+" : "-") + absFormatted
    }
    
    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Netto")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(AppTheme.Colors.dynamicSubtext)
                
                Text(formattedCurrency(netAmount))
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(AppTheme.Colors.dynamicText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
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

struct CashFlowNetCard_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 16) {
            CashFlowNetCard(income: 2450.00, expense: 1840.00)
            CashFlowNetCard(income: 1200.00, expense: 1550.00)
        }
        .padding()
        .background(AppTheme.Colors.dynamicBackground)
    }
}
