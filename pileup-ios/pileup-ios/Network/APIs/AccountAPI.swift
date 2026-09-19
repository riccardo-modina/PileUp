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
