//
// PileUp - Personal finance tracking platform
// Copyright (C) 2025-2026 PileUp
//
// Licensed under the GNU Affero General Public License v3.0.
// See LICENSE in the project root for full license details.
//

import Foundation

protocol SettingsAPIProtocol: Sendable {
    func getGlobalSettings() async throws -> GlobalSettings
}

final class SettingsAPI: SettingsAPIProtocol, @unchecked Sendable {
    nonisolated static let shared = SettingsAPI()
    private let network: NetworkManager

    init(network: NetworkManager = .shared) {
        self.network = network
    }

    func getGlobalSettings() async throws -> GlobalSettings {
        try await network.request(
            endpoint: "settings/",
            method: "GET"
        )
    }
}
