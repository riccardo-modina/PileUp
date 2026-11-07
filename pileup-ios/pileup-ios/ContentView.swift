//
// PileUp - Personal finance tracking platform
// Copyright (C) 2024-2026 PileUp
//
// Licensed under the GNU Affero General Public License v3.0.
// See LICENSE in the project root for full license details.
//

import SwiftUI

struct ContentView: View {
    @StateObject
    private var authViewModel = AuthViewModel()

    var body: some View {
        if authViewModel.isAuthenticated {
            MainTabView(authViewModel: authViewModel)
        } else if authViewModel.needsUnlock {
            UnlockView(viewModel: authViewModel)
        } else {
            LoginView(viewModel: authViewModel)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
