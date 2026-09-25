import SwiftUI

/// Custom iOS-styled bottom sheet confirmation modal.
/// Provides rich visual feedback matching AppTheme tokens with icons,
/// smooth spring slide-up animations, and distinct primary/cancel actions.
struct ConfirmationBottomSheet: View {
    let icon: String
    var iconColor: Color = AppTheme.Colors.negative
    var iconBackgroundColor: Color = AppTheme.Colors.negative.opacity(0.12)
    let title: String
    let message: String
    let confirmTitle: String
    var isDestructive: Bool = true
    var isLoading: Bool = false
    let onConfirm: () -> Void
    var cancelTitle: String = "Annulla"
    let onCancel: () -> Void
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Dimmed backdrop
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    HapticHelper.light()
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    onCancel()
                }
            
            // Bottom Sheet Card
            VStack(spacing: 0) {
                // Drag handle indicator
                Capsule()
                    .fill(AppTheme.Colors.dynamicSubtext.opacity(0.3))
                    .frame(width: 36, height: 5)
                    .padding(.top, 12)
                    .padding(.bottom, 20)
                
                // Icon Header
                ZStack {
                    Circle()
                        .fill(iconBackgroundColor)
                        .frame(width: 56, height: 56)
                    Image(systemName: icon)
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(iconColor)
                }
                .padding(.bottom, 16)
                
                // Title
                Text(title)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(AppTheme.Colors.dynamicText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 8)
                
                // Message
                Text(message)
                    .font(.system(size: 15, weight: .regular))
                    .foregroundColor(AppTheme.Colors.dynamicSubtext)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 28)
                
                // Action Buttons
                VStack(spacing: 10) {
                    // Confirm / Destructive Button
                    Button(action: {
                        HapticHelper.warning()
                        onConfirm()
                    }) {
                        HStack {
                            if isLoading {
                                ProgressView()
                                    .scaleEffect(0.85)
                                    .foregroundColor(.white)
                            } else {
                                Text(confirmTitle)
                                    .font(.system(size: 16, weight: .semibold))
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(isDestructive ? AppTheme.Colors.negative : AppTheme.Colors.primary)
                        )
                        .foregroundColor(isDestructive ? .white : AppTheme.Colors.primaryButtonText)
                        .shadow(
                            color: isDestructive ? AppTheme.Colors.negative.opacity(0.25) : AppTheme.Colors.primary.opacity(0.25),
                            radius: 8,
                            y: 3
                        )
                    }
                    .disabled(isLoading)
                    
                    // Cancel / Dismiss Button
                    Button(action: {
                        HapticHelper.light()
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                        onCancel()
                    }) {
                        Text(cancelTitle)
                            .font(.system(size: 16, weight: .semibold))
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .fill(AppTheme.Colors.dynamicBackground)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .stroke(AppTheme.Colors.dynamicBorder.opacity(0.8), lineWidth: 1)
                            )
                            .foregroundColor(AppTheme.Colors.dynamicText)
                    }
                    .disabled(isLoading)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
            }
            .background(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(AppTheme.Colors.dynamicCardBackground)
                    .shadow(color: Color.black.opacity(0.18), radius: 24, y: -4)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .stroke(AppTheme.Colors.dynamicBorder.opacity(0.5), lineWidth: 1)
            )
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
        .ignoresSafeArea(edges: .bottom)
        .onAppear {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
    }
}
