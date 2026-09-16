import SwiftUI

struct WheelYearMonthPickerModal: View {
    @Binding var selectedPeriod: DataPeriod
    @Environment(\.dismiss) var dismiss
    
    @State private var mode: SelectionMode
    @State private var tempYear: Int
    @State private var tempMonth: Int
    
    let currentYear = Calendar.current.component(.year, from: Date())
    let currentMonth = Calendar.current.component(.month, from: Date())
    
    enum SelectionMode {
        case year, monthYear
    }
    
    let monthsNames = Calendar.current.standaloneMonthSymbols.map { $0.capitalized }
    
    var yearsList: [Int] {
        Array((currentYear - 10)...currentYear).reversed()
    }
    
    var monthsList: [Int] {
        if tempYear == currentYear {
            return Array(1...currentMonth)
        }
        return Array(1...12)
    }
    
    init(selectedPeriod: Binding<DataPeriod>) {
        self._selectedPeriod = selectedPeriod
        
        let initialYear: Int
        let initialMonth: Int
        var initialMode: SelectionMode = .monthYear
        
        switch selectedPeriod.wrappedValue {
        case .monthYear(let m, let y):
            initialMonth = m
            initialYear = y
            initialMode = .monthYear
        case .year(let y):
            initialMonth = Calendar.current.component(.month, from: Date())
            initialYear = y
            initialMode = .year
        case .total:
            initialMonth = Calendar.current.component(.month, from: Date())
            initialYear = Calendar.current.component(.year, from: Date())
            initialMode = .monthYear
        }
        
        self._tempYear = State(initialValue: initialYear)
        self._tempMonth = State(initialValue: initialMonth)
        self._mode = State(initialValue: initialMode)
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // Mode Switcher
            Picker("Modalità", selection: $mode) {
                Text("Anno").tag(SelectionMode.year)
                Text("Mese / Anno").tag(SelectionMode.monthYear)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 24)
            .padding(.top, 24)
            
            // Title
            VStack(spacing: 4) {
                Text("SELEZIONA PERIODO")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(AppTheme.Colors.textLight)
                
                if mode == .monthYear {
                    Text("\(monthsNames[tempMonth - 1]) \(String(tempYear))")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(AppTheme.Colors.text)
                } else {
                    Text(String(tempYear))
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(AppTheme.Colors.text)
                }
            }
            
            // Wheels
            HStack(spacing: 0) {
                if mode == .monthYear {
                    Picker("Mese", selection: $tempMonth) {
                        ForEach(monthsList, id: \.self) { month in
                            Text(monthsNames[month - 1]).tag(month)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(maxWidth: .infinity)
                }
                
                Picker("Anno", selection: $tempYear) {
                    ForEach(yearsList, id: \.self) { year in
                        Text(String(year)).tag(year)
                    }
                }
                .pickerStyle(.wheel)
                .frame(maxWidth: mode == .year ? .infinity : 120)
            }
            .frame(height: 150)
            .padding(.horizontal)
            .onChange(of: tempYear) {
                // If we selected the current year and the tempMonth is in the future, clamp it
                if tempYear == currentYear && tempMonth > currentMonth {
                    tempMonth = currentMonth
                }
            }
            
            // Bottom Buttons
            HStack {
                Button(action: {
                    selectedPeriod = .total
                    dismiss()
                }) {
                    Text("Totale")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .padding(.vertical, 10)
                        .padding(.horizontal, 20)
                        .background(Color(UIColor.secondarySystemBackground))
                        .cornerRadius(12)
                        .foregroundColor(AppTheme.Colors.text)
                }
                
                Spacer()
                
                Button(action: {
                    dismiss()
                }) {
                    Text("Annulla")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(AppTheme.Colors.textLight)
                }
                
                Spacer()
                
                Button(action: {
                    if mode == .year {
                        selectedPeriod = .year(tempYear)
                    } else {
                        selectedPeriod = .monthYear(month: tempMonth, year: tempYear)
                    }
                    dismiss()
                }) {
                    Image(systemName: "checkmark")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 50, height: 50)
                        .background(AppTheme.Colors.primary)
                        .clipShape(Circle())
                        .shadow(color: AppTheme.Colors.primary.opacity(0.3), radius: 6, x: 0, y: 4)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
        .background(AppTheme.Colors.background.edgesIgnoringSafeArea(.bottom))
    }
}
