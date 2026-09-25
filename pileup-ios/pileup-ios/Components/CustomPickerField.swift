import SwiftUI

/// Unified, generic item model for Picker selection (Categories, Accounts, or any selectable item)
struct CustomPickerItem: Identifiable, Equatable {
    let id: Int?
    let name: String
    let subtitle: String?
    let icon: String?
    let color: Color
    
    init(id: Int?, name: String, subtitle: String? = nil, icon: String? = nil, color: Color = AppTheme.Colors.primary) {
        self.id = id
        self.name = name
        self.subtitle = subtitle
        self.icon = icon
        self.color = color
    }
    
    init(category: CategoryItem) {
        self.id = category.id
        self.name = category.nome
        self.subtitle = nil
        self.icon = nil
        self.color = category.displayColor
    }
    
    init(account: AccountItem) {
        self.id = account.id
        self.name = account.nome
        self.subtitle = account.tipo == "contanti" ? "Contanti" : "Conto Corrente"
        self.icon = account.tipo == "contanti" ? "banknote" : "creditcard"
        self.color = account.displayColor
    }
    
    init(slice: CategoryPieSlice) {
        self.id = slice.categoryId
        self.name = slice.name
        self.subtitle = nil
        self.icon = nil
        self.color = slice.color
    }
}

// Backwards compatibility alias
typealias CategoryPickerItem = CustomPickerItem

/// Unified, clean Picker Field that opens a native Bottom Sheet.
/// Highly reusable for Categories, Accounts, or any selectable list.
struct CustomPickerField: View {
    var title: String? = nil
    var placeholder: String = "Seleziona..."
    var sheetTitle: String? = nil
    var searchPlaceholder: String = "Cerca..."
    let items: [CustomPickerItem]
    @Binding var selectedId: Int?
    
    var showAllOption: Bool = false
    var allOptionLabel: String = "Tutti i movimenti"
    var allowClear: Bool = false
    var showError: Bool = false
    var errorMessage: String? = nil
    var onTap: (() -> Void)? = nil
    var onSelect: ((Int?) -> Void)? = nil
    
    @State private var isSheetPresented: Bool = false
    
    private var selectedItem: CustomPickerItem? {
        guard let id = selectedId else { return nil }
        return items.first(where: { $0.id == id })
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let title = title, !title.isEmpty {
                Text(title)
                    .font(.system(size: 11, weight: .bold))
                    .tracking(1.5)
                    .foregroundColor(AppTheme.Colors.dynamicSubtext)
            }
            
            Button(action: {
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                HapticHelper.light()
                onTap?()
                isSheetPresented = true
            }) {
                HStack(spacing: 12) {
                    if let selected = selectedItem {
                        if let icon = selected.icon {
                            Image(systemName: icon)
                                .font(.system(size: 16))
                                .foregroundColor(selected.color)
                        } else {
                            Circle()
                                .fill(selected.color)
                                .frame(width: 14, height: 14)
                        }
                        
                        Text(selected.name)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(AppTheme.Colors.dynamicText)
                            .lineLimit(1)
                        
                        Spacer()
                        
                        if allowClear {
                            Button(action: {
                                HapticHelper.light()
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                    selectedId = nil
                                    onSelect?(nil)
                                }
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 18))
                                    .foregroundColor(AppTheme.Colors.dynamicSubtext)
                                    .padding(4)
                            }
                            .buttonStyle(.plain)
                        }
                    } else if showAllOption {
                        Text(allOptionLabel)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(AppTheme.Colors.dynamicText)
                        
                        Spacer()
                    } else {
                        Circle()
                            .fill(AppTheme.Colors.dynamicSubtext.opacity(0.35))
                            .frame(width: 14, height: 14)
                        
                        Text(placeholder)
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(AppTheme.Colors.dynamicSubtext)
                        
                        Spacer()
                    }
                    
                    Image(systemName: "chevron.down")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(AppTheme.Colors.dynamicSubtext)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(AppTheme.Colors.dynamicCardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(
                            showError ? AppTheme.Colors.negative : AppTheme.Colors.dynamicBorder.opacity(0.6),
                            lineWidth: showError ? 1.5 : 1
                        )
                )
                .shadow(color: Color.black.opacity(0.02), radius: 4, x: 0, y: 1)
            }
            .buttonStyle(.plain)
            
            if showError, let msg = errorMessage, !msg.isEmpty {
                InputError(message: msg, type: .error)
                    .padding(.horizontal, 4)
            }
        }
        .sheet(isPresented: $isSheetPresented) {
            CustomSelectionSheet(
                title: sheetTitle ?? (showAllOption ? "Filtra" : placeholder),
                searchPlaceholder: searchPlaceholder,
                items: items,
                selectedId: $selectedId,
                showAllOption: showAllOption,
                allOptionLabel: allOptionLabel,
                onSelect: onSelect
            )
        }
    }
}

// Backwards compatibility alias
typealias CategoryPickerField = CustomPickerField

/// Spacious Bottom Sheet for selecting an item with live search and clean rows.
struct CustomSelectionSheet: View {
    let title: String
    var searchPlaceholder: String = "Cerca..."
    let items: [CustomPickerItem]
    @Binding var selectedId: Int?
    var showAllOption: Bool = false
    var allOptionLabel: String = "Tutti i movimenti"
    var onSelect: ((Int?) -> Void)? = nil
    @Environment(\.dismiss) private var dismiss
    
    @State private var searchQuery: String = ""
    
    private var filteredItems: [CustomPickerItem] {
        let query = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if query.isEmpty {
            return items
        }
        return items.filter { item in
            item.name.lowercased().contains(query) || (item.subtitle?.lowercased().contains(query) ?? false)
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                // Search Bar
                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 15))
                        .foregroundColor(AppTheme.Colors.dynamicSubtext)
                    
                    TextField(searchPlaceholder, text: $searchQuery)
                        .font(.system(size: 15))
                        .foregroundColor(AppTheme.Colors.dynamicText)
                        .textInputAutocapitalization(.never)
                        .disableAutocorrection(true)
                    
                    if !searchQuery.isEmpty {
                        Button(action: {
                            HapticHelper.light()
                            searchQuery = ""
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 16))
                                .foregroundColor(AppTheme.Colors.dynamicSubtext)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 11)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(AppTheme.Colors.dynamicBackground)
                )
                .padding(.horizontal, 20)
                .padding(.top, 8)
                
                // List of Items
                ScrollView(.vertical, showsIndicators: true) {
                    LazyVStack(spacing: 8) {
                        // All option row if enabled
                        if showAllOption && (searchQuery.isEmpty || allOptionLabel.lowercased().contains(searchQuery.lowercased())) {
                            let isAllSelected = selectedId == nil
                            Button(action: {
                                HapticHelper.selection()
                                selectedId = nil
                                onSelect?(nil)
                                dismiss()
                            }) {
                                HStack(spacing: 12) {
                                    Text(allOptionLabel)
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundColor(AppTheme.Colors.dynamicText)
                                    
                                    Spacer()
                                    
                                    if isAllSelected {
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 14, weight: .bold))
                                            .foregroundColor(AppTheme.Colors.dynamicText)
                                    }
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 14)
                                .background(
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .fill(isAllSelected ? AppTheme.Colors.dynamicBorder.opacity(0.18) : AppTheme.Colors.dynamicCardBackground)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .stroke(isAllSelected ? AppTheme.Colors.dynamicBorder : AppTheme.Colors.dynamicBorder.opacity(0.6), lineWidth: 1)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                        
                        if filteredItems.isEmpty {
                            VStack(spacing: 8) {
                                Image(systemName: "magnifyingglass")
                                    .font(.system(size: 28))
                                    .foregroundColor(AppTheme.Colors.dynamicSubtext.opacity(0.4))
                                    .padding(.top, 24)
                                Text("Nessun elemento trovato")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(AppTheme.Colors.dynamicSubtext)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 20)
                        } else {
                            ForEach(filteredItems) { item in
                                let isSelected = selectedId != nil && selectedId == item.id
                                Button(action: {
                                    HapticHelper.selection()
                                    selectedId = item.id
                                    onSelect?(item.id)
                                    dismiss()
                                }) {
                                    HStack(spacing: 12) {
                                        if let icon = item.icon {
                                            ZStack {
                                                Circle()
                                                    .fill(item.color.opacity(0.15))
                                                    .frame(width: 34, height: 34)
                                                Image(systemName: icon)
                                                    .font(.system(size: 15))
                                                    .foregroundColor(item.color)
                                            }
                                        } else {
                                            Circle()
                                                .fill(item.color)
                                                .frame(width: 14, height: 14)
                                        }
                                        
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(item.name)
                                                .font(.system(size: 15, weight: .semibold))
                                                .foregroundColor(AppTheme.Colors.dynamicText)
                                                .lineLimit(1)
                                            
                                            if let sub = item.subtitle {
                                                Text(sub)
                                                    .font(.system(size: 12))
                                                    .foregroundColor(AppTheme.Colors.dynamicSubtext)
                                            }
                                        }
                                        
                                        Spacer()
                                        
                                        if isSelected {
                                            Image(systemName: "checkmark")
                                                .font(.system(size: 14, weight: .bold))
                                                .foregroundColor(item.color)
                                        }
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, item.subtitle != nil ? 10 : 14)
                                    .background(
                                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                                            .fill(isSelected ? item.color.opacity(0.08) : AppTheme.Colors.dynamicCardBackground)
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                                            .stroke(isSelected ? item.color : AppTheme.Colors.dynamicBorder.opacity(0.6), lineWidth: isSelected ? 1.5 : 1)
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 24)
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(AppTheme.Colors.dynamicSubtext)
                    }
                }
            }
            .background(AppTheme.Colors.dynamicBackground.ignoresSafeArea())
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}

// Backwards compatibility alias
typealias CategorySelectionSheet = CustomSelectionSheet
