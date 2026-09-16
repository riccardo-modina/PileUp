import SwiftUI

/// Semantic severity level for form messages.
enum InputErrorType {
    case error
    case warning
    case info
    
    var color: Color {
        switch self {
        case .error:
            return AppTheme.Colors.negative
        case .warning:
            return Color(red: 217/255, green: 119/255, blue: 6/255) // Amber-600
        case .info:
            return AppTheme.Colors.primary
        }
    }
}

/// Reusable UI component matching the frontend InputError.vue component.
/// Renders a clean validation message using purely color to communicate severity, without icons or emojis.
struct InputError: View {
    let message: String
    var type: InputErrorType = .error
    var animate: Bool = false
    
    var body: some View {
        if !message.isEmpty {
            Text(message)
                .font(.system(size: 11.5, weight: .semibold))
                .foregroundColor(type.color)
                .lineLimit(2)
                .padding(.vertical, 2)
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .move(edge: .top)),
                    removal: .opacity
                ))
        }
    }
}

/// Backwards compatibility alias
typealias InputErrorView = InputError
