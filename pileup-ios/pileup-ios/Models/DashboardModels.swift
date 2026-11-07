//
// PileUp - Personal finance tracking platform
// Copyright (C) 2024-2026 PileUp
//
// Licensed under the GNU Affero General Public License v3.0.
// See LICENSE in the project root for full license details.
//

import Foundation

nonisolated struct MonthlyStat: Codable, Identifiable, Sendable {
    var id: String {
        month
    }

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
