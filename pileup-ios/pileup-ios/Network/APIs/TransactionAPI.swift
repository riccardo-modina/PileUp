import Foundation

protocol TransactionAPIProtocol: Sendable {
    func createMovement(payload: MovementPayload) async throws -> MovementResponse
    func getMovements(page: Int?, pageSize: String?, year: String?, month: String?) async throws -> [MovementResponse]
    func getMovement(id: Int) async throws -> MovementResponse
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
    
    func getMovements(page: Int? = nil, pageSize: String? = nil, year: String? = nil, month: String? = nil) async throws -> [MovementResponse] {
        var queryItems: [URLQueryItem] = []
        if let page = page {
            queryItems.append(URLQueryItem(name: "page", value: "\(page)"))
        }
        if let pageSize = pageSize {
            queryItems.append(URLQueryItem(name: "page_size", value: pageSize))
        }
        if let year = year {
            queryItems.append(URLQueryItem(name: "year", value: year))
        }
        if let month = month {
            queryItems.append(URLQueryItem(name: "month", value: month))
        }
        
        do {
            let paginated: PaginatedListResponse<MovementResponse> = try await network.request(
                endpoint: "movimenti/",
                method: "GET",
                queryItems: queryItems
            )
            return paginated.results
        } catch {
            return try await network.request(
                endpoint: "movimenti/",
                method: "GET",
                queryItems: queryItems
            )
        }
    }
    
    func getMovement(id: Int) async throws -> MovementResponse {
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
