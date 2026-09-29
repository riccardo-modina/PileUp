import Foundation

protocol AccountAPIProtocol: Sendable {
    func getAllAccounts() async throws -> [AccountItem]
    func getAccounts(page: Int, pageSize: Int) async throws -> [AccountItem]
}

final class AccountAPI: AccountAPIProtocol, @unchecked Sendable {
    nonisolated static let shared = AccountAPI()
    private let network: NetworkManager
    
    init(network: NetworkManager = .shared) {
        self.network = network
    }
    
    /// Fetches all user accounts.
    /// NOTE FOR FUTURE DEVELOPMENT: When account management endpoints (create, edit, delete) are implemented
    /// (e.g. POST/PUT/DELETE /conti/), call `PendingTransactionsStore.shared.updateAccountsCache(...)`
    /// to keep the local offline accounts cache in sync for Apple Wallet background card matching.
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
}
