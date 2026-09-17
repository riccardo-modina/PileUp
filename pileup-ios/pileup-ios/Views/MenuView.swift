import SwiftUI

/// View for the Menu tab matching the Pileup theme.
struct MenuView: View {
    @ObservedObject var authViewModel: AuthViewModel
    var onClose: () -> Void = {}
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Drag handle
                Capsule()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 36, height: 5)
                    .padding(.top, 10)
                    .padding(.bottom, 8)
                
                // Header
                HStack {
                    Text("Menu")
                        .font(.montserrat(size: 20, weight: .bold))
                        .foregroundColor(AppTheme.Colors.text)
                    
                    Spacer()
                    
                    Button(action: {
                        let generator = UIImpactFeedbackGenerator(style: .light)
                        generator.impactOccurred()
                        onClose()
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(AppTheme.Colors.neutral)
                            .padding(8)
                            .background(Color.gray.opacity(0.1))
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 16)
                
                ScrollView {
                    VStack(spacing: 24) {
                        ZStack {
                            Circle()
                                .fill(AppTheme.Colors.primary.opacity(0.1))
                                .frame(width: 80, height: 80)
                            
                            Image(systemName: "line.3.horizontal")
                                .font(.system(size: 32))
                                .foregroundColor(AppTheme.Colors.primary)
                        }
                        .padding(.top, 12)
                        
                        VStack(spacing: 8) {
                            Text("Opzioni e Strumenti")
                                .font(.montserrat(size: 18, weight: .bold))
                                .foregroundColor(AppTheme.Colors.text)
                            
                            Text("Impostazioni, gestione categorie e preferenze dell'account.")
                                .font(.montserrat(size: 13, weight: .regular))
                                .foregroundColor(AppTheme.Colors.textLight)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 32)
                        }
                        
                        Text("FUNZIONALITÀ IN ARRIVO")
                            .font(.montserrat(size: 11, weight: .bold))
                            .tracking(2)
                            .foregroundColor(AppTheme.Colors.primary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(AppTheme.Colors.primary.opacity(0.08))
                            .clipShape(Capsule())
                        
                        // Quick link to settings for user convenience
                        NavigationLink(destination: SettingsView(authViewModel: authViewModel)) {
                            HStack(spacing: 12) {
                                Image(systemName: "gearshape.fill")
                                    .font(.system(size: 18))
                                    .foregroundColor(AppTheme.Colors.primary)
                                    .frame(width: 36, height: 36)
                                    .background(AppTheme.Colors.primary.opacity(0.1))
                                    .clipShape(Circle())
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Impostazioni Account")
                                        .font(.montserrat(size: 14, weight: .semibold))
                                        .foregroundColor(AppTheme.Colors.text)
                                    
                                    Text("Gestisci profilo, server e preferenze")
                                        .font(.montserrat(size: 11))
                                        .foregroundColor(AppTheme.Colors.textLight)
                                }
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(AppTheme.Colors.neutral)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .fill(AppTheme.Colors.cardBackground)
                                    .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 2)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .stroke(AppTheme.Colors.dynamicBorder.opacity(0.6), lineWidth: 1)
                            )
                        }
                        .padding(.horizontal, 20)
                        
                        Spacer(minLength: 30)
                    }
                }
            }
            .background(AppTheme.Colors.background.ignoresSafeArea())
            .navigationBarHidden(true)
        }
    }
}

struct MenuView_Previews: PreviewProvider {
    static var previews: some View {
        MenuView(authViewModel: AuthViewModel())
    }
}
