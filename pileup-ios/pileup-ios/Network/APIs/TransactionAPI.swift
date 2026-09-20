import Foundation

protocol TransactionAPIProtocol: Sendable {
    func createMovement(payload: MovementPayload) async throws -> MovementResponse
    func getMovements(page: Int?, pageSize: String?, year: String?, month: String?, tipo: String?, categoria: Int?) async throws -> [MovementItem]
    func getPaginatedMovements(page: Int?, pageSize: String?, year: String?, month: String?, tipo: String?, categoria: Int?) async throws -> PaginatedListResponse<MovementItem>
    func getMovement(id: Int) async throws -> MovementItem
    func deleteMovement(id: Int) async throws
}

final class TransactionAPI: TransactionAPIProtocol, @unchecked Sendable {
    nonisolated static let shared = TransactionAPI()
    private let network: NetworkManager
    
    init(network: NetworkManager = .shared) {
        self.network = network
    }
    
    func createMovement(payload: MovementPayload) async throws -> MovementResponse {
        let body = try JSONEncoder().encode(payload)
        return try await network.request(
            endpoint: "movimenti/",
            method: "POST",
            body: body
        )
    }
    
    func getPaginatedMovements(
        page: Int? = nil,
        pageSize: String? = nil,
        year: String? = nil,
        month: String? = nil,
        tipo: String? = nil,
        categoria: Int? = nil
    ) async throws -> PaginatedListResponse<MovementItem> {
        var queryItems: [URLQueryItem] = []
        if let page = page {
            queryItems.append(URLQueryItem(name: "page", value: "\(page)"))
        }
        if let pageSize = pageSize {
            queryItems.append(URLQueryItem(name: "page_size", value: pageSize))
        }
        if let year = year, year != "Totale" {
            queryItems.append(URLQueryItem(name: "year", value: year))
        }
        if let month = month {
            queryItems.append(URLQueryItem(name: "month", value: month))
        }
        if let tipo = tipo {
            queryItems.append(URLQueryItem(name: "tipo", value: tipo))
        }
        if let categoria = categoria {
            queryItems.append(URLQueryItem(name: "categoria", value: "\(categoria)"))
        }
        
        do {
            let paginated: PaginatedListResponse<MovementItem> = try await network.request(
                endpoint: "movimenti/",
                method: "GET",
                queryItems: queryItems
            )
            return paginated
        } catch {
            // Fallback if backend returned plain list
            let list: [MovementItem] = try await network.request(
                endpoint: "movimenti/",
                method: "GET",
                queryItems: queryItems
            )
            return PaginatedListResponse(count: list.count, next: nil, previous: nil, results: list)
        }
    }
    
    func getMovements(
        page: Int? = nil,
        pageSize: String? = nil,
        year: String? = nil,
        month: String? = nil,
        tipo: String? = nil,
        categoria: Int? = nil
    ) async throws -> [MovementItem] {
        let response = try await getPaginatedMovements(
            page: page,
            pageSize: pageSize,
            year: year,
            month: month,
            tipo: tipo,
            categoria: categoria
        )
        return response.results
    }
    
    func getMovement(id: Int) async throws -> MovementItem {
        return try await network.request(
            endpoint: "movimenti/\(id)/",
            method: "GET"
        )
    }
    
    func deleteMovement(id: Int) async throws {
        try await network.request(
            endpoint: "movimenti/\(id)/",
            method: "DELETE"
        )
    }
}
