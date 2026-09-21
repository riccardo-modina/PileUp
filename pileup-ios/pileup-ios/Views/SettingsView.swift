import SwiftUI

struct SettingsView: View {
    @ObservedObject var authViewModel: AuthViewModel
    @State private var showLogoutConfirmation = false
    
    var body: some View {
        Form {
            Section(header: Text("Account")
                .font(.montserrat(size: 12, weight: .semibold))
                .foregroundColor(AppTheme.Colors.textLight)) {
                Button(action: {
                    showLogoutConfirmation = true
                }) {
                    HStack(spacing: 12) {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                            .font(.system(size: 16, weight: .medium))
                        Text("Esci dal profilo")
                            .font(.montserrat(size: 15, weight: .medium))
                    }
                    .foregroundColor(AppTheme.Colors.negative)
                }
                .listRowBackground(AppTheme.Colors.cardBackground)
            }
            
            // Qui potrai aggiungere in futuro altre impostazioni
            // come cambio tema, notifiche, lingua, ecc.
        }
        .scrollContentBackground(.hidden)
        .background(AppTheme.Colors.background.ignoresSafeArea())
        .navigationTitle("Impostazioni")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarHidden(false) // Assicura che la barra di navigazione torni visibile
        .alert("Conferma Uscita", isPresented: $showLogoutConfirmation) {
            Button("Annulla", role: .cancel) { }
            Button("Esci", role: .destructive) {
                authViewModel.logout()
            }
        } message: {
            Text("Sei sicuro di voler uscire dal tuo account?")
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            SettingsView(authViewModel: AuthViewModel())
        }
    }
}
