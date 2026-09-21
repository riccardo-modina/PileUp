import Foundation
import CryptoKit
import CommonCrypto

/// --- V1 LEGACY CRYPTO ---
/// Maintains backward compatibility for old data encrypted with MD5 + EVP_BytesToKey.
/// Used exclusively for reading. New data is never encrypted with V1.
class CryptoV1 {
    
    /// Derives a Key Encryption Key (KEK) using PBKDF2 (100,000 iterations for legacy users)
    static func deriveKeyEncryptionKey(password: String, salt: String) -> String {
        guard let passwordData = password.data(using: .utf8),
              let saltData = salt.data(using: .utf8) else { return "" }
        
        var derivedBytes = [UInt8](repeating: 0, count: 32)
        
        let status = CCKeyDerivationPBKDF(
            CCPBKDFAlgorithm(kCCPBKDF2),
            passwordData.bytes,
            passwordData.count,
            saltData.bytes,
            saltData.count,
            CCPseudoRandomAlgorithm(kCCPRFHmacAlgSHA256),
            100000,
            &derivedBytes,
            derivedBytes.count
        )
        
        if status == kCCSuccess {
            return derivedBytes.map { String(format: "%02x", $0) }.joined()
        }
        return ""
    }
    
    private static func evpKDF(password: String, salt: Data, keySize: Int, ivSize: Int) -> (key: Data, iv: Data) {
        var d = Data()
        var d_i = Data()
        let passwordData = password.data(using: .utf8)!
        
        while d.count < (keySize + ivSize) {
            var dataToHash = Data()
            dataToHash.append(d_i)
            dataToHash.append(passwordData)
            dataToHash.append(salt)
            
            let hash = Insecure.MD5.hash(data: dataToHash)
            d_i = Data(hash)
            d.append(d_i)
        }
        
        let key = d.subdata(in: 0..<keySize)
        let iv = d.subdata(in: keySize..<(keySize + ivSize))
        return (key, iv)
    }
    
    /// Decrypts data using the legacy OpenSSL compatible method
    static func decryptData(_ ciphertext: String, key passphrase: String) -> String? {
        guard let data = Data(base64Encoded: ciphertext), data.count > 16 else { return nil }
        
        let prefix = data.subdata(in: 0..<8)
        guard String(data: prefix, encoding: .utf8) == "Salted__" else { return nil }
        
        let salt = data.subdata(in: 8..<16)
        let encryptedBytes = data.subdata(in: 16..<data.count)
        
        let kdfResult = evpKDF(password: passphrase, salt: salt, keySize: 32, ivSize: 16)
        
        var decryptedBytes = [UInt8](repeating: 0, count: encryptedBytes.count + kCCBlockSizeAES128)
        var numBytesDecrypted = 0
        
        let status = CCCrypt(
            CCOperation(kCCDecrypt),
            CCAlgorithm(kCCAlgorithmAES),
            CCOptions(kCCOptionPKCS7Padding),
            kdfResult.key.bytes,
            kdfResult.key.count,
            kdfResult.iv.bytes,
            encryptedBytes.bytes,
            encryptedBytes.count,
            &decryptedBytes,
            decryptedBytes.count,
            &numBytesDecrypted
        )
        
        if status == kCCSuccess {
            let resultData = Data(bytes: decryptedBytes, count: numBytesDecrypted)
            return String(data: resultData, encoding: .utf8)
        }
        return nil
    }
}
