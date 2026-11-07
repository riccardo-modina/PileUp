//
// PileUp - Personal finance tracking platform
// Copyright (C) 2024-2026 PileUp
//
// Licensed under the GNU Affero General Public License v3.0.
// See LICENSE in the project root for full license details.
//

import SwiftUI

extension Font {
    /// Helper for the Montserrat custom font with Dynamic Type support.
    /// Automatically scales with the text size configured in iOS Settings (Dynamic Type).
    static func montserrat(size: CGFloat, weight: Font.Weight = .regular, relativeTo: Font.TextStyle? = nil) -> Font {
        let fontName: String = switch weight {
        case .medium:
            "Montserrat-Medium"
        case .semibold:
            "Montserrat-SemiBold"
        case .bold:
            "Montserrat-Bold"
        default:
            "Montserrat-Regular"
        }

        let textStyle: Font.TextStyle = if let relativeTo {
            relativeTo
        } else {
            // Automatic mapping to standard iOS Dynamic Type scale
            switch size {
            case 34...: .largeTitle
            case 28 ..< 34: .title
            case 22 ..< 28: .title2
            case 20 ..< 22: .title3
            case 17 ..< 20: .headline
            case 15 ..< 17: .body
            case 13 ..< 15: .subheadline
            case 11 ..< 13: .footnote
            default: .caption2
            }
        }

        return .custom(fontName, size: size, relativeTo: textStyle)
    }
}
