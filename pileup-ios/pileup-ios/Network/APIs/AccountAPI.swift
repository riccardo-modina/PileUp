import Foundation

protocol AccountAPIProtocol: Sendable {
    func getAllAccounts() async throws -> [AccountItem]
    func getAccounts(page: Int, pageSize: Int) async throws -> [AccountItem]
    func createAccount(nome: String, tipo: String, color: String) async throws -> AccountItem
    func updateAccount(id: Int, nome: String, tipo: String, color: String) async throws -> AccountItem
    func deleteAccount(id: Int) async throws
}

private struct CreateAccountPayload: Codable, Sendable {
    let nome: String
    let tipo: String
    let color: String
}

final class AccountAPI: AccountAPIProtocol, @unchecked Sendable {
    nonisolated static let shared = AccountAPI()
    private let network: NetworkManager
    
    init(network: NetworkManager = .shared) {
        self.network = network
    }
    
    /// Fetches all user accounts.
    func getAllAccounts() async throws -> [AccountItem] {
        return try await network.request(
            endpoint: "conti/",
            method: "GET",
            queryItems: [URLQueryItem(name: "page_size", value: "all")]
        )
    }
    
    func getAccounts(page: Int = 1, pageSize: Int = 10) async throws -> [AccountItem] {
        let queryItems = [
            URLQueryItem(name: "page", value: "\(page)"),
            URLQueryItem(name: "page_size", value: "\(pageSize)")
        ]
        do {
            let paginated: PaginatedListResponse<AccountItem> = try await network.request(
                endpoint: "conti/",
                method: "GET",
                queryItems: queryItems
            )
            return paginated.results
        } catch {
            return try await network.request(
                endpoint: "conti/",
                method: "GET",
                queryItems: queryItems
            )
        }
    }
    
    func createAccount(nome: String, tipo: String, color: String) async throws -> AccountItem {
        let payload = CreateAccountPayload(nome: nome, tipo: tipo, color: color)
        let body = try JSONEncoder().encode(payload)
        let created: AccountItem = try await network.request(
            endpoint: "conti/",
            method: "POST",
            body: body
        )
        Task {
            if let all = try? await getAllAccounts() {
                PendingTransactionsStore.shared.updateAccountsCache(all)
            }
        }
        return created
    }
    
    func updateAccount(id: Int, nome: String, tipo: String, color: String) async throws -> AccountItem {
        let payload = CreateAccountPayload(nome: nome, tipo: tipo, color: color)
        let body = try JSONEncoder().encode(payload)
        let updated: AccountItem = try await network.request(
            endpoint: "conti/\(id)/",
            method: "PATCH",
            body: body
        )
        Task {
            if let all = try? await getAllAccounts() {
                PendingTransactionsStore.shared.updateAccountsCache(all)
            }
        }
        return updated
    }
    
    func deleteAccount(id: Int) async throws {
        try await network.request(
            endpoint: "conti/\(id)/",
            method: "DELETE"
        )
        Task {
            if let all = try? await getAllAccounts() {
                PendingTransactionsStore.shared.updateAccountsCache(all)
            }
        }
    }
}
