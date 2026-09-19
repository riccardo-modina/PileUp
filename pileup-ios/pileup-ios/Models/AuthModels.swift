import Foundation

nonisolated struct TokenResponse: Codable, Sendable {
    let access: String
    let refresh: String
}

nonisolated struct LoginRequest: Codable, Sendable {
    let username: String
    let password: String
}

nonisolated struct RegisterRequest: Codable, Sendable {
    let username: String
    let email: String
    let password: String
    let encrypted_master_key: String
    let invite_code: String?
}

nonisolated struct UserProfile: Codable, Sendable {
    let encrypted_master_key: String?
    let recovery_encrypted_master_key: String?
}

nonisolated struct GlobalSettings: Codable, Sendable {
    let is_initialized: Bool
    let allow_registration: Bool
}
