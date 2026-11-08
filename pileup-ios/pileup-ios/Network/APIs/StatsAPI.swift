//
// PileUp - Personal finance tracking platform
// Copyright (C) 2025-2026 PileUp
//
// Licensed under the GNU Affero General Public License v3.0.
// See LICENSE in the project root for full license details.
//

import Foundation

protocol StatsAPIProtocol: Sendable {
    func getMonthlyStats(year: String, month: String?, months: [String]?) async throws -> MonthlyStatsResponse
    func getAllYearsTotals() async throws -> MonthlyStatsResponse
}

extension StatsAPIProtocol {
    func getMonthlyStats(year: String, months: [String]? = nil) async throws -> MonthlyStatsResponse {
        try await getMonthlyStats(year: year, month: nil, months: months)
    }
}

final class StatsAPI: StatsAPIProtocol, @unchecked Sendable {
    nonisolated static let shared = StatsAPI()
    private let network: NetworkManager

    init(network: NetworkManager = .shared) {
        self.network = network
    }

    func getMonthlyStats(year: String, month: String? = nil, months: [String]? = nil) async throws -> MonthlyStatsResponse {
        var queryItems = [URLQueryItem(name: "year", value: year)]
        if let month {
            queryItems.append(URLQueryItem(name: "month", value: month))
        }
        if let months, !months.isEmpty {
            queryItems.append(URLQueryItem(name: "months", value: months.joined(separator: ",")))
        }

        return try await network.request(
            endpoint: "stats/monthly/",
            method: "GET",
            queryItems: queryItems
        )
    }

    func getAllYearsTotals() async throws -> MonthlyStatsResponse {
        try await network.request(
            endpoint: "stats/monthly/",
            method: "GET",
            queryItems: [URLQueryItem(name: "year", value: "Totale")]
        )
    }
}
