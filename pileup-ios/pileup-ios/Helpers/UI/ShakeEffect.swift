import SwiftUI

/// Modifier to apply horizontal shaking animation to a view for error/validation feedback.
struct ShakeEffect: GeometryEffect {
    var amount: CGFloat = 8
    var shakesPerUnit: CGFloat = 3
    var animatableData: CGFloat

    func effectValue(size: CGSize) -> ProjectionTransform {
        ProjectionTransform(CGAffineTransform(translationX:
            amount * sin(animatableData * .pi * shakesPerUnit),
            y: 0))
    }
}

extension View {
    func shake(animatableData: CGFloat, amount: CGFloat = 8, shakesPerUnit: CGFloat = 3) -> some View {
        self.modifier(ShakeEffect(amount: amount, shakesPerUnit: shakesPerUnit, animatableData: animatableData))
    }
}
