import Foundation
import Security
import LocalAuthentication

class KeychainManager {
    static let shared = KeychainManager()
    private let account = "E2E_MasterKey"
    private var cachedMasterKey: String? = nil
    
    func saveMasterKey(_ key: String) -> Bool {
        guard let data = key.data(using: .utf8) else { return false }
        
        let accessControl = SecAccessControlCreateWithFlags(
            nil,
            kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
            .biometryAny, // Requires Face ID / Touch ID
            nil
        )
        
        guard let access = accessControl else { return false }
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: account,
            kSecValueData as String: data,
            kSecAttrAccessControl as String: access
        ]
        
        // Delete any existing key first
        _ = deleteMasterKey()
        
        let status = SecItemAdd(query as CFDictionary, nil)
        if status == errSecSuccess {
            cachedMasterKey = key
            return true
        }
        return false
    }
    
    func getMasterKey() -> String? {
        if let cached = cachedMasterKey, !cached.isEmpty {
            return cached
        }
        
        let context = LAContext()
        context.localizedReason = "Autenticati per sbloccare la tua chiave di crittografia."
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecUseAuthenticationContext as String: context
        ]
        
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        
        if status == errSecSuccess, let data = item as? Data {
            let key = String(data: data, encoding: .utf8)
            cachedMasterKey = key
            return key
        }
        
        return nil
    }
    
    func deleteMasterKey() -> Bool {
        cachedMasterKey = nil
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: account
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }
    
    /// Clears the in-memory cache without removing the key from Keychain.
    func clearSessionCache() {
        cachedMasterKey = nil
    }
}
