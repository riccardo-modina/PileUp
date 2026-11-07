//
// PileUp - Personal finance tracking platform
// Copyright (C) 2024-2026 PileUp
//
// Licensed under the GNU Affero General Public License v3.0.
// See LICENSE in the project root for full license details.
//

import Foundation

protocol TransactionAPIProtocol: Sendable {
    func createMovement(payload: MovementPayload) async throws -> MovementResponse
    func getMovements(page: Int?, pageSize: String?, year: String?, month: String?, tipo: String?, categoria: Int?) async throws
        -> [MovementItem]
    func getPaginatedMovements(page: Int?, pageSize: String?, year: String?, month: String?, tipo: String?, categoria: Int?) async throws
        -> PaginatedListResponse<MovementItem>
    func getMovement(id: Int) async throws -> MovementItem
    func updateMovement(id: Int, payload: MovementPayload) async throws -> MovementResponse
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
        if let page {
            queryItems.append(URLQueryItem(name: "page", value: "\(page)"))
        }
        if let pageSize {
            queryItems.append(URLQueryItem(name: "page_size", value: pageSize))
        }
        if let year, year != "Totale" {
            queryItems.append(URLQueryItem(name: "year", value: year))
        }
        if let month {
            queryItems.append(URLQueryItem(name: "month", value: month))
        }
        if let tipo {
            queryItems.append(URLQueryItem(name: "tipo", value: tipo))
        }
        if let categoria {
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
        try await network.request(
            endpoint: "movimenti/\(id)/",
            method: "GET"
        )
    }

    func updateMovement(id: Int, payload: MovementPayload) async throws -> MovementResponse {
        let body = try JSONEncoder().encode(payload)
        return try await network.request(
            endpoint: "movimenti/\(id)/",
            method: "PATCH",
            body: body
        )
    }

    func deleteMovement(id: Int) async throws {
        try await network.request(
            endpoint: "movimenti/\(id)/",
            method: "DELETE"
        )
    }
}
