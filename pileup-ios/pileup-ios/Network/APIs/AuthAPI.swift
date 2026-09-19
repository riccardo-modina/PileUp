import Foundation

protocol AuthAPIProtocol: Sendable {
    func login(credentials: LoginRequest) async throws -> TokenResponse
    func register(request: RegisterRequest) async throws -> UserProfile
    func getUserProfile() async throws -> UserProfile
    func getGlobalSettings() async throws -> GlobalSettings
}

final class AuthAPI: AuthAPIProtocol, @unchecked Sendable {
    nonisolated static let shared = AuthAPI()
    private let network: NetworkManager
    
    init(network: NetworkManager = .shared) {
        self.network = network
    }
    
    func login(credentials: LoginRequest) async throws -> TokenResponse {
        let body = try JSONEncoder().encode(credentials)
        return try await network.request(
            endpoint: "auth/jwt/create/",
            method: "POST",
            body: body
        )
    }
    
    func register(request: RegisterRequest) async throws -> UserProfile {
        let body = try JSONEncoder().encode(request)
        return try await network.request(
            endpoint: "auth/register/",
            method: "POST",
            body: body
        )
    }
    
    func getUserProfile() async throws -> UserProfile {
        return try await network.request(
            endpoint: "auth/profile/",
            method: "GET"
        )
    }
    
    func getGlobalSettings() async throws -> GlobalSettings {
        return try await network.request(
            endpoint: "settings/",
            method: "GET"
        )
    }
}
