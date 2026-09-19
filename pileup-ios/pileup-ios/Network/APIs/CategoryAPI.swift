import Foundation

protocol CategoryAPIProtocol: Sendable {
    func getAllCategories() async throws -> [CategoryItem]
    func getCategories(page: Int, pageSize: Int) async throws -> [CategoryItem]
}

final class CategoryAPI: CategoryAPIProtocol, @unchecked Sendable {
    nonisolated static let shared = CategoryAPI()
    private let network: NetworkManager
    
    init(network: NetworkManager = .shared) {
        self.network = network
    }
    
    func getAllCategories() async throws -> [CategoryItem] {
        return try await network.request(
            endpoint: "categorie/",
            method: "GET",
            queryItems: [URLQueryItem(name: "page_size", value: "all")]
        )
    }
    
    func getCategories(page: Int = 1, pageSize: Int = 10) async throws -> [CategoryItem] {
        let queryItems = [
            URLQueryItem(name: "page", value: "\(page)"),
            URLQueryItem(name: "page_size", value: "\(pageSize)")
        ]
        do {
            let paginated: PaginatedListResponse<CategoryItem> = try await network.request(
                endpoint: "categorie/",
                method: "GET",
                queryItems: queryItems
            )
            return paginated.results
        } catch {
            return try await network.request(
                endpoint: "categorie/",
                method: "GET",
                queryItems: queryItems
            )
        }
    }
}
