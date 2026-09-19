import Foundation

protocol StatsAPIProtocol: Sendable {
    func getMonthlyStats(year: String, months: [String]?) async throws -> MonthlyStatsResponse
    func getAllYearsTotals() async throws -> MonthlyStatsResponse
}

final class StatsAPI: StatsAPIProtocol, @unchecked Sendable {
    nonisolated static let shared = StatsAPI()
    private let network: NetworkManager
    
    init(network: NetworkManager = .shared) {
        self.network = network
    }
    
    func getMonthlyStats(year: String, months: [String]? = nil) async throws -> MonthlyStatsResponse {
        var queryItems = [URLQueryItem(name: "year", value: year)]
        if let months = months, !months.isEmpty {
            queryItems.append(URLQueryItem(name: "months", value: months.joined(separator: ",")))
        }
        
        return try await network.request(
            endpoint: "stats/monthly/",
            method: "GET",
            queryItems: queryItems
        )
    }
    
    func getAllYearsTotals() async throws -> MonthlyStatsResponse {
        return try await network.request(
            endpoint: "stats/monthly/",
            method: "GET",
            queryItems: [URLQueryItem(name: "year", value: "Totale")]
        )
    }
}
