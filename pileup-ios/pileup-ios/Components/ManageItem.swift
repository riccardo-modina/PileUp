import SwiftUI
import UIKit

/// Sheet to manage (Create, Edit, Delete) categories or accounts.
/// Displays three prominent actions: Create, Edit (requires selection), Delete (requires selection).
struct ManageItem: View {
    let pickerType: CustomPickerType
    @Binding var items: [CustomPickerItem]
    var availableColors: [String] = AppTheme.Palette.presets
    var onCreated: ((CustomPickerItem) -> Void)? = nil
    var onUpdated: ((CustomPickerItem) -> Void)? = nil
    var onDeleted: ((Int) -> Void)? = nil
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    @State private var selectedItemId: Int? = nil
    @State private var isCreatePresented: Bool = false
    @State private var isEditPresented: Bool = false
    @State private var showDeleteConfirmation: Bool = false
    @State private var isDeleting: Bool = false
    @State private var errorMessage: String? = nil
    
    private var isCategory: Bool {
        if case .category = pickerType { return true }
        return false
    }
    
    private var entityNameSingle: String {
        isCategory ? "categoria" : "conto"
    }
    
    private var entityTitleSingle: String {
        isCategory ? "Categoria" : "Conto"
    }
    
    private var sheetTitle: String {
        isCategory ? "Gestisci Categorie" : "Gestisci Conti"
    }
    
    private var selectedItem: CustomPickerItem? {
        guard let id = selectedItemId else { return nil }
        return items.first(where: { $0.id == id })
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.Colors.dynamicBackground
                    .ignoresSafeArea()
                
                VStack(spacing: 16) {
                    // Top Action Controls
                    VStack(spacing: 10) {
                        // 1. Create Button (Always enabled)
                        Button(action: {
                            HapticHelper.light()
                            isCreatePresented = true
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 15, weight: .semibold))
                                Text("Crea \(entityTitleSingle)")
                                    .font(.system(size: 14, weight: .bold))
                            }
                            .foregroundColor(colorScheme == .dark ? Color.black : Color.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 13)
                            .background(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(colorScheme == .dark ? Color.white : Color(hex: "#0f172a"))
                            )
                        }
                        .buttonStyle(.plain)
                        
                        // 2. Contextual Actions: Edit & Delete (Enabled only when an item is selected)
                        HStack(spacing: 10) {
                            // Edit Button
                            let canEdit = selectedItem != nil
                            Button(action: {
                                guard canEdit else { return }
                                HapticHelper.light()
                                isEditPresented = true
                            }) {
                                HStack(spacing: 6) {
                                    Image(systemName: "pencil")
                                        .font(.system(size: 13, weight: .semibold))
                                    Text("Modifica")
                                        .font(.system(size: 13.5, weight: .semibold))
                                }
                                .foregroundColor(canEdit ? AppTheme.Colors.dynamicText : AppTheme.Colors.dynamicSubtext.opacity(0.4))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 11)
                                .background(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .fill(canEdit ? AppTheme.Colors.dynamicCardBackground : AppTheme.Colors.dynamicBackground)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .stroke(canEdit ? AppTheme.Colors.dynamicBorder : AppTheme.Colors.dynamicBorder.opacity(0.3), lineWidth: 1)
                                )
                            }
                            .buttonStyle(.plain)
                            .disabled(!canEdit)
                            
                            // Delete Button
                            let canDelete = selectedItem != nil && !(selectedItem?.isSystem ?? false)
                            Button(action: {
                                guard canDelete else { return }
                                HapticHelper.warning()
                                showDeleteConfirmation = true
                            }) {
                                HStack(spacing: 6) {
                                    Image(systemName: "trash")
                                        .font(.system(size: 13, weight: .semibold))
                                    Text("Elimina")
                                        .font(.system(size: 13.5, weight: .semibold))
                                }
                                .foregroundColor(canDelete ? AppTheme.Colors.negative : AppTheme.Colors.dynamicSubtext.opacity(0.4))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 11)
                                .background(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .fill(canDelete ? AppTheme.Colors.negative.opacity(0.1) : AppTheme.Colors.dynamicBackground)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .stroke(canDelete ? AppTheme.Colors.negative.opacity(0.4) : AppTheme.Colors.dynamicBorder.opacity(0.3), lineWidth: 1)
                                )
                            }
                            .buttonStyle(.plain)
                            .disabled(!canDelete)
                        }
                        
                        // Status helper text
                        HStack {
                            if let selected = selectedItem {
                                HStack(spacing: 6) {
                                    Text("Selezionato:")
                                        .foregroundColor(AppTheme.Colors.dynamicSubtext)
                                    Text(selected.name)
                                        .fontWeight(.bold)
                                        .foregroundColor(AppTheme.Colors.dynamicText)
                                    
                                    if selected.isSystem {
                                        Text("(Sistema - non eliminabile)")
                                            .font(.system(size: 11))
                                            .foregroundColor(AppTheme.Colors.dynamicSubtext)
                                    }
                                }
                                .font(.system(size: 12))
                                
                                Spacer()
                                
                                Button("Deseleziona") {
                                    withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                                        selectedItemId = nil
                                    }
                                }
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(AppTheme.Colors.dynamicSubtext)
                            } else {
                                Text("Tocca un elemento nella lista per selezionarlo, quindi modificalo o eliminalo.")
                                    .font(.system(size: 12))
                                    .foregroundColor(AppTheme.Colors.dynamicSubtext)
                                Spacer()
                            }
                        }
                        .padding(.top, 2)
                        .padding(.horizontal, 4)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    
                    if let err = errorMessage {
                        InputError(message: err, type: .error)
                            .padding(.horizontal, 20)
                    }
                    
                    // List of Items
                    ScrollView(.vertical, showsIndicators: true) {
                        LazyVStack(spacing: 8) {
                            ForEach(items) { item in
                                let isSelected = selectedItemId == item.id
                                Button(action: {
                                    HapticHelper.selection()
                                    withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                                        if selectedItemId == item.id {
                                            selectedItemId = nil
                                        } else {
                                            selectedItemId = item.id
                                        }
                                    }
                                }) {
                                    HStack(spacing: 12) {
                                        // Color / Icon badge
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
                                                .frame(width: 16, height: 16)
                                        }
                                        
                                        // Name and subtitle
                                        VStack(alignment: .leading, spacing: 2) {
                                            HStack(spacing: 6) {
                                                Text(item.name)
                                                    .font(.system(size: 15, weight: .semibold))
                                                    .foregroundColor(AppTheme.Colors.dynamicText)
                                                    .lineLimit(1)
                                                
                                                if item.isSystem {
                                                    Text("Sistema")
                                                        .font(.system(size: 10, weight: .bold))
                                                        .padding(.horizontal, 6)
                                                        .padding(.vertical, 2)
                                                        .background(AppTheme.Colors.dynamicSubtext.opacity(0.15))
                                                        .foregroundColor(AppTheme.Colors.dynamicSubtext)
                                                        .clipShape(Capsule())
                                                }
                                            }
                                            
                                            if let sub = item.subtitle {
                                                Text(sub)
                                                    .font(.system(size: 12))
                                                    .foregroundColor(AppTheme.Colors.dynamicSubtext)
                                            }
                                        }
                                        
                                        Spacer()
                                        
                                        // Selection Radio Indicator
                                        ZStack {
                                            Circle()
                                                .stroke(isSelected ? (colorScheme == .dark ? Color.white : Color(hex: "#0f172a")) : AppTheme.Colors.dynamicBorder, lineWidth: 1.5)
                                                .frame(width: 20, height: 20)
                                            
                                            if isSelected {
                                                Circle()
                                                    .fill(colorScheme == .dark ? Color.white : Color(hex: "#0f172a"))
                                                    .frame(width: 10, height: 10)
                                            }
                                        }
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                                            .fill(isSelected ? AppTheme.Colors.dynamicBorder.opacity(0.2) : AppTheme.Colors.dynamicCardBackground)
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                                            .stroke(isSelected ? (colorScheme == .dark ? Color.white.opacity(0.6) : Color(hex: "#0f172a").opacity(0.6)) : AppTheme.Colors.dynamicBorder.opacity(0.4), lineWidth: 1)
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 24)
                    }
                }
                
                // Delete confirmation sheet
                if showDeleteConfirmation, let itemToDelete = selectedItem {
                    ConfirmationBottomSheet(
                        icon: "trash.fill",
                        iconColor: AppTheme.Colors.negative,
                        iconBackgroundColor: AppTheme.Colors.negative.opacity(0.12),
                        title: "Elimina \(entityTitleSingle)",
                        message: "Sei sicuro di voler eliminare '\(itemToDelete.name)'? Questa azione non può essere annullata.",
                        confirmTitle: "Elimina",
                        isDestructive: true,
                        isLoading: isDeleting,
                        onConfirm: {
                            deleteSelectedItem()
                        },
                        cancelTitle: "Annulla",
                        onCancel: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                showDeleteConfirmation = false
                            }
                        }
                    )
                }
            }
            .navigationTitle(sheetTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fine") {
                        dismiss()
                    }
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(AppTheme.Colors.dynamicText)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .sheet(isPresented: $isCreatePresented) {
            if isCategory {
                let defaultType: String = {
                    if case .category(let tipo) = pickerType {
                        return tipo ?? "uscita"
                    }
                    return "uscita"
                }()
                CreateCategorySheet(
                    initialName: "",
                    initialType: defaultType,
                    availableColors: availableColors,
                    onSaved: { created in
                        let newItem = CustomPickerItem(category: created)
                        items.append(newItem)
                        selectedItemId = created.id
                        onCreated?(newItem)
                        NotificationCenter.default.post(name: NSNotification.Name("CategoriesUpdated"), object: created)
                    }
                )
            } else {
                CreateAccountSheet(
                    initialName: "",
                    availableColors: availableColors,
                    onSaved: { created in
                        let newItem = CustomPickerItem(account: created)
                        items.append(newItem)
                        selectedItemId = created.id
                        onCreated?(newItem)
                        NotificationCenter.default.post(name: NSNotification.Name("AccountsUpdated"), object: created)
                    }
                )
            }
        }
        .sheet(isPresented: $isEditPresented) {
            if let item = selectedItem, let itemId = item.id {
                if isCategory {
                    let tipo: String = {
                        if case .category(let t) = item.itemType {
                            return t ?? "uscita"
                        }
                        return "uscita"
                    }()
                    CreateCategorySheet(
                        categoryId: itemId,
                        initialName: item.name,
                        initialType: tipo,
                        initialColorHex: item.colorHex ?? item.color.toHex(),
                        availableColors: availableColors,
                        onSaved: { updated in
                            let updatedItem = CustomPickerItem(category: updated)
                            if let idx = items.firstIndex(where: { $0.id == itemId }) {
                                items[idx] = updatedItem
                            }
                            onUpdated?(updatedItem)
                            NotificationCenter.default.post(name: NSNotification.Name("CategoriesUpdated"), object: updated)
                        }
                    )
                } else {
                    let tipo: String = {
                        if item.subtitle?.lowercased().contains("contanti") == true {
                            return "contanti"
                        }
                        return "conto_corrente"
                    }()
                    CreateAccountSheet(
                        accountId: itemId,
                        initialName: item.name,
                        initialType: tipo,
                        initialColorHex: item.colorHex ?? item.color.toHex(),
                        availableColors: availableColors,
                        onSaved: { updated in
                            let updatedItem = CustomPickerItem(account: updated)
                            if let idx = items.firstIndex(where: { $0.id == itemId }) {
                                items[idx] = updatedItem
                            }
                            onUpdated?(updatedItem)
                            NotificationCenter.default.post(name: NSNotification.Name("AccountsUpdated"), object: updated)
                        }
                    )
                }
            }
        }
    }
    
    private func deleteSelectedItem() {
        guard let item = selectedItem, let itemId = item.id else { return }
        
        isDeleting = true
        errorMessage = nil
        
        Task {
            do {
                if isCategory {
                    try await CategoryAPI.shared.deleteCategory(id: itemId)
                    NotificationCenter.default.post(name: NSNotification.Name("CategoriesUpdated"), object: nil)
                } else {
                    try await AccountAPI.shared.deleteAccount(id: itemId)
                    NotificationCenter.default.post(name: NSNotification.Name("AccountsUpdated"), object: nil)
                }
                
                await MainActor.run {
                    items.removeAll(where: { $0.id == itemId })
                    selectedItemId = nil
                    isDeleting = false
                    showDeleteConfirmation = false
                    onDeleted?(itemId)
                    HapticHelper.success()
                }
            } catch {
                await MainActor.run {
                    isDeleting = false
                    showDeleteConfirmation = false
                    errorMessage = ErrorHandler.format(error)
                    HapticHelper.error()
                }
            }
        }
    }
}
