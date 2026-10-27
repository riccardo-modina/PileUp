import Foundation

protocol CategoryAPIProtocol: Sendable {
    func getAllCategories() async throws -> [CategoryItem]
    func getCategories(page: Int, pageSize: Int) async throws -> [CategoryItem]
    func createCategory(nome: String, tipo: String, color: String) async throws -> CategoryItem
    func updateCategory(id: Int, nome: String, tipo: String, color: String) async throws -> CategoryItem
    func deleteCategory(id: Int) async throws
}

private struct CreateCategoryPayload: Codable, Sendable {
    let nome: String
    let tipo: String
    let color: String
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
    
    func createCategory(nome: String, tipo: String, color: String) async throws -> CategoryItem {
        let payload = CreateCategoryPayload(nome: nome, tipo: tipo, color: color)
        let body = try JSONEncoder().encode(payload)
        return try await network.request(
            endpoint: "categorie/",
            method: "POST",
            body: body
        )
    }
    
    func updateCategory(id: Int, nome: String, tipo: String, color: String) async throws -> CategoryItem {
        let payload = CreateCategoryPayload(nome: nome, tipo: tipo, color: color)
        let body = try JSONEncoder().encode(payload)
        return try await network.request(
            endpoint: "categorie/\(id)/",
            method: "PATCH",
            body: body
        )
    }
    
    func deleteCategory(id: Int) async throws {
        try await network.request(
            endpoint: "categorie/\(id)/",
            method: "DELETE"
        )
    }
}

