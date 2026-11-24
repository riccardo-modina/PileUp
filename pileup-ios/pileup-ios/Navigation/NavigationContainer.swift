//
// PileUp - Personal finance tracking platform
// Copyright (C) 2025-2026 PileUp
//
// Licensed under the GNU Affero General Public License v3.0.
// See LICENSE in the project root for full license details.
//

import SwiftUI

struct NavigationContainer<Content: View>: View {

    // Coordinator of this view, if slide from left/right is the same as the one of the parent.
    // If a modal comes out is built new.
    @StateObject private var coordinator: NavigationCoordinator

    // The root of the stack, homeview at the beginning and the first view of the modal stack.
    private let content: Content

    
    // Passing a @autoclosure@escaping () -> NavigationCoordinator allows creation of the coordinator lazily, (build only when needed)
    // First view of the stack is built and saved in content
    init(
        coordinator: @autoclosure @escaping () -> NavigationCoordinator = NavigationCoordinator(),
        @ViewBuilder content: () -> Content
    ){
        // _coordinator and not the self.coordinator because the coordinator might not be initalized yet.
        _coordinator = StateObject(wrappedValue: coordinator())
        self.content = content()
    }

    var body: some View {
        NavigationStack(path: $coordinator.path) {
            content
                .navigationDestination(for: NavigationRoute.self) { route in
                    route.destination
                }
        }
        
        .environment(\.coordinator, coordinator)
        
        .sheet(item: $coordinator.presentedSheet) {
            coordinator.dismissSheet()
        } content: { presentedRoute in
            NavigationContainer(coordinator: presentedRoute.coordinator) {
                presentedRoute.route.destination
            }
        }
       
        .fullScreenCover(item: $coordinator.presentedFullScreen) {
            coordinator.dismissFullScreen()
        } content: { presentedRoute in
            NavigationContainer(coordinator: presentedRoute.coordinator) {
                presentedRoute.route.destination
            }
        }
    }
}