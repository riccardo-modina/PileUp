//
// PileUp - Personal finance tracking platform
// Copyright (C) 2025-2026 PileUp
//
// Licensed under the GNU Affero General Public License v3.0.
// See LICENSE in the project root for full license details.
//

import SwiftUI

@MainActor
final class NavigationCoordinator: ObservableObject {

    // Struct to represent a new view with a new navigation stack
    // Modal coming from the bottom while a simple left push is a n.r. to add to the stack 
    struct PresentedRoute: Identifiable {
        let route: NavigationRoute
        let coordinator: NavigationCoordinator

        var id: String { route.id }
    }

    // The stack of navigation routes
    @Published var path: [NavigationRoute] = []

    //The current View displayed
    @Published var presentedSheet: PresentedRoute?
    @Published var presentedFullScreen: PresentedRoute?

    // MARK: - Stack manipulation

    func navigateTo(_ route: NavigationRoute) {
        switch route.transitionStyle {
        case .push:
            // Add to stack, slide from left for example
            path.append(route)

        case .sheet:
            // New stack for the sheet, a modal, come from the bottom usually 
            presentedSheet = PresentedRoute(
                route: route,
                coordinator: NavigationCoordinator()
            )

        case .fullscreen:
            // TODO: Still not used
            // full screen modal, usually slide from bottom with a bigger transition
            withAnimation {
                presentedFullScreen = PresentedRoute(
                    route: route,
                    coordinator: NavigationCoordinator()
                )
            }
        }
    }

    // Remove the last view from the stack
    func pop() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }
    // Empty stack 
    func popToRoot() {
        path.removeAll()
    }
    // Close the sheet
    func dismissSheet() {
        presentedSheet = nil
    }
    // Close the full screen modal
    func dismissFullScreen() {
        presentedFullScreen = nil
    }
}

