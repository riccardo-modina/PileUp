import Foundation

protocol SettingsAPIProtocol: Sendable {
    func getGlobalSettings() async throws -> GlobalSettings
}

final class SettingsAPI: SettingsAPIProtocol, @unchecked Sendable {
    nonisolated static let shared = SettingsAPI()
    private let network: NetworkManager
    
    init(network: NetworkManager = .shared) {
        self.network = network
    }
    
    func getGlobalSettings() async throws -> GlobalSettings {
        return try await network.request(
            endpoint: "settings/",
            method: "GET"
        )
    }
}
