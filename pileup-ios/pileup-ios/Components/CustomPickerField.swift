import SwiftUI
import UIKit

/// Unified, generic item model for Picker selection (Categories, Accounts, or any selectable item)
struct CustomPickerItem: Identifiable, Equatable {
    let id: Int?
    let name: String
    let subtitle: String?
    let icon: String?
    let color: Color
    var colorHex: String? = nil
    var isSystem: Bool = false
    var itemType: ItemType? = nil
    
    enum ItemType: Equatable {
        case category(tipo: String?)
        case account
    }
    
    init(id: Int?, name: String, subtitle: String? = nil, icon: String? = nil, color: Color = AppTheme.Colors.primary, colorHex: String? = nil, isSystem: Bool = false, itemType: ItemType? = nil) {
        self.id = id
        self.name = name
        self.subtitle = subtitle
        self.icon = icon
        self.color = color
        self.colorHex = colorHex
        self.isSystem = isSystem
        self.itemType = itemType
    }
    
    init(category: CategoryItem) {
        self.id = category.id
        self.name = category.nome
        self.subtitle = nil
        self.icon = nil
        self.color = category.displayColor
        self.colorHex = category.color
        self.isSystem = category.isSystem
        self.itemType = .category(tipo: category.tipo)
    }
    
    init(account: AccountItem) {
        self.id = account.id
        self.name = account.nome
        self.subtitle = account.tipo == "contanti" ? "Contanti" : "Conto Corrente"
        self.icon = account.tipo == "contanti" ? "banknote" : "creditcard"
        self.color = account.displayColor
        self.colorHex = account.color
        self.isSystem = account.isSystem
        self.itemType = .account
    }
    
    init(slice: CategoryPieSlice) {
        self.id = slice.categoryId
        self.name = slice.name
        self.subtitle = nil
        self.icon = nil
        self.color = slice.color
        self.colorHex = slice.color.toHex()
        self.isSystem = false
        self.itemType = nil
    }
}


/// Defines the type of entity managed by the picker when allowing creation
enum CustomPickerType: Equatable {
    case category(defaultType: String? = nil)
    case account
    case generic(title: String)
}

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
    var customBackgroundColor: Color? = nil
    var customBorderColor: Color? = nil
    var onTap: (() -> Void)? = nil
    var onSelect: ((Int?) -> Void)? = nil
    
    // Add option configuration
    var pickerType: CustomPickerType? = nil
    var allowAdd: Bool? = nil
    var onCategoryCreated: ((CategoryItem) -> Void)? = nil
    var onAccountCreated: ((AccountItem) -> Void)? = nil
    var onAddNew: (() -> Void)? = nil
    
    @State private var isSheetPresented: Bool = false
    @State private var newlyAddedItems: [CustomPickerItem] = []
    
    private var resolvedPickerType: CustomPickerType? {
        if let explicit = pickerType {
            return explicit
        }
        for item in items {
            if case .category(let tipo) = item.itemType {
                return .category(defaultType: tipo ?? "uscita")
            } else if item.itemType == .account {
                return .account
            }
        }
        let combined = "\(sheetTitle ?? "") \(placeholder) \(title ?? "")".lowercased()
        if combined.contains("conto") {
            return .account
        }
        if combined.contains("categor") {
            return .category(defaultType: "uscita")
        }
        return nil
    }
    
    private var shouldAllowAdd: Bool {
        if let explicit = allowAdd {
            return explicit
        }
        return !showAllOption && resolvedPickerType != nil
    }
    
    private var combinedItems: [CustomPickerItem] {
        var result = items
        for item in newlyAddedItems {
            if !result.contains(where: { $0.id == item.id }) {
                result.append(item)
            }
        }
        return result
    }
    
    private var selectedItem: CustomPickerItem? {
        guard let id = selectedId else { return nil }
        return combinedItems.first(where: { $0.id == id })
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
                .background(customBackgroundColor ?? AppTheme.Colors.dynamicCardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(
                            customBorderColor ?? (showError ? AppTheme.Colors.negative : AppTheme.Colors.dynamicBorder.opacity(0.6)),
                            lineWidth: 1
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
                items: combinedItems,
                selectedId: $selectedId,
                showAllOption: showAllOption,
                allOptionLabel: allOptionLabel,
                onSelect: onSelect,
                pickerType: resolvedPickerType,
                allowAdd: shouldAllowAdd,
                onCategoryCreated: { cat in
                    let item = CustomPickerItem(category: cat)
                    if !newlyAddedItems.contains(where: { $0.id == item.id }) {
                        newlyAddedItems.append(item)
                    }
                    onCategoryCreated?(cat)
                },
                onAccountCreated: { acc in
                    let item = CustomPickerItem(account: acc)
                    if !newlyAddedItems.contains(where: { $0.id == item.id }) {
                        newlyAddedItems.append(item)
                    }
                    onAccountCreated?(acc)
                },
                onAddNew: onAddNew
            )
        }
    }
}

/// Spacious Bottom Sheet for selecting an item with live search and clean rows.
struct CustomSelectionSheet: View {
    let title: String
    var searchPlaceholder: String = "Cerca..."
    let items: [CustomPickerItem]
    @Binding var selectedId: Int?
    var showAllOption: Bool = false
    var allOptionLabel: String = "Tutti i movimenti"
    var onSelect: ((Int?) -> Void)? = nil
    
    var pickerType: CustomPickerType? = nil
    var allowAdd: Bool = false
    var onCategoryCreated: ((CategoryItem) -> Void)? = nil
    var onAccountCreated: ((AccountItem) -> Void)? = nil
    var onAddNew: (() -> Void)? = nil
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    @State private var searchQuery: String = ""
    @State private var localItems: [CustomPickerItem] = []
    
    @State private var isManageSheetPresented: Bool = false
    
    private var currentItems: [CustomPickerItem] {
        localItems.isEmpty ? items : localItems
    }
    
    private var filteredItems: [CustomPickerItem] {
        let query = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if query.isEmpty {
            return currentItems
        }
        return currentItems.filter { item in
            item.name.lowercased().contains(query) || (item.subtitle?.lowercased().contains(query) ?? false)
        }
    }
    
    private func manageButtonTitle(for type: CustomPickerType) -> String {
        switch type {
        case .category:
            return "Gestisci categorie"
        case .account:
            return "Gestisci conti"
        case .generic(let title):
            return "Gestisci \(title.lowercased())"
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
                
                // Manage Button under Search Bar
                if allowAdd, let type = pickerType {
                    Button(action: {
                        HapticHelper.light()
                        if let onAddNew = onAddNew {
                            onAddNew()
                        } else {
                            isManageSheetPresented = true
                        }
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "slider.horizontal.3")
                                .font(.system(size: 15, weight: .semibold))
                            
                            Text(manageButtonTitle(for: type))
                                .font(.system(size: 14, weight: .bold))
                                .lineLimit(1)
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12, weight: .semibold))
                                .opacity(0.6)
                        }
                        .foregroundColor(colorScheme == .dark ? Color.black : Color.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 13)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(colorScheme == .dark ? Color.white : Color(hex: "#0f172a"))
                        )
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 20)
                }
                
                // List of Items
                ScrollView(.vertical, showsIndicators: true) {
                    if filteredItems.isEmpty && (!showAllOption || !searchQuery.isEmpty) {
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
                        .padding(.vertical, 30)
                    } else {
                        VStack(spacing: 0) {
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
                                    .background(isAllSelected ? AppTheme.Colors.dynamicBorder.opacity(0.18) : Color.clear)
                                    .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)
                                
                                if !filteredItems.isEmpty {
                                    Divider()
                                        .background(AppTheme.Colors.dynamicBorder.opacity(0.5))
                                        .padding(.horizontal, 16)
                                }
                            }
                            
                            ForEach(Array(filteredItems.enumerated()), id: \.element.id) { index, item in
                                let isSelected = selectedId != nil && selectedId == item.id
                                VStack(spacing: 0) {
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
                                                        .frame(width: 32, height: 32)
                                                    Image(systemName: icon)
                                                        .font(.system(size: 15))
                                                        .foregroundColor(item.color)
                                                }
                                            } else {
                                                Circle()
                                                    .fill(item.color)
                                                    .frame(width: 12, height: 12)
                                            }
                                            
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(item.name)
                                                    .font(.system(size: 15, weight: .semibold))
                                                    .foregroundColor(AppTheme.Colors.dynamicText)
                                                    .lineLimit(1)
                                                
                                                if let sub = item.subtitle {
                                                    Text(sub)
                                                        .font(.system(size: 12, weight: .regular))
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
                                        .padding(.vertical, item.subtitle != nil ? 11 : 13)
                                        .background(isSelected ? AppTheme.Colors.dynamicBorder.opacity(0.18) : Color.clear)
                                        .contentShape(Rectangle())
                                    }
                                    .buttonStyle(.plain)
                                    
                                    if index < filteredItems.count - 1 {
                                        Divider()
                                            .background(AppTheme.Colors.dynamicBorder.opacity(0.5))
                                            .padding(.horizontal, 16)
                                    }
                                }
                            }
                        }
                        .background(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .fill(AppTheme.Colors.dynamicCardBackground)
                                .shadow(color: Color.black.opacity(0.02), radius: 6, x: 0, y: 2)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .stroke(AppTheme.Colors.dynamicBorder.opacity(0.5), lineWidth: 1)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                        .padding(.horizontal, 20)
                        .padding(.bottom, 24)
                    }
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
        .onAppear {
            if localItems.isEmpty {
                localItems = items
            }
        }
        .sheet(isPresented: $isManageSheetPresented) {
            if let type = pickerType {
                ManageItem(
                    pickerType: type,
                    items: $localItems,
                    availableColors: dynamicPaletteColors,
                    onCreated: { newItem in
                        selectedId = newItem.id
                        onSelect?(newItem.id)
                    },
                    onUpdated: { updatedItem in
                        // Items list is updated via binding
                    },
                    onDeleted: { deletedId in
                        if selectedId == deletedId {
                            selectedId = nil
                            onSelect?(nil)
                        }
                    }
                )
            }
        }
    }
    
    private var dynamicPaletteColors: [String] {
        var set: [String] = []
        for hex in AppTheme.Palette.presets {
            if !set.contains(where: { $0.caseInsensitiveCompare(hex) == .orderedSame }) {
                set.append(hex)
            }
        }
        for item in items {
            if let hex = item.color.toHex(), !set.contains(where: { $0.caseInsensitiveCompare(hex) == .orderedSame }) {
                set.append(hex)
            }
        }
        return set
    }
}

