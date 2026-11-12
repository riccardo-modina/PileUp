//
// PileUp - Personal finance tracking platform
// Copyright (C) 2025-2026 PileUp
//
// Licensed under the GNU Affero General Public License v3.0.
// See LICENSE in the project root for full license details.
//

import Foundation
import SwiftUI

struct NavigationRoute: Identifiable, Hashable {

    enum TransitionStyle: Hashable {

        case push
        case sheet
        case fullscreen // STILL NOT USED. TODO: Onboarding, legalview and lockscreen.
    }

    // TODO: make it computed considering parameters passed in the view to avoid conflict
    // Example: movementDetail + movement.id since divverent movement does not change id
    let id: String

    private let content: AnyView

    let transitionStyle: TransitionStyle

    // MARK: init
    init(
        id: String,
        style: TransitionStyle = .push,
        @ViewBuilder content: () -> some View
    ) {
        self.id = id
        self.content = AnyView(content())
        self.transitionStyle = style
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.id == rhs.id
    }

    // MARK:View to be displayed
    var destination: some View {
        content
    }
}
