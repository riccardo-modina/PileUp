import SwiftUI
import UIKit

extension UIColor {
    convenience init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            red: CGFloat(r) / 255.0,
            green: CGFloat(g) / 255.0,
            blue: CGFloat(b) / 255.0,
            alpha: CGFloat(a) / 255.0
        )
    }
}

extension Color {
    init(hex: String) {
        self.init(uiColor: UIColor(hex: hex))
    }
}

/// Shared App Theme matching the official design palette.
struct AppTheme {
    struct Colors {
        // Core Palette Tokens
        static let willowGreen = Color(hex: "#8ce857")
        static let moneyIn = Color(hex: "#34d399")
        static let moneyOut = Color(hex: "#60a5fa")
        
        static let brightSnow = Color(hex: "#f8fafc")
        static let prussianBlue = Color(hex: "#0f172a")
        static let prussianBlueDark = Color(hex: "#1e2638")
        static let aliceBlue = Color(hex: "#e2e8f0")
        static let inkBlack = Color(hex: "#0b0f17")
        static let platinum = Color(hex: "#f1f5f9")
        static let negative = Color(hex: "#ef4444")
        
        // Dynamic adaptive colors (Light / Dark Mode)
        static var dynamicBackground: Color {
            Color(uiColor: UIColor { trait in
                trait.userInterfaceStyle == .dark ? UIColor(hex: "#0b0f17") : UIColor(hex: "#f8fafc")
            })
        }
        
        static var dynamicCardBackground: Color {
            Color(uiColor: UIColor { trait in
                trait.userInterfaceStyle == .dark ? UIColor(hex: "#1e2638") : UIColor.white
            })
        }
        
        static var dynamicText: Color {
            Color(uiColor: UIColor { trait in
                trait.userInterfaceStyle == .dark ? UIColor(hex: "#f1f5f9") : UIColor(hex: "#0f172a")
            })
        }
        
        static var dynamicSubtext: Color {
            Color(uiColor: UIColor { trait in
                trait.userInterfaceStyle == .dark ? UIColor(hex: "#94a3b8") : UIColor(hex: "#64748b")
            })
        }
        
        static var dynamicBorder: Color {
            Color(uiColor: UIColor { trait in
                trait.userInterfaceStyle == .dark ? UIColor(hex: "#243049") : UIColor(hex: "#e2e8f0")
            })
        }

        // Palette-bound app aliases
        static var primary: Color { prussianBlue }
        static var background: Color { dynamicBackground }
        static var cardBackground: Color { dynamicCardBackground }
        static var text: Color { dynamicText }
        static var textLight: Color { dynamicSubtext }
        static var neutral: Color { dynamicSubtext }
    }
}
