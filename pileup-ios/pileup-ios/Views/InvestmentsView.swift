import SwiftUI

/// View for the Investimenti tab matching the Pileup theme.
struct InvestmentsView: View {
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Spacer()
                
                ZStack {
                    Circle()
                        .fill(AppTheme.Colors.dynamicCardBackground)
                        .frame(width: 90, height: 90)
                        .overlay(
                            Circle()
                                .stroke(AppTheme.Colors.dynamicBorder, lineWidth: 1)
                        )
                    
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.system(size: 40))
                        .foregroundColor(AppTheme.Colors.primary)
                }
                
                VStack(spacing: 8) {
                    Text("Investimenti")
                        .font(.montserrat(size: 22, weight: .bold))
                        .foregroundColor(AppTheme.Colors.text)
                    
                    Text("Monitora il tuo portafoglio, azioni e rendimenti.")
                        .font(.montserrat(size: 14, weight: .regular))
                        .foregroundColor(AppTheme.Colors.textLight)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                
                Text("FUNZIONALITÀ IN ARRIVO")
                    .font(.montserrat(size: 11, weight: .bold))
                    .tracking(2)
                    .foregroundColor(AppTheme.Colors.primary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(AppTheme.Colors.dynamicCardBackground)
                    .overlay(
                        Capsule()
                            .stroke(AppTheme.Colors.dynamicBorder, lineWidth: 1)
                    )
                    .clipShape(Capsule())
                
                Spacer()
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(AppTheme.Colors.background.ignoresSafeArea())
            .navigationBarTitle("Investimenti", displayMode: .inline)
        }
    }
}

struct InvestmentsView_Previews: PreviewProvider {
    static var previews: some View {
        InvestmentsView()
    }
}
