import SwiftUI

/// Styled error banner component with an icon, themed background, and smooth presentation.
struct ErrorBanner: View {
    let message: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(AppTheme.Colors.negative)
                .padding(.top, 1)
            
            Text(message)
                .font(.montserrat(size: 13, weight: .medium))
                .foregroundColor(AppTheme.Colors.negative)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
            
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(AppTheme.Colors.negative.opacity(0.1))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(AppTheme.Colors.negative.opacity(0.3), lineWidth: 1)
        )
        .transition(.asymmetric(
            insertion: .opacity.combined(with: .scale(scale: 0.96)),
            removal: .opacity
        ))
    }
}

struct ErrorBanner_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 16) {
            ErrorBanner(message: "Nome utente o password non corretti. Riprova.")
            ErrorBanner(message: "Questo nome utente è già in uso. Scegline un altro.")
            ErrorBanner(message: "Nessuna connessione a Internet. Verifica la tua rete e riprova.")
        }
        .padding()
        .background(AppTheme.Colors.background)
    }
}
