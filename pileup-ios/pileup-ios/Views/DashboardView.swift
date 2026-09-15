import SwiftUI

/// Home view placeholder matching the other upcoming feature screens.
struct DashboardView: View {
    @ObservedObject var authViewModel: AuthViewModel
    @ObservedObject var viewModel: DashboardViewModel
    
    init(authViewModel: AuthViewModel, viewModel: DashboardViewModel? = nil) {
        self.authViewModel = authViewModel
        self.viewModel = viewModel ?? DashboardViewModel()
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Spacer()
                
                ZStack {
                    Circle()
                        .fill(AppTheme.Colors.primary.opacity(0.1))
                        .frame(width: 100, height: 100)
                    
                    Image(systemName: "house.fill")
                        .font(.system(size: 42))
                        .foregroundColor(AppTheme.Colors.primary)
                }
                
                VStack(spacing: 8) {
                    Text("Home")
                        .font(.montserrat(size: 24, weight: .bold))
                        .foregroundColor(AppTheme.Colors.text)
                    
                    Text("Panoramica generale, statistiche e scorciatoie in arrivo.")
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
                    .background(AppTheme.Colors.primary.opacity(0.08))
                    .clipShape(Capsule())
                
                Spacer()
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(AppTheme.Colors.background.ignoresSafeArea())
            .navigationBarTitle("Home", displayMode: .inline)
        }
    }
}

struct DashboardView_Previews: PreviewProvider {
    static var previews: some View {
        DashboardView(authViewModel: AuthViewModel())
    }
}
