import SwiftUI
import UIKit

/// Configuration model for a selectable type option in CreateItem
struct PickerTypeOption: Identifiable, Equatable {
    let id: String
    let title: String
    let iconName: String
    let color: Color?
    
    init(id: String, title: String, iconName: String, color: Color? = nil) {
        self.id = id
        self.title = title
        self.iconName = iconName
        self.color = color
    }
}

/// Unified, generic sheet to create a Category, Account, or other entity.
/// Completely eliminates duplicate UI code and centralizes styling and error handling.
struct CreateItem: View {
    let title: String
    let nameLabel: String
    let namePlaceholder: String
    var initialName: String = ""
    
    let typeLabel: String
    let typeOptions: [PickerTypeOption]
    var initialTypeId: String = ""
    
    var initialColorHex: String = AppTheme.Palette.presets.first ?? "#1FBC9C"
    var availableColors: [String] = AppTheme.Palette.presets
    
    let onSave: (_ name: String, _ typeId: String, _ colorHex: String) async throws -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    @State private var name: String = ""
    @State private var selectedTypeId: String = ""
    @State private var selectedHex: String = ""
    @State private var customColor: Color = Color(hex: "#1FBC9C")
    
    @State private var isSubmitting: Bool = false
    @State private var errorMessage: String? = nil
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Name Section
                    VStack(alignment: .leading, spacing: 8) {
                        Text(nameLabel)
                            .font(.system(size: 11, weight: .bold))
                            .tracking(1.5)
                            .foregroundColor(AppTheme.Colors.dynamicSubtext)
                        
                        TextField(namePlaceholder, text: $name)
                            .font(.system(size: 15))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)
                            .background(AppTheme.Colors.dynamicCardBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .stroke(AppTheme.Colors.dynamicBorder.opacity(0.6), lineWidth: 1)
                            )
                    }
                    
                    // Type Selection (if options provided)
                    if !typeOptions.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(typeLabel)
                                .font(.system(size: 11, weight: .bold))
                                .tracking(1.5)
                                .foregroundColor(AppTheme.Colors.dynamicSubtext)
                            
                            HStack(spacing: 8) {
                                ForEach(typeOptions) { option in
                                    let isSelected = selectedTypeId == option.id
                                    let optionColor = option.color ?? AppTheme.Colors.primary
                                    
                                    Button(action: {
                                        HapticHelper.selection()
                                        withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                                            selectedTypeId = option.id
                                        }
                                    }) {
                                        HStack(spacing: 6) {
                                            Image(systemName: option.iconName)
                                                .font(.system(size: 12, weight: .semibold))
                                            Text(option.title)
                                                .font(.system(size: 13, weight: .semibold))
                                        }
                                        .foregroundColor(isSelected ? optionColor : AppTheme.Colors.dynamicSubtext)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 11)
                                        .background(
                                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                                .fill(isSelected ? optionColor.opacity(0.14) : AppTheme.Colors.dynamicCardBackground)
                                        )
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                                .stroke(isSelected ? optionColor.opacity(0.5) : AppTheme.Colors.dynamicBorder.opacity(0.6), lineWidth: 1)
                                        )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                    
                    // Color Section
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("COLORE")
                                .font(.system(size: 11, weight: .bold))
                                .tracking(1.5)
                                .foregroundColor(AppTheme.Colors.dynamicSubtext)
                            
                            Spacer()
                            
                            ColorPicker("", selection: $customColor, supportsOpacity: false)
                                .labelsHidden()
                                .onChange(of: customColor) { _, newColor in
                                    if let hex = newColor.toHex() {
                                        selectedHex = hex
                                    }
                                }
                        }
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 7), spacing: 10) {
                            ForEach(availableColors, id: \.self) { hex in
                                let isSelected = selectedHex.caseInsensitiveCompare(hex) == .orderedSame
                                Button(action: {
                                    HapticHelper.light()
                                    selectedHex = hex
                                    customColor = Color(hex: hex)
                                }) {
                                    ZStack {
                                        Circle()
                                            .fill(Color(hex: hex))
                                            .frame(width: 32, height: 32)
                                        
                                        if isSelected {
                                            Circle()
                                                .stroke(Color.white, lineWidth: 2)
                                                .frame(width: 28, height: 28)
                                            Image(systemName: "checkmark")
                                                .font(.system(size: 12, weight: .bold))
                                                .foregroundColor(.white)
                                        }
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    
                    if let error = errorMessage {
                        InputError(message: error, type: .error)
                    }
                }
                .padding(20)
            }
            .background(AppTheme.Colors.dynamicBackground.ignoresSafeArea())
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annulla") {
                        dismiss()
                    }
                    .foregroundColor(AppTheme.Colors.dynamicSubtext)
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    if isSubmitting {
                        ProgressView()
                    } else {
                        Button("Salva") {
                            save()
                        }
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(AppTheme.Colors.dynamicPrimary)
                        .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }
            }
            .onAppear {
                name = initialName.trimmingCharacters(in: .whitespacesAndNewlines)
                selectedTypeId = initialTypeId
                selectedHex = initialColorHex
                customColor = Color(hex: initialColorHex)
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
    
    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            errorMessage = "Inserisci un nome"
            HapticHelper.warning()
            return
        }
        
        isSubmitting = true
        errorMessage = nil
        
        Task {
            do {
                try await onSave(trimmed, selectedTypeId, selectedHex)
                HapticHelper.success()
                isSubmitting = false
                dismiss()
            } catch {
                isSubmitting = false
                errorMessage = ErrorHandler.format(error)
                HapticHelper.error()
            }
        }
    }
}

// MARK: - Specialized Sheets for Category and Account

struct CreateCategorySheet: View {
    var categoryId: Int? = nil
    var initialName: String = ""
    var initialType: String = "uscita"
    var initialColorHex: String? = nil
    var availableColors: [String] = AppTheme.Palette.presets
    var onSaved: ((CategoryItem) -> Void)? = nil
    
    var body: some View {
        CreateItem(
            title: categoryId == nil ? "Nuova Categoria" : "Modifica Categoria",
            nameLabel: "NOME",
            namePlaceholder: "Es. Ristorante, Viaggi...",
            initialName: initialName,
            typeLabel: "TIPO DI MOVIMENTO",
            typeOptions: MovementType.allCases.map {
                PickerTypeOption(id: $0.rawValue, title: $0.title, iconName: $0.iconName, color: $0.accentColor)
            },
            initialTypeId: initialType,
            initialColorHex: initialColorHex ?? AppTheme.Palette.defaultCategoryColor,
            availableColors: availableColors,
            onSave: { name, typeId, hex in
                let item: CategoryItem
                if let id = categoryId {
                    item = try await CategoryAPI.shared.updateCategory(
                        id: id,
                        nome: name,
                        tipo: typeId,
                        color: hex
                    )
                } else {
                    item = try await CategoryAPI.shared.createCategory(
                        nome: name,
                        tipo: typeId,
                        color: hex
                    )
                }
                onSaved?(item)
            }
        )
    }
}

struct CreateAccountSheet: View {
    var accountId: Int? = nil
    var initialName: String = ""
    var initialType: String = "conto_corrente"
    var initialColorHex: String? = nil
    var availableColors: [String] = AppTheme.Palette.presets
    var onSaved: ((AccountItem) -> Void)? = nil
    
    var body: some View {
        CreateItem(
            title: accountId == nil ? "Nuovo Conto" : "Modifica Conto",
            nameLabel: "NOME CONTO",
            namePlaceholder: "Es. Conto Principale, Revolut, Contanti...",
            initialName: initialName,
            typeLabel: "TIPO DI CONTO",
            typeOptions: [
                PickerTypeOption(id: "conto_corrente", title: "Conto Corrente", iconName: "creditcard", color: AppTheme.Colors.primary),
                PickerTypeOption(id: "contanti", title: "Contanti", iconName: "banknote", color: AppTheme.Colors.primary)
            ],
            initialTypeId: initialType,
            initialColorHex: initialColorHex ?? AppTheme.Palette.defaultAccountColor,
            availableColors: availableColors,
            onSave: { name, typeId, hex in
                let item: AccountItem
                if let id = accountId {
                    item = try await AccountAPI.shared.updateAccount(
                        id: id,
                        nome: name,
                        tipo: typeId,
                        color: hex
                    )
                } else {
                    item = try await AccountAPI.shared.createAccount(
                        nome: name,
                        tipo: typeId,
                        color: hex
                    )
                }
                onSaved?(item)
            }
        )
    }
}

// MARK: - Color Hex Conversion Extension

extension Color {
    func toHex() -> String? {
        let uic = UIColor(self)
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        guard uic.getRed(&r, green: &g, blue: &b, alpha: &a) else { return nil }
        return String(format: "#%02lX%02lX%02lX", lroundf(Float(r * 255)), lroundf(Float(g * 255)), lroundf(Float(b * 255)))
    }
}
