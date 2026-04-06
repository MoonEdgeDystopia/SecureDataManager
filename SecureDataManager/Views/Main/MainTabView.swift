//
//  MainTabView.swift
//  SecureDataManager
//
//  Vista principal con tabs
//

import SwiftUI
import CryptoKit

struct MainTabView: View {
    
    @Binding var isAuthenticated: Bool
    let masterKey: SymmetricKey
    
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Tab de Cuentas
            AccountsListView()
                .tabItem {
                    Label("Cuentas", systemImage: "key.fill")
                }
                .tag(0)
            
            // Tab de Documentos
            DocumentsListView()
                .tabItem {
                    Label("Documentos", systemImage: "doc.fill")
                }
                .tag(1)
            
            // Tab de Fotos
            PhotosGridView()
                .tabItem {
                    Label("Fotos", systemImage: "photo.fill")
                }
                .tag(2)
            
            // Tab de Configuración
            SettingsView(isAuthenticated: $isAuthenticated)
                .tabItem {
                    Label("Ajustes", systemImage: "gear")
                }
                .tag(3)
        }
        .environment(\.masterKey, masterKey)
    }
}

// MARK: - Environment Key para Master Key

private struct MasterKeyKey: EnvironmentKey {
    static let defaultValue: SymmetricKey? = nil
}

extension EnvironmentValues {
    var masterKey: SymmetricKey? {
        get { self[MasterKeyKey.self] }
        set { self[MasterKeyKey.self] = newValue }
    }
}

// MARK: - Settings View

struct SettingsView: View {
    
    @Binding var isAuthenticated: Bool
    @Environment(\.masterKey) private var masterKey
    
    @State private var showLogoutConfirmation: Bool = false
    @State private var showBiometricToggle: Bool = false
    @State private var isBiometricEnabled: Bool = false
    @State private var accountCount: Int = 0
    @State private var documentCount: Int = 0
    @State private var photoCount: Int = 0
    
    var body: some View {
        NavigationStack {
            List {
                // Sección de seguridad
                Section("Seguridad") {
                    NavigationLink("Cambiar Contraseña") {
                        ChangePasswordView()
                    }
                    
                    Toggle("Face ID / Touch ID", isOn: $isBiometricEnabled)
                        .onChange(of: isBiometricEnabled) { _, newValue in
                            updateBiometricSetting(enabled: newValue)
                        }
                }
                
                // Sección de estadísticas
                Section("Almacenamiento") {
                    StatRow(title: "Cuentas guardadas", value: accountCount, icon: "key.fill", color: .blue)
                    StatRow(title: "Documentos", value: documentCount, icon: "doc.fill", color: .green)
                    StatRow(title: "Fotos", value: photoCount, icon: "photo.fill", color: .purple)
                }
                
                // Sección de información
                Section("Información") {
                    HStack {
                        Text("Versión")
                        Spacer()
                        Text("1.0.0")
                            .foregroundStyle(.secondary)
                    }
                    
                    HStack {
                        Text("Cifrado")
                        Spacer()
                        Text("AES-256-GCM")
                            .foregroundStyle(.secondary)
                    }
                }
                
                // Cerrar sesión
                Section {
                    Button("Cerrar Sesión") {
                        showLogoutConfirmation = true
                    }
                    .foregroundStyle(.red)
                }
            }
            .navigationTitle("Ajustes")
            .onAppear {
                loadStats()
                loadBiometricSetting()
            }
            .confirmationDialog("¿Cerrar sesión?", isPresented: $showLogoutConfirmation, titleVisibility: .visible) {
                Button("Cerrar Sesión", role: .destructive) {
                    logout()
                }
                Button("Cancelar", role: .cancel) {}
            }
        }
    }
    
    private func loadStats() {
        accountCount = DataStore.shared.accounts.count
        documentCount = DataStore.shared.documents.count
        photoCount = DataStore.shared.photos.count
    }
    
    private func loadBiometricSetting() {
        isBiometricEnabled = (try? KeychainManager.shared.isBiometricEnabled()) ?? false
    }
    
    private func updateBiometricSetting(enabled: Bool) {
        do {
            try KeychainManager.shared.saveBiometricEnabled(enabled)
        } catch {
            isBiometricEnabled = !enabled
        }
    }
    
    private func logout() {
        isAuthenticated = false
    }
}

/// Fila de estadística
struct StatRow: View {
    let title: String
    let value: Int
    let icon: String
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(color)
                .frame(width: 24)
            
            Text(title)
            
            Spacer()
            
            Text("\(value)")
                .fontWeight(.medium)
                .foregroundStyle(.secondary)
        }
    }
}

/// Vista de cambio de contraseña
struct ChangePasswordView: View {
    
    @Environment(\.dismiss) private var dismiss
    
    @State private var currentPassword: String = ""
    @State private var newPassword: String = ""
    @State private var confirmPassword: String = ""
    @State private var isChanging: Bool = false
    @State private var errorMessage: String?
    @State private var successMessage: String?
    
    var body: some View {
        Form {
            Section("Contraseña Actual") {
                SecureField("Contraseña actual", text: $currentPassword)
            }
            
            Section("Nueva Contraseña") {
                SecureField("Nueva contraseña", text: $newPassword)
                
                if !newPassword.isEmpty {
                    PasswordStrengthBar(password: newPassword)
                        .frame(height: 4)
                }
                
                SecureField("Confirmar nueva contraseña", text: $confirmPassword)
            }
            
            if let errorMessage = errorMessage {
                Section {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                        .font(.caption)
                }
            }
            
            if let successMessage = successMessage {
                Section {
                    Text(successMessage)
                        .foregroundStyle(.green)
                        .font(.caption)
                }
            }
            
            Section {
                Button(action: changePassword) {
                    if isChanging {
                        ProgressView()
                    } else {
                        Text("Cambiar Contraseña")
                    }
                }
                .disabled(!canChange || isChanging)
            }
        }
        .navigationTitle("Cambiar Contraseña")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private var canChange: Bool {
        !currentPassword.isEmpty &&
        newPassword.isValidPassword &&
        newPassword == confirmPassword
    }
    
    private func changePassword() {
        isChanging = true
        errorMessage = nil
        
        Task {
            do {
                // Verificar contraseña actual
                guard let salt = try KeychainManager.shared.getSalt(),
                      let storedHash = try KeychainManager.shared.getPasswordHash() else {
                    throw NSError(domain: "ChangePassword", code: -1)
                }
                
                let cryptoService = CryptoService()
                let isValid = try cryptoService.verifyPassword(currentPassword, against: storedHash, salt: salt)
                
                guard isValid else {
                    await MainActor.run {
                        errorMessage = "Contraseña actual incorrecta"
                        isChanging = false
                    }
                    return
                }
                
                // Generar nuevo hash y clave
                let newHash = try cryptoService.hashPassword(newPassword, salt: salt)
                let newMasterKey = try cryptoService.deriveKey(from: newPassword, salt: salt)
                
                // Guardar nuevos valores
                try KeychainManager.shared.savePasswordHash(newHash)
                try KeychainManager.shared.saveMasterKey(newMasterKey)
                
                await MainActor.run {
                    successMessage = "Contraseña cambiada exitosamente"
                    isChanging = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        dismiss()
                    }
                }
                
            } catch {
                await MainActor.run {
                    errorMessage = "Error al cambiar contraseña"
                    isChanging = false
                }
            }
        }
    }
}

#Preview {
    MainTabView(isAuthenticated: .constant(true), masterKey: SymmetricKey(size: .bits256))
}
