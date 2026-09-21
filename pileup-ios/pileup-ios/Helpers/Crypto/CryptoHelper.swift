import Foundation

extension Data {
    var bytes: [UInt8] {
        return [UInt8](self)
    }
}

/// =========================================================================
/// END-TO-END ENCRYPTION (E2EE) ROUTER
/// =========================================================================
/// This class acts as an interceptor to provide backward compatibility.
/// 
/// V1 (Legacy): Used MD5 and EVP_BytesToKey within CryptoJS. 
///              Produces ciphertexts starting with 'U2FsdGVkX1'.
///              Maintained ONLY for reading existing data in the DB.
/// 
/// V2 (Modern): Uses pure AES-256-CBC with explicitly generated 16-byte IVs.
///              Produces ciphertexts in the format 'IV(hex):Ciphertext(b64)'.
///              Used for ALL new encryptions (new items, or when editing old items).
/// =========================================================================
class CryptoHelper {
    
    // ---------------------------------------------------------
    // 1. KEY GENERATION (Always V2)
    // ---------------------------------------------------------
    static func generateMasterKey() -> String {
        return CryptoV2.generateMasterKey()
    }
    
    // ---------------------------------------------------------
    // 2. KEK DERIVATION (Context Aware)
    // ---------------------------------------------------------
    static func deriveKeyEncryptionKey(password: String, salt: String, isLegacyV1: Bool = false) -> String {
        if isLegacyV1 {
            return CryptoV1.deriveKeyEncryptionKey(password: password, salt: salt)
        }
        return CryptoV2.deriveKeyEncryptionKey(password: password, salt: salt)
    }
    
    // ---------------------------------------------------------
    // 3. DATA ENCRYPTION (Always V2)
    // ---------------------------------------------------------
    static func encryptData(_ text: String, key keyHex: String) -> String? {
        return CryptoV2.encryptData(text, key: keyHex)
    }
    
    // ---------------------------------------------------------
    // 4. DATA DECRYPTION (Context Aware)
    // ---------------------------------------------------------
    static func decryptData(_ ciphertextPayload: String, key keyHex: String) -> String? {
        if ciphertextPayload.hasPrefix("U2FsdGVkX1") {
            return CryptoV1.decryptData(ciphertextPayload, key: keyHex)
        } else if ciphertextPayload.contains(":") {
            return CryptoV2.decryptData(ciphertextPayload, key: keyHex)
        }
        return ciphertextPayload // Fallback for unencrypted data
    }
}
