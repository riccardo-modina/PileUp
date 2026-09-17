import UIKit

/// Centralized haptic feedback helper for tactile touch interactions across the app.
/// Keeps strong references to generators to prevent premature deallocation before the Taptic Engine fires.
enum HapticHelper {
    
    @MainActor private static let lightGenerator = UIImpactFeedbackGenerator(style: .light)
    @MainActor private static let mediumGenerator = UIImpactFeedbackGenerator(style: .medium)
    @MainActor private static let heavyGenerator = UIImpactFeedbackGenerator(style: .heavy)
    @MainActor private static let selectionGenerator = UISelectionFeedbackGenerator()
    @MainActor private static let notificationGenerator = UINotificationFeedbackGenerator()
    
    /// Light impact feedback for secondary buttons, pills, and navigation.
    static func light() {
        runOnMain {
            lightGenerator.prepare()
            lightGenerator.impactOccurred()
        }
    }
    
    /// Medium impact feedback for primary action buttons and step advancements.
    static func medium() {
        runOnMain {
            mediumGenerator.prepare()
            mediumGenerator.impactOccurred()
        }
    }
    
    /// Heavy impact feedback for critical or high-emphasis actions.
    static func heavy() {
        runOnMain {
            heavyGenerator.prepare()
            heavyGenerator.impactOccurred()
        }
    }
    
    /// Selection change feedback for picker rows, segmented tabs, and radio-style selections.
    static func selection() {
        runOnMain {
            selectionGenerator.prepare()
            selectionGenerator.selectionChanged()
        }
    }
    
    /// Success notification feedback for completed operations (e.g. transaction saved).
    static func success() {
        runOnMain {
            notificationGenerator.prepare()
            notificationGenerator.notificationOccurred(.success)
        }
    }
    
    /// Warning notification feedback for threshold alerts or input limits.
    static func warning() {
        runOnMain {
            notificationGenerator.prepare()
            notificationGenerator.notificationOccurred(.warning)
        }
    }
    
    /// Error notification feedback for validation failures or server errors.
    static func error() {
        runOnMain {
            notificationGenerator.prepare()
            notificationGenerator.notificationOccurred(.error)
        }
    }
    
    private static func runOnMain(_ block: @escaping @MainActor () -> Void) {
        if Thread.isMainThread {
            MainActor.assumeIsolated {
                block()
            }
        } else {
            Task { @MainActor in
                block()
            }
        }
    }
}
