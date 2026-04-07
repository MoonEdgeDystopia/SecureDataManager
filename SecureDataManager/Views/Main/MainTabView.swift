//
//  MainTabView.swift
//  SecureDataManager
//
//  Vista principal con tabs - Estilo Metálico
//

import SwiftUI
import CryptoKit

struct MainTabView: View {
    
    @Binding var isAuthenticated: Bool
    let masterKey: SymmetricKey
    
    @State private var selectedTab = 0
    @Environment(\.colorScheme) var colorScheme
    
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
        .onAppear {
            // Configurar apariencia del tab bar para tema metálico
            let appearance = UITabBarAppearance()
            
            if colorScheme == .dark {
                appearance.backgroundColor = UIColor(red: 0.12, green: 0.13, blue: 0.15, alpha: 1.0)
            } else {
                appearance.backgroundColor = UIColor(red: 0.92, green: 0.93, blue: 0.95, alpha: 1.0)
            }
            
            appearance.stackedLayoutAppearance.normal.iconColor = UIColor(red: 0.50, green: 0.52, blue: 0.55, alpha: 1.0)
            appearance.stackedLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor(red: 0.50, green: 0.52, blue: 0.55, alpha: 1.0)]
            
            appearance.stackedLayoutAppearance.selected.iconColor = UIColor(red: 0.35, green: 0.45, blue: 0.65, alpha: 1.0)
            appearance.stackedLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: UIColor(red: 0.35, green: 0.45, blue: 0.65, alpha: 1.0)]
            
            UITabBar.appearance().standardAppearance = appearance
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
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
    @Environment(\.colorScheme) var colorScheme
    
    @State private var showLogoutConfirmation: Bool = false
    @State private var showBiometricToggle: Bool = false
    @State private var isBiometricEnabled: Bool = false
    @State private var accountCount: Int = 0
    @State private var documentCount: Int = 0
    @State private var photoCount: Int = 0
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Fondo metálico sutil
                MetallicBackground()
                
                List {
                    // Sección de seguridad
                    Section {
                        NavigationLink {
                            ChangePasswordView()
                        } label: {
                            HStack {
                                Image(systemName: "lock.circle.fill")
                                    .font(.title2)
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [Color(red: 0.35, green: 0.45, blue: 0.65), Color(red: 0.25, green: 0.35, blue: 0.55)],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                                
                                Text("Cambiar Contraseña")
                                    .foregroundStyle(colorScheme == .dark ? .white : .primary)
                            }
                        }
                        
                        HStack {
                            Image(systemName: "faceid")
                                .font(.title2)
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [Color(red: 0.35, green: 0.55, blue: 0.65), Color(red: 0.25, green: 0.45, blue: 0.55)],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                            
                            Text("Face ID / Touch ID")
                                .foregroundStyle(colorScheme == .dark ? .white : .primary)
                            
                            Spacer()
                            
                            Toggle("", isOn: $isBiometricEnabled)
                                .toggleStyle(SwitchToggleStyle(tint: Color(red: 0.40, green: 0.50, blue: 0.70)))
                                .onChange(of: isBiometricEnabled) { _, newValue in
                                    updateBiometricSetting(enabled: newValue)
                                }
                        }
                    } header: {
                        Text("Seguridad")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(
                                LinearGradient(
                                    colors: colorScheme == .dark
                                        ? [Color(red: 0.60, green: 0.65, blue: 0.75), Color(red: 0.45, green: 0.50, blue: 0.60)]
                                        : [Color(red: 0.35, green: 0.40, blue: 0.50), Color(red: 0.50, green: 0.55, blue: 0.65)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    }
                    .listRowBackground(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(MetallicColors.cardGradient(isDark: colorScheme == .dark))
                            .padding(EdgeInsets(top: 2, leading: 6, bottom: 2, trailing: 6))
                    )
                    
                    // Sección de estadísticas
                    Section {
                        MetallicStatRow(title: "Cuentas guardadas", value: accountCount, icon: "key.fill", gradient: [
                            Color(red: 0.35, green: 0.55, blue: 0.85),
                            Color(red: 0.25, green: 0.45, blue: 0.75)
                        ])
                        
                        MetallicStatRow(title: "Documentos", value: documentCount, icon: "doc.fill", gradient: [
                            Color(red: 0.35, green: 0.75, blue: 0.55),
                            Color(red: 0.25, green: 0.65, blue: 0.45)
                        ])
                        
                        MetallicStatRow(title: "Fotos", value: photoCount, icon: "photo.fill", gradient: [
                            Color(red: 0.75, green: 0.45, blue: 0.85),
                            Color(red: 0.65, green: 0.35, blue: 0.75)
                        ])
                    } header: {
                        Text("Almacenamiento")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(
                                LinearGradient(
                                    colors: colorScheme == .dark
                                        ? [Color(red: 0.60, green: 0.65, blue: 0.75), Color(red: 0.45, green: 0.50, blue: 0.60)]
                                        : [Color(red: 0.35, green: 0.40, blue: 0.50), Color(red: 0.50, green: 0.55, blue: 0.65)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    }
                    .listRowBackground(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(MetallicColors.cardGradient(isDark: colorScheme == .dark))
                            .padding(EdgeInsets(top: 2, leading: 6, bottom: 2, trailing: 6))
                    )
                    
                    // Sección de información
                    Section {
                        HStack {
                            Text("Versión")
                                .foregroundStyle(colorScheme == .dark ? .white : .primary)
                            Spacer()
                            Text("1.0.0")
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: colorScheme == .dark
                                            ? [Color(red: 0.60, green: 0.65, blue: 0.75), Color(red: 0.45, green: 0.50, blue: 0.60)]
                                            : [Color(red: 0.45, green: 0.50, blue: 0.60), Color(red: 0.60, green: 0.65, blue: 0.75)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                        }
                        
                        HStack {
                            Text("Cifrado")
                                .foregroundStyle(colorScheme == .dark ? .white : .primary)
                            Spacer()
                            Text("AES-256-GCM")
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [
                                            Color(red: 0.30, green: 0.70, blue: 0.50),
                                            Color(red: 0.20, green: 0.60, blue: 0.40)
                                        ],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .fontWeight(.medium)
                        }
                    } header: {
                        Text("Información")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(
                                LinearGradient(
                                    colors: colorScheme == .dark
                                        ? [Color(red: 0.60, green: 0.65, blue: 0.75), Color(red: 0.45, green: 0.50, blue: 0.60)]
                                        : [Color(red: 0.35, green: 0.40, blue: 0.50), Color(red: 0.50, green: 0.55, blue: 0.65)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    }
                    .listRowBackground(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(MetallicColors.cardGradient(isDark: colorScheme == .dark))
                            .padding(EdgeInsets(top: 2, leading: 6, bottom: 2, trailing: 6))
                    )
                    
                    // Cerrar sesión
                    Section {
                        Button("Cerrar Sesión") {
                            showLogoutConfirmation = true
                        }
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.red.opacity(0.9), Color.red.opacity(0.7)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .fontWeight(.medium)
                    }
                    .listRowBackground(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(MetallicColors.cardGradient(isDark: colorScheme == .dark))
                            .padding(EdgeInsets(top: 2, leading: 6, bottom: 2, trailing: 6))
                    )
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
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

/// Fila de estadística estilo metálico
struct MetallicStatRow: View {
    let title: String
    let value: Int
    let icon: String
    let gradient: [Color]
    
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(
                    LinearGradient(
                        colors: gradient,
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 30)
            
            Text(title)
                .foregroundStyle(colorScheme == .dark ? .white : .primary)
            
            Spacer()
            
            Text("\(value)")
                .font(.system(.body, design: .rounded))
                .fontWeight(.bold)
                .foregroundStyle(
                    LinearGradient(
                        colors: colorScheme == .dark
                            ? [Color(red: 0.80, green: 0.85, blue: 0.95), Color(red: 0.60, green: 0.65, blue: 0.80)]
                            : [Color(red: 0.30, green: 0.35, blue: 0.50), Color(red: 0.50, green: 0.55, blue: 0.70)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
        }
    }
}

/// Vista de cambio de contraseña estilo metálico
struct ChangePasswordView: View {
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) var colorScheme
    
    @State private var currentPassword: String = ""
    @State private var newPassword: String = ""
    @State private var confirmPassword: String = ""
    @State private var isChanging: Bool = false
    @State private var errorMessage: String?
    @State private var successMessage: String?
    
    var body: some View {
        ZStack {
            MetallicBackground()
            
            ScrollView {
                VStack(spacing: 24) {
                    MetallicHeader(
                        title: "Cambiar Contraseña",
                        icon: "lock.rotation",
                        iconSize: 70
                    )
                    
                    VStack(spacing: 20) {
                        // Contraseña actual
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Contraseña Actual")
                                .font(.headline)
                                .foregroundStyle(
                                    colorScheme == .dark
                                        ? Color(red: 0.80, green: 0.85, blue: 0.95)
                                        : Color(red: 0.25, green: 0.30, blue: 0.45)
                                )
                            
                            SecureField("Contraseña actual", text: $currentPassword)
                                .foregroundStyle(colorScheme == .dark ? .white : .primary)
                                .metallicTextField()
                        }
                        
                        // Nueva contraseña
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Nueva Contraseña")
                                .font(.headline)
                                .foregroundStyle(
                                    colorScheme == .dark
                                        ? Color(red: 0.80, green: 0.85, blue: 0.95)
                                        : Color(red: 0.25, green: 0.30, blue: 0.45)
                                )
                            
                            SecureField("Nueva contraseña", text: $newPassword)
                                .foregroundStyle(colorScheme == .dark ? .white : .primary)
                                .metallicTextField()
                            
                            if !newPassword.isEmpty {
                                MetallicStrengthBar(strength: newPassword.passwordStrength)
                            }
                            
                            SecureField("Confirmar nueva contraseña", text: $confirmPassword)
                                .foregroundStyle(colorScheme == .dark ? .white : .primary)
                                .metallicTextField()
                        }
                        
                        if let errorMessage = errorMessage {
                            Label(errorMessage, systemImage: "exclamationmark.triangle")
                                .font(.caption)
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [Color.red.opacity(0.9), Color.red.opacity(0.7)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.red.opacity(0.1))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(Color.red.opacity(0.3), lineWidth: 1)
                                        )
                                )
                        }
                        
                        if let successMessage = successMessage {
                            Label(successMessage, systemImage: "checkmark.circle.fill")
                                .font(.caption)
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [Color.green.opacity(0.9), Color.green.opacity(0.7)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.green.opacity(0.1))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(Color.green.opacity(0.3), lineWidth: 1)
                                        )
                                )
                        }
                    }
                    .padding(24)
                    .metallicCard()
                    
                    Button(action: changePassword) {
                        if isChanging {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                                .padding()
                        } else {
                            Text("Cambiar Contraseña")
                                .font(.headline)
                                .fontWeight(.bold)
                                .frame(maxWidth: .infinity)
                                .padding()
                        }
                    }
                    .foregroundStyle(.white)
                    .frame(height: 54)
                    .metallicButton(isEnabled: canChange && !isChanging)
                    .disabled(!canChange || isChanging)
                    
                    Spacer(minLength: 30)
                }
                .padding()
                .padding(.top, 20)
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
                      let storedHash = try KeychainManager.shared.getPasswordHash(),
                      let encryptedMasterKey = try KeychainManager.shared.getEncryptedMasterKey() else {
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
                
                // Desencriptar la master key actual
                let masterKey = try cryptoService.decryptMasterKey(encryptedMasterKey, password: currentPassword, salt: salt)
                
                // Re-encriptar con la nueva contraseña
                let newHash = try cryptoService.hashPassword(newPassword, salt: salt)
                let newEncryptedMasterKey = try cryptoService.encryptMasterKey(masterKey, password: newPassword, salt: salt)
                
                // Guardar nuevos valores
                try KeychainManager.shared.savePasswordHash(newHash)
                try KeychainManager.shared.saveEncryptedMasterKey(newEncryptedMasterKey)
                
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
