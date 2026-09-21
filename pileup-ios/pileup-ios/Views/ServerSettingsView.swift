import SwiftUI

struct ServerSettingsView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var customURL: String = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Configurazione Server")
                    .font(.montserrat(size: 12, weight: .semibold))
                    .foregroundColor(AppTheme.Colors.textLight),
                        footer: Text("Lascia vuoto per utilizzare il server cloud. Assicurati di includere http:// o https:// e terminare con /api/ se utilizzi un server locale/personalizzato.")
                    .font(.montserrat(size: 12))
                    .foregroundColor(AppTheme.Colors.textLight)) {
                    TextField("Es. http://192.168.1.100:8080/api/", text: $customURL)
                        .font(.montserrat(size: 15))
                        .foregroundColor(AppTheme.Colors.text)
                        .keyboardType(.URL)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                }
                .listRowBackground(AppTheme.Colors.cardBackground)
                
                Section {
                    Button(action: {
                        customURL = ""
                        saveURL()
                    }) {
                        Text("Ripristina Predefinito")
                            .font(.montserrat(size: 15, weight: .medium))
                            .foregroundColor(AppTheme.Colors.negative)
                    }
                }
                .listRowBackground(AppTheme.Colors.cardBackground)
            }
            .scrollContentBackground(.hidden)
            .background(AppTheme.Colors.background.ignoresSafeArea())
            .navigationBarTitle("Impostazioni Server", displayMode: .inline)
            .navigationBarItems(
                leading: Button("Annulla") {
                    presentationMode.wrappedValue.dismiss()
                }
                .foregroundColor(AppTheme.Colors.primary),
                trailing: Button("Salva") {
                    saveURL()
                }
                .foregroundColor(AppTheme.Colors.primary)
                .fontWeight(.bold)
            )
            .onAppear {
                customURL = UserDefaults.standard.string(forKey: "customServerURL") ?? ""
            }
        }
    }
    
    private func saveURL() {
        let trimmed = customURL.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            UserDefaults.standard.removeObject(forKey: "customServerURL")
        } else {
            // Ensure it ends with a slash
            let finalURL = trimmed.hasSuffix("/") ? trimmed : trimmed + "/"
            UserDefaults.standard.set(finalURL, forKey: "customServerURL")
        }
        presentationMode.wrappedValue.dismiss()
    }
}

struct ServerSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        ServerSettingsView()
    }
}
