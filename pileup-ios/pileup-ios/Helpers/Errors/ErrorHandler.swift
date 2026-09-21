import Foundation

/// Strongly-typed application errors with centralized Italian descriptions:
/// - Login: generic ("Credenziali non corrette")
/// - Registration: specific per field (so the user understands what to fix)
/// - Network: sensibly grouped (offline vs server unreachable)
enum AppError: LocalizedError, Sendable, Equatable {
    // MARK: - Auth & Session (Generici)
    case invalidCredentials     // "Credenziali non corrette" (password errata, utente inesistente, ecc.)
    case sessionExpired          // "Sessione scaduta"
    case accessDenied            // "Accesso negato"
    
    // MARK: - Registration (Specifici per guidare l'utente)
    case usernameTaken           // "Nome utente già in uso"
    case usernameInvalid         // "Nome utente non valido"
    case emailTaken              // "Email già registrata"
    case emailInvalid            // "Email non valida"
    case passwordTooShort        // "Password troppo corta (minimo 8 caratteri)"
    case passwordTooCommon       // "Password troppo comune o semplice"
    case passwordInvalid         // "Password non valida"
    case inviteCodeInvalid       // "Codice invito non valido"
    case registrationFailed      // "Registrazione non riuscita"
    
    // MARK: - Security & Biometrics
    case biometricsFailed        // "Face ID non riuscito"
    case keyDerivationFailed     // "Errore generazione chiavi"
    
    // MARK: - Network & Server (Accorpati con senso)
    case noInternet              // "Nessuna connessione a Internet"
    case serverUnreachable       // "Impossibile raggiungere il server" (timeout, offline, 502/503/504)
    case invalidURL              // "Indirizzo server non valido"
    
    // MARK: - Generic
    case generic(String)
    
    var errorDescription: String? {
        switch self {
        // Auth (Generico al login)
        case .invalidCredentials:
            return "Credenziali non corrette"
        case .sessionExpired:
            return "Sessione scaduta"
        case .accessDenied:
            return "Accesso negato"
            
        // Registrazione (Specifici per capire cosa non va)
        case .usernameTaken:
            return "Nome utente già in uso"
        case .usernameInvalid:
            return "Nome utente non valido"
        case .emailTaken:
            return "Email già registrata"
        case .emailInvalid:
            return "Email non valida"
        case .passwordTooShort:
            return "Password troppo corta (minimo 8 caratteri)"
        case .passwordTooCommon:
            return "Password troppo comune o semplice"
        case .passwordInvalid:
            return "Password non valida"
        case .inviteCodeInvalid:
            return "Codice invito non valido"
        case .registrationFailed:
            return "Registrazione non riuscita"
            
        // Biometria
        case .biometricsFailed:
            return "Face ID non riuscito"
        case .keyDerivationFailed:
            return "Errore generazione chiavi"
            
        // Rete (casi chiari)
        case .noInternet:
            return "Nessuna connessione a Internet"
        case .serverUnreachable:
            return "Impossibile raggiungere il server"
        case .invalidURL:
            return "Indirizzo server non valido"
            
        case .generic(let message):
            return message
        }
    }
}

/// Centralized utility to parse and map all errors to AppError.
struct ErrorHandler: Sendable {
    
    /// Maps any error into a clean user-facing Italian string.
    nonisolated static func format(_ error: Error) -> String {
        if let appError = error as? AppError {
            return appError.errorDescription ?? "Si è verificato un errore"
        }
        
        let mapped = mapToAppError(error)
        return mapped.errorDescription ?? "Si è verificato un errore"
    }
    
    /// Maps any system or network error to an AppError instance.
    nonisolated static func mapToAppError(_ error: Error) -> AppError {
        if let appError = error as? AppError {
            return appError
        }
        
        let nsError = error as NSError
        
        // 1. URLSession connectivity errors (raggruppati con senso)
        if nsError.domain == NSURLErrorDomain {
            if nsError.code == NSURLErrorNotConnectedToInternet {
                return .noInternet
            } else {
                return .serverUnreachable
            }
        }
        
        let desc = nsError.localizedDescription
        
        // 2. Embedded JSON or server message
        if let parsed = parseEmbeddedJSON(from: desc) {
            return parsed
        }
        
        // 3. Known phrases
        if let matched = matchKnownPhrases(desc) {
            return matched
        }
        
        return .generic(desc.isEmpty || desc.contains("NSError") ? "Si è verificato un errore" : desc)
    }
    
    /// Parses raw response Data and HTTP status code from NetworkManager into an AppError.
    nonisolated static func parseBackendError(data: Data, statusCode: Int) -> AppError {
        // Any 401 Unauthorized is invalid credentials (stops info leakage at login)
        if statusCode == 401 {
            return .invalidCredentials
        }
        
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            return parseJSONDictionary(json, statusCode: statusCode)
        } else if let rawString = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines), !rawString.isEmpty {
            if rawString.hasPrefix("<") {
                return statusCodeToAppError(statusCode)
            }
            if let matched = matchKnownPhrases(rawString) {
                return matched
            }
        }
        return statusCodeToAppError(statusCode)
    }
    
    // MARK: - Internal Parsing
    
    private nonisolated static func parseJSONDictionary(_ json: [String: Any], statusCode: Int) -> AppError {
        // Direct detail message (e.g. Djoser / DRF auth errors)
        if let detail = json["detail"] as? String {
            if let matched = matchKnownPhrases(detail) {
                return matched
            }
        }
        
        // Generic error/message keys
        if let errorMsg = json["error"] as? String, let matched = matchKnownPhrases(errorMsg) {
            return matched
        }
        if let msg = json["message"] as? String, let matched = matchKnownPhrases(msg) {
            return matched
        }
        
        // Field validation errors (e.g. { "username": ["..."], "password": ["..."] })
        let prioritizedKeys = ["detail", "username", "email", "password", "invite_code", "non_field_errors"]
        let sortedKeys = json.keys.sorted { (k1, k2) -> Bool in
            let idx1 = prioritizedKeys.firstIndex(of: k1) ?? 99
            let idx2 = prioritizedKeys.firstIndex(of: k2) ?? 99
            return idx1 < idx2
        }
        
        for key in sortedKeys {
            if let messages = json[key] as? [String], let first = messages.first {
                return mapFieldToAppError(key: key, message: first)
            } else if let message = json[key] as? String {
                return mapFieldToAppError(key: key, message: message)
            }
        }
        
        return statusCodeToAppError(statusCode)
    }
    
    private nonisolated static func parseEmbeddedJSON(from text: String) -> AppError? {
        guard let start = text.firstIndex(of: "{"), let end = text.lastIndex(of: "}") else {
            return nil
        }
        let jsonSubstring = String(text[start...end])
        guard let jsonData = jsonSubstring.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] else {
            return nil
        }
        return parseJSONDictionary(json, statusCode: 400)
    }
    
    private nonisolated static func mapFieldToAppError(key: String, message: String) -> AppError {
        let lower = message.lowercased()
        
        switch key.lowercased() {
        case "username":
            if lower.contains("already exists") || lower.contains("già in uso") || lower.contains("already in use") {
                return .usernameTaken
            }
            return .usernameInvalid
            
        case "email":
            if lower.contains("already exists") || lower.contains("già") {
                return .emailTaken
            }
            return .emailInvalid
            
        case "password":
            if lower.contains("too short") || lower.contains("8 characters") || lower.contains("corta") {
                return .passwordTooShort
            }
            if lower.contains("too common") || lower.contains("comune") {
                return .passwordTooCommon
            }
            return .passwordInvalid
            
        case "invite_code":
            return .inviteCodeInvalid
            
        default:
            return matchKnownPhrases(message) ?? .generic(message)
        }
    }
    
    private nonisolated static func matchKnownPhrases(_ text: String) -> AppError? {
        let lower = text.lowercased()
        
        // 1. Auth & Credentials -> sempre generico per il login ("Credenziali non corrette")
        if lower.contains("nessun account") ||
           lower.contains("no active account") ||
           lower.contains("unable to log in") ||
           lower.contains("invalid credentials") ||
           lower.contains("credenziali non") ||
           lower.contains("credenziali") ||
           lower.contains("user not found") ||
           lower.contains("utente non trovato") ||
           lower.contains("password non valida") ||
           lower.contains("password errata") ||
           lower.contains("password non corretta") ||
           lower.contains("decrittografia") {
            return .invalidCredentials
        }
        
        // 2. Session
        if lower.contains("token not valid") ||
           lower.contains("session expired") ||
           lower.contains("token is expired") ||
           lower.contains("sessione scaduta") {
            return .sessionExpired
        }
        
        // 3. Permission
        if lower.contains("credentials were not provided") ||
           lower.contains("you do not have permission") {
            return .accessDenied
        }
        
        // 4. Security & Biometrics
        if lower.contains("face id") {
            return .biometricsFailed
        }
        if lower.contains("chiavi") {
            return .keyDerivationFailed
        }
        
        // 5. Network (accorpati a "Impossibile raggiungere il server")
        if lower.contains("nsurlerrordomain") ||
           lower.contains("the operation couldn’t be completed") ||
           lower.contains("network error") ||
           lower.contains("timed out") ||
           lower.contains("server") {
            return .serverUnreachable
        }
        
        return nil
    }
    
    private nonisolated static func statusCodeToAppError(_ code: Int) -> AppError {
        switch code {
        case 401:
            return .invalidCredentials
        case 403:
            return .accessDenied
        case 404:
            return .generic("Elemento non trovato")
        case 429:
            return .generic("Troppi tentativi. Riprova più tardi")
        case 500, 502, 503, 504:
            return .serverUnreachable
        default:
            return .generic("Dati non validi")
        }
    }
}
