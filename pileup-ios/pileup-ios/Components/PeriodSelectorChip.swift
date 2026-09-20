import SwiftUI

/// Reusable interactive period selector chip component that displays the current DataPeriod
/// and presents the WheelYearMonthPickerModal bottom sheet on tap.
struct PeriodSelectorChip: View {
    @Binding var selectedPeriod: DataPeriod
    var onPeriodChanged: ((DataPeriod) -> Void)? = nil
    
    @State private var showPickerModal: Bool = false
    
    private let monthNamesShort = ["Gen", "Feb", "Mar", "Apr", "Mag", "Giu", "Lug", "Ago", "Set", "Ott", "Nov", "Dic"]
    
    private var periodChipTitle: String {
        switch selectedPeriod {
        case .monthYear(let m, let y):
            let mName = monthNamesShort[max(0, min(m - 1, 11))]
            return "\(mName) \(y)"
        case .year(let y):
            return "\(y)"
        case .total:
            return "Totale"
        }
    }
    
    var body: some View {
        Button(action: {
            HapticHelper.light()
            showPickerModal = true
        }) {
            HStack(spacing: 6) {
                Text(periodChipTitle)
                    .font(.system(size: 13, weight: .medium))
                Image(systemName: "chevron.down")
                    .font(.system(size: 10, weight: .bold))
            }
            .foregroundColor(AppTheme.Colors.dynamicText)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(AppTheme.Colors.dynamicCardBackground)
                    .shadow(color: Color.black.opacity(0.04), radius: 4, x: 0, y: 1)
            )
            .overlay(
                Capsule()
                    .stroke(AppTheme.Colors.dynamicBorder.opacity(0.6), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showPickerModal) {
            WheelYearMonthPickerModal(selectedPeriod: $selectedPeriod)
                .presentationDetents([.height(380)])
                .presentationCornerRadius(30)
                .presentationDragIndicator(.visible)
        }
        .onChange(of: selectedPeriod) {
            onPeriodChanged?(selectedPeriod)
        }
    }
}
