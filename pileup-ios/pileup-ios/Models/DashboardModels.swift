import Foundation

nonisolated struct MonthlyStat: Codable, Identifiable, Sendable {
    var id: String { month }
    let month: String
    let amount: Double
}

nonisolated struct MonthlyStatsResponse: Codable, Sendable {
    let year: String
    let month: String?
    let income: [MonthlyStat]
    let spending: [MonthlyStat]
    let monthlyIncome: Double
    let monthlyExpense: Double
}
