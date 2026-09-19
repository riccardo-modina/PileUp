import Foundation
import SwiftUI
import Combine

class AuthViewModel: ObservableObject {
    @Published var isAuthenticated: Bool = false
    @Published var needsUnlock: Bool = false
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    
    @Published var userProfile: UserProfile? = nil
    @Published var masterKey: String? = nil
    @Published var globalSettings: GlobalSettings? = nil
    
    private let authAPI: AuthAPIProtocol
    private let settingsAPI: SettingsAPIProtocol
    
    init(
        authAPI: AuthAPIProtocol = AuthAPI.shared,
        settingsAPI: SettingsAPIProtocol = SettingsAPI.shared
    ) {
        self.authAPI = authAPI
        self.settingsAPI = settingsAPI
        
        checkAuthStatus()
        fetchGlobalSettings()
        
        NotificationCenter.default.addObserver(forName: NSNotification.Name("SessionExpired"), object: nil, queue: .main) { [weak self] _ in
            self?.logout()
        }
    }
    
    func checkAuthStatus() {
        if let _ = UserDefaults.standard.string(forKey: "authToken") {
            // Token is present, we need to unlock the master key
            needsUnlock = true
        }
    }
    
    // Fetches global settings from the API to check if the register feature with invite code is enabled
    func fetchGlobalSettings() {
        Task { @MainActor in
            do {
                let settings = try await self.settingsAPI.getGlobalSettings()
                self.globalSettings = settings
            } catch {
                // Fallback silenzioso in caso di errore fetch settings
            }
        }
    }
    
    // Called by UnlockView when Face ID button is clicked
    func unlockWithBiometrics() {
        if let key = KeychainManager.shared.getMasterKey() {
            DispatchQueue.main.async {
                self.masterKey = key
                self.isAuthenticated = true
                self.needsUnlock = false
                self.errorMessage = nil
            }
        } else {
            DispatchQueue.main.async {
                self.errorMessage = "Face ID non riuscito o annullato. Inserisci la password."
            }
        }
    }
    
    // Called by UnlockView when user manually enters password
    func unlockWithPassword(_ password: String) {
        let username = UserDefaults.standard.string(forKey: "username") ?? ""
        login(username: username, password: password)
    }
    
    func login(username: String, password: String) {
        isLoading = true
        errorMessage = nil
        
        let credentials = LoginRequest(username: username, password: password)
        
        Task { @MainActor in
            do {
                let response = try await self.authAPI.login(credentials: credentials)
                UserDefaults.standard.set(response.access, forKey: "authToken")
                UserDefaults.standard.set(response.refresh, forKey: "refreshToken") // Save refresh token
                UserDefaults.standard.set(username, forKey: "username") // Save username right after successful login
                self.fetchProfileAndDeriveKey(password: password, username: username)
            } catch {
                self.isLoading = false
                self.errorMessage = "Invalid credentials or network error. (\(error.localizedDescription))"
            }
        }
    }
    
    private func fetchProfileAndDeriveKey(password: String, username: String) {
        isLoading = true
        errorMessage = nil
        
        Task { @MainActor in
            do {
                let profile = try await self.authAPI.getUserProfile()
                self.isLoading = false
                self.userProfile = profile
                
                if let encryptedMasterKey = profile.encrypted_master_key, !encryptedMasterKey.isEmpty {
                    // Rileva se è la vecchia versione
                    let isLegacy = encryptedMasterKey.hasPrefix("U2FsdGVkX1")
                    
                    // Derive KEK (210k per V2, 100k per V1)
                    let kek = CryptoHelper.deriveKeyEncryptionKey(password: password, salt: username, isLegacyV1: isLegacy)
                    
                    // Decrypt Master Key
                    if let decryptedKey = CryptoHelper.decryptData(encryptedMasterKey, key: kek) {
                        self.masterKey = decryptedKey
                        // Save to Keychain for future Face ID unlocks
                        _ = KeychainManager.shared.saveMasterKey(decryptedKey)
                        
                        self.isAuthenticated = true
                        self.needsUnlock = false
                    } else {
                        self.errorMessage = "Password non valida per la decrittografia E2E."
                    }
                } else {
                    // Registration hasn't set an E2E key yet, or older account.
                    // Ideally shouldn't happen with new flow.
                    self.isAuthenticated = true
                    self.needsUnlock = false
                }
            } catch {
                self.isLoading = false
                self.errorMessage = "Errore durante il recupero del profilo: \(error.localizedDescription)"
            }
        }
    }
    
    func register(username: String, email: String, password: String, inviteCode: String?) async throws -> String? {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        // 1. Genera chiavi E2E
        let newMasterKey = CryptoHelper.generateMasterKey()
        let kek = CryptoHelper.deriveKeyEncryptionKey(password: password, salt: username)
        guard let encryptedMasterKey = CryptoHelper.encryptData(newMasterKey, key: kek) else {
            await MainActor.run {
                self.errorMessage = "Errore nella generazione delle chiavi crittografiche."
                self.isLoading = false
            }
            return nil
        }
        
        let request = RegisterRequest(
            username: username,
            email: email,
            password: password,
            encrypted_master_key: encryptedMasterKey,
            invite_code: inviteCode
        )
        
        do {
            let _ = try await authAPI.register(request: request)
            await MainActor.run { self.isLoading = false }
            return newMasterKey
        } catch {
            await MainActor.run {
                self.errorMessage = "Errore durante la registrazione. L'username potrebbe essere già in uso. (\(error.localizedDescription))"
                self.isLoading = false
            }
            throw error
        }
    }
    
    func logout() {
        UserDefaults.standard.removeObject(forKey: "authToken")
        UserDefaults.standard.removeObject(forKey: "refreshToken")
        _ = KeychainManager.shared.deleteMasterKey()
        isAuthenticated = false
        needsUnlock = false
        masterKey = nil
        userProfile = nil
    }
}
