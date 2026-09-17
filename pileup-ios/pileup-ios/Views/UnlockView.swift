import SwiftUI
import LocalAuthentication

struct UnlockView: View {
    @ObservedObject var viewModel: AuthViewModel
    @State private var password = ""
    
    @State private var isFaceIDAvailable = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Spacer()
                
                let username = UserDefaults.standard.string(forKey: "username") ?? "Utente"
                Text("CIAO, \(username.uppercased())")
                    .font(.montserrat(size: 28, weight: .bold))
                    .tracking(2)
                    .foregroundColor(AppTheme.Colors.primary)
                
                Text("Sblocca per accedere ai tuoi dati")
                    .font(.montserrat(size: 15))
                    .foregroundColor(AppTheme.Colors.textLight)
                
                Spacer().frame(height: 20)
                
                if isFaceIDAvailable {
                    Button(action: {
                        viewModel.unlockWithBiometrics()
                    }) {
                        VStack(spacing: 12) {
                            Image(systemName: "faceid")
                                .font(.system(size: 60))
                                .foregroundColor(AppTheme.Colors.primary)
                            Text("SBLOCCA CON FACE ID")
                                .font(.montserrat(size: 14, weight: .bold))
                                .tracking(1)
                                .foregroundColor(AppTheme.Colors.primary)
                        }
                    }
                    .padding()
                    
                    Spacer().frame(height: 20)
                    
                    Text("Oppure usa la password")
                        .font(.montserrat(size: 12))
                        .foregroundColor(AppTheme.Colors.textLight)
                        .textCase(.uppercase)
                }
                
                SecureField("Password", text: $password)
                    .padding()
                    .background(AppTheme.Colors.cardBackground)
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(AppTheme.Colors.dynamicBorder.opacity(0.8), lineWidth: 1)
                    )
                    .padding(.horizontal)
                
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.montserrat(size: 13))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                Button(action: {
                    viewModel.unlockWithPassword(password)
                }) {
                    HStack {
                        if viewModel.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: AppTheme.Colors.primaryButtonText))
                        } else {
                            Text("SBLOCCA")
                                .font(.montserrat(size: 16, weight: .bold))
                                .tracking(2)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(AppTheme.Colors.primary)
                    .foregroundColor(AppTheme.Colors.primaryButtonText)
                    .cornerRadius(10)
                }
                .padding(.horizontal)
                .disabled(viewModel.isLoading || password.isEmpty)
                
                Spacer()
                
                Button(action: {
                    viewModel.logout()
                }) {
                    Text("Esci e usa un altro account")
                        .font(.montserrat(size: 14))
                        .foregroundColor(AppTheme.Colors.textLight)
                }
                .padding(.bottom, 20)
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(AppTheme.Colors.background.ignoresSafeArea())
            .onAppear {
                checkBiometrics()
            }
        }
    }
    
    func checkBiometrics() {
        let context = LAContext()
        var error: NSError?
        
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            isFaceIDAvailable = (context.biometryType == .faceID)
        } else {
            isFaceIDAvailable = false
        }
    }
}
