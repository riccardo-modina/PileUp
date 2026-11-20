//
// PileUp - Personal finance tracking platform
// Copyright (C) 2025-2026 PileUp
//
// Licensed under the GNU Affero General Public License v3.0.
// See LICENSE in the project root for full license details.
//

import SwiftUI

struct Router {

    // Weak pointer to a coordinator.
    //
    // Optional because you might not have the coordinator when the view is created
    // or if the coordinator is destroyed by the container.
    // We use weak to avoid ownershipt of the coordinator by the router,
    // the container holds the ownership of the coordinator via the @StateObject wrapper.
    //
    // Used to add a screen to the navigationCoordinator, while the container observes its
    // state to update the actual NavigationStack so the screen that the user sees
    weak var coordinator: NavigationCoordinator?

    // Dismiss action obtained from a view environment, it's needed to close the current view
    // by calling the pop function on the NavigationStack or dismissing the modal.
    let dismissAction: DismissAction

    // Add a route to the navigation stack
    func navigate(to route: NavigationRoute) {
        coordinator?.navigateTo(route)
    }

    // Remove the current view from the navigation stack
    func dismiss() {
        dismissAction()
    }

    // Return to the inital view of the coordinator.
    func popToRoot() {
        coordinator?.popToRoot()
    }
}

// "Global" variable that contains a coordinator.
// It is not unique because it is overriden when a new navigation stack is needed
// for example when modal is opened
//
// defined here since we access it in the property wrapper defined in the next lines
// but the navigation container creates the new instance of the coordinator
extension EnvironmentValues {
    @Entry
    var coordinator: NavigationCoordinator? = nil
}

// Property Wrapper used to access the "global" coordinator and the dismiss action.
// It is dynamic because it needs to observe changes in the environment.
// It needs to be able to recognize when a new coordinator is created by the
// navigation container (for example when a modal is opened)
@propertyWrapper
struct NavigationRouter: DynamicProperty {
    @Environment(\.coordinator)
    private var coordinator
    @Environment(\.dismiss)
    private var dismiss

    var wrappedValue: Router {
        Router(
            coordinator: coordinator,
            dismissAction: dismiss
        )
    }
}
