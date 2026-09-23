import SwiftUI

/// Reusable component that renders currency amounts with smaller decimal numbers.
/// The font size reduction for decimals scales dynamically: the larger the base font size,
/// the greater the proportional reduction.
struct CurrencyAmountText: View {
    let text: String
    var size: CGFloat = 15
    var weight: Font.Weight = .semibold
    var design: Font.Design = .rounded
    var color: Color = AppTheme.Colors.dynamicText
    
    init(
        _ text: String,
        size: CGFloat = 15,
        weight: Font.Weight = .semibold,
        design: Font.Design = .rounded,
        color: Color = AppTheme.Colors.dynamicText
    ) {
        self.text = text
        self.size = size
        self.weight = weight
        self.design = design
        self.color = color
    }
    
    init(
        value: Double,
        prefix: String = "",
        size: CGFloat = 15,
        weight: Font.Weight = .semibold,
        design: Font.Design = .rounded,
        color: Color = AppTheme.Colors.dynamicText
    ) {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "€"
        formatter.locale = Locale(identifier: "it_IT")
        let formatted = formatter.string(from: NSNumber(value: value)) ?? String(format: "€ %.2f", value)
        self.text = prefix.isEmpty ? formatted : "\(prefix)\(formatted)"
        self.size = size
        self.weight = weight
        self.design = design
        self.color = color
    }
    
    private var parts: (integer: String, decimal: String) {
        if let commaIndex = text.lastIndex(of: ",") {
            return (String(text[..<commaIndex]), String(text[commaIndex...]))
        } else if let dotIndex = text.lastIndex(of: ".") {
            return (String(text[..<dotIndex]), String(text[dotIndex...]))
        }
        return (text, "")
    }
    
    /// Scales decimal reduction:
    /// - Small fonts (<= 16pt): ~22% reduction (ratio 0.78, e.g. 15pt -> 12pt)
    /// - Medium fonts (17-22pt): ~28% reduction (ratio 0.72, e.g. 20pt -> 14pt)
    /// - Large fonts (23-28pt): ~34% reduction (ratio 0.66, e.g. 26pt -> 17pt, 28pt -> 18pt)
    /// - Extra large fonts (> 28pt): ~40% reduction (ratio 0.60, e.g. 36pt -> 22pt)
    private var decimalSize: CGFloat {
        let ratio: CGFloat
        if size <= 16 {
            ratio = 0.78
        } else if size <= 22 {
            ratio = 0.72
        } else if size <= 28 {
            ratio = 0.66
        } else {
            ratio = 0.60
        }
        return max(9, round(size * ratio))
    }
    
    var body: some View {
        if parts.decimal.isEmpty {
            Text(parts.integer)
                .font(.system(size: size, weight: weight, design: design))
                .foregroundColor(color)
        } else {
            Text("\(Text(parts.integer).font(.system(size: size, weight: weight, design: design)))\(Text(parts.decimal).font(.system(size: decimalSize, weight: weight, design: design)))")
                .foregroundColor(color)
        }
    }
}
