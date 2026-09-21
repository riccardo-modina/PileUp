import SwiftUI

struct LoginView: View {
    @ObservedObject var viewModel: AuthViewModel
    @State private var username = ""
    @State private var password = ""
    @State private var showSettings = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Tasto impostazioni in alto a destra, indipendente dalla Navigation Bar
                HStack {
                    Spacer()
                    Button(action: { showSettings = true }) {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 22))
                            .foregroundColor(.gray.opacity(0.6))
                    }
                }
                .padding(.trailing, 10)
                
                Spacer()
                
                // Logo or Title
                Text("PILEUP")
                    .font(.montserrat(size: 34, weight: .bold))
                    .tracking(6) // increased space between letters
                    .foregroundColor(AppTheme.Colors.primary)
                
                Text("Accedi al tuo account")
                    .font(.montserrat(size: 14, weight: .semibold))
                    .textCase(.uppercase)
                    .tracking(2)
                    .foregroundColor(.gray)
                
                // Form Fields
                VStack(spacing: 16) {
                    TextField("Nome utente", text: $username)
                        .padding()
                        .background(AppTheme.Colors.cardBackground)
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(AppTheme.Colors.dynamicBorder.opacity(0.8), lineWidth: 1)
                        )
                        .autocapitalization(.none)
                    
                    SecureField("Password", text: $password)
                        .padding()
                        .background(AppTheme.Colors.cardBackground)
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(AppTheme.Colors.dynamicBorder.opacity(0.8), lineWidth: 1)
                        )
                }
                .padding(.horizontal)
                
                if let errorMessage = viewModel.errorMessage {
                    ErrorBanner(message: errorMessage)
                        .padding(.horizontal)
                }
                
                // Login Button
                Button(action: {
                    viewModel.login(username: username, password: password)
                }) {
                    HStack {
                        if viewModel.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: AppTheme.Colors.primaryButtonText))
                        } else {
                            Text("ACCEDI")
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
                .disabled(viewModel.isLoading || username.isEmpty || password.isEmpty)
                
                // Se le registrazioni sono aperte
                if viewModel.globalSettings?.allow_registration == true {
                    NavigationLink(destination: RegisterView(viewModel: viewModel)) {
                        Text("NON HAI UN ACCOUNT? REGISTRATI")
                            .font(.montserrat(size: 12, weight: .bold))
                            .tracking(1)
                            .foregroundColor(AppTheme.Colors.primary)
                    }
                    .padding(.top, 16)
                }
                
                Spacer()
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(AppTheme.Colors.background.ignoresSafeArea())
            .sheet(isPresented: $showSettings) {
                ServerSettingsView()
            }
        }
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            LoginView(viewModel: AuthViewModel())
                .preferredColorScheme(.light)
                .previewDisplayName("Light Mode")
            
            LoginView(viewModel: AuthViewModel())
                .preferredColorScheme(.dark)
                .previewDisplayName("Dark Mode")
        }
    }
}
