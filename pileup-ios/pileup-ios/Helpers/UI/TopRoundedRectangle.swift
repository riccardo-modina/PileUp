import SwiftUI

/// Custom Shape for histogram bars with top rounded corners and a flat bottom base (90 degrees).
struct TopRoundedRectangle: Shape {
    var radius: CGFloat = 4
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let r = max(0, min(radius, min(rect.width / 2, rect.height)))
        
        path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + r))
        path.addQuadCurve(
            to: CGPoint(x: rect.minX + r, y: rect.minY),
            control: CGPoint(x: rect.minX, y: rect.minY)
        )
        path.addLine(to: CGPoint(x: rect.maxX - r, y: rect.minY))
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX, y: rect.minY + r),
            control: CGPoint(x: rect.maxX, y: rect.minY)
        )
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.closeSubpath()
        
        return path
    }
}
