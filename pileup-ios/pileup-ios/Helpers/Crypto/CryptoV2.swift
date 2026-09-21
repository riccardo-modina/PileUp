import Foundation
import CommonCrypto

/// --- V2 MODERN CRYPTO ---
/// Uses pure AES-256-CBC with explicitly generated IVs.
/// Bypasses the insecure MD5 EVP_BytesToKey algorithm.
/// Ciphertext format: "IV_HEX:CIPHERTEXT_BASE64"
class CryptoV2 {
    
    /// Generates a random 256-bit (32-byte) Master Key as a hex string
    static func generateMasterKey() -> String {
        var bytes = [UInt8](repeating: 0, count: 32)
        let status = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        if status == errSecSuccess {
            return bytes.map { String(format: "%02x", $0) }.joined()
        }
        return ""
    }
    
    /// Derives a Key Encryption Key (KEK) using PBKDF2 (210,000 iterations for modern users)
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
            210000,
            &derivedBytes,
            derivedBytes.count
        )
        
        if status == kCCSuccess {
            return derivedBytes.map { String(format: "%02x", $0) }.joined()
        }
        return ""
    }
    
    /// Encrypts text into V2 format: "IV_HEX:CIPHERTEXT_BASE64"
    static func encryptData(_ text: String, key keyHex: String) -> String? {
        guard let textData = text.data(using: .utf8) else { return nil }
        
        let keyData = dataFromHex(keyHex)
        guard keyData.count == 32 else { return nil }
        
        var ivBytes = [UInt8](repeating: 0, count: 16)
        _ = SecRandomCopyBytes(kSecRandomDefault, 16, &ivBytes)
        
        var encryptedBytes = [UInt8](repeating: 0, count: textData.count + kCCBlockSizeAES128)
        var numBytesEncrypted = 0
        
        let status = CCCrypt(
            CCOperation(kCCEncrypt),
            CCAlgorithm(kCCAlgorithmAES),
            CCOptions(kCCOptionPKCS7Padding),
            keyData.bytes,
            keyData.count,
            ivBytes,
            textData.bytes,
            textData.count,
            &encryptedBytes,
            encryptedBytes.count,
            &numBytesEncrypted
        )
        
        if status == kCCSuccess {
            let ivHex = Data(ivBytes).map { String(format: "%02x", $0) }.joined()
            let ciphertextBase64 = Data(bytes: encryptedBytes, count: numBytesEncrypted).base64EncodedString()
            return "\(ivHex):\(ciphertextBase64)"
        }
        return nil
    }
    
    /// V2 Decrypt: Parses "IV_HEX:CIPHERTEXT_BASE64"
    static func decryptData(_ ciphertextPayload: String, key keyHex: String) -> String? {
        let parts = ciphertextPayload.split(separator: ":")
        guard parts.count == 2 else { return nil }
        
        let ivHex = String(parts[0])
        let ciphertextB64 = String(parts[1])
        
        let keyData = dataFromHex(keyHex)
        let ivData = dataFromHex(ivHex)
        guard let encryptedData = Data(base64Encoded: ciphertextB64) else { return nil }
        
        var decryptedBytes = [UInt8](repeating: 0, count: encryptedData.count + kCCBlockSizeAES128)
        var numBytesDecrypted = 0
        
        let status = CCCrypt(
            CCOperation(kCCDecrypt),
            CCAlgorithm(kCCAlgorithmAES),
            CCOptions(kCCOptionPKCS7Padding),
            keyData.bytes,
            keyData.count,
            ivData.bytes,
            encryptedData.bytes,
            encryptedData.count,
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
    
    private static func dataFromHex(_ hex: String) -> Data {
        var data = Data()
        var hexString = hex
        if hexString.count % 2 != 0 {
            hexString = "0" + hexString
        }
        var startIndex = hexString.startIndex
        while startIndex < hexString.endIndex {
            let endIndex = hexString.index(startIndex, offsetBy: 2)
            let byteString = String(hexString[startIndex..<endIndex])
            if let byte = UInt8(byteString, radix: 16) {
                data.append(byte)
            }
            startIndex = endIndex
        }
        return data
    }
}
