import SwiftUI

struct ServerSettingsView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var customURL: String = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Configurazione Server"), footer: Text("Lascia vuoto per utilizzare il server cloud. Assicurati di includere http:// o https:// e terminare con /api/ se utilizzi un server locale/personalizzato.")) {
                    TextField("Es. http://192.168.1.100:8080/api/", text: $customURL)
                        .keyboardType(.URL)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                }
                
                Section {
                    Button(action: {
                        customURL = ""
                        saveURL()
                    }) {
                        Text("Ripristina Predefinito")
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationBarTitle("Impostazioni Server", displayMode: .inline)
            .navigationBarItems(
                leading: Button("Annulla") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("Salva") {
                    saveURL()
                }
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
