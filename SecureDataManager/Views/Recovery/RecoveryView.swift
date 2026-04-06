//
//  RecoveryView.swift
//  SecureDataManager
//
//  Vista para recuperación de contraseña usando Shamir Secret Sharing
//

import SwiftUI
import CryptoKit

struct RecoveryView: View {
    
    @Binding var isAuthenticated: Bool
    @Environment(\.dismiss) private var dismiss
    
    @State private var shareCodes: [String] = ["", "", ""]
    @State private var isRecovering: Bool = false
    @State private var errorMessage: String?
    @State private var showNewPasswordSetup: Bool = false
    @State private var recoveredSalt: Data?
    
    private let shamir = ShamirSecretSharing()
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 12) {
                    Image(systemName: "key.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(.orange)
                    
                    Text("Recuperación de Contraseña")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Ingresa 3 de tus 5 códigos de recuperación para restaurar el acceso.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 20)
                
                // Campos de shares
                VStack(spacing: 16) {
                    ForEach(0..<3) { index in
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Código de recuperación \(index + 1)")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundStyle(.secondary)
                            
                            TextField("Pega el código aquí", text: $shareCodes[index])
                                .textContentType(.none)
                                .autocorrectionDisabled()
                                .textInputAutocapitalization(.never)
                                .font(.system(.body, design: .monospaced))
                                .padding()
                                .background(Color(.systemGray6))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                    }
                }
                
                if let errorMessage = errorMessage {
                    Label(errorMessage, systemImage: "exclamationmark.circle")
                        .font(.subheadline)
                        .foregroundStyle(.red)
                        .padding()
                        .background(Color.red.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                
                // Botón de recuperación
                Button(action: attemptRecovery) {
                    if isRecovering {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .padding()
                    } else {
                        Text("Recuperar Acceso")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                    }
                }
                .background(allFieldsFilled ? Color.orange : Color.gray)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .disabled(!allFieldsFilled || isRecovering)
                
                // Información adicional
                VStack(alignment: .leading, spacing: 12) {
                    Label("Los códigos de recuperación se mostraron al configurar la aplicación.", systemImage: "info.circle")
                    
                    Label("Guarda tus códigos en un lugar seguro fuera de este dispositivo.", systemImage: "exclamationmark.shield")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding()
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                
                Spacer()
            }
            .padding()
        }
        .navigationTitle("Recuperación")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showNewPasswordSetup) {
            if let salt = recoveredSalt {
                NewPasswordAfterRecoveryView(
                    recoveredSalt: salt,
                    isAuthenticated: $isAuthenticated,
                    onComplete: { dismiss() }
                )
            }
        }
    }
    
    private var allFieldsFilled: Bool {
        shareCodes.allSatisfy { !$0.isEmpty }
    }
    
    private func attemptRecovery() {
        isRecovering = true
        errorMessage = nil
        
        Task {
            do {
                // Intentar reconstruir el secreto
                let secretData = try shamir.combine(shares: shareCodes.compactMap { SecretShare(shareCode: $0) })
                
                await MainActor.run {
                    self.recoveredSalt = secretData
                    self.isRecovering = false
                    self.showNewPasswordSetup = true
                }
                
            } catch {
                await MainActor.run {
                    self.errorMessage = "Códigos inválidos. Verifica que sean correctos."
                    self.isRecovering = false
                }
            }
        }
    }
}

/// Vista para configurar nueva contraseña después de recuperación
struct NewPasswordAfterRecoveryView: View {
    
    let recoveredSalt: Data
    @Binding var isAuthenticated: Bool
    let onComplete: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    @State private var newPassword: String = ""
    @State private var confirmPassword: String = ""
    @State private var isSettingUp: Bool = false
    @State private var errorMessage: String?
    @State private var showPassword: Bool = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                VStack(spacing: 12) {
                    Image(systemName: "lock.rotation")
                        .font(.system(size: 60))
                        .foregroundStyle(.green)
                    
                    Text("Nueva Contraseña")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Establece una nueva contraseña maestra para tu cuenta.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 40)
                
                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Nueva contraseña")
                            .font(.headline)
                        
                        HStack {
                            if showPassword {
                                TextField("Mínimo 12 caracteres", text: $newPassword)
                            } else {
                                SecureField("Mínimo 12 caracteres", text: $newPassword)
                            }
                            
                            Button(action: { showPassword.toggle() }) {
                                Image(systemName: showPassword ? "eye.slash" : "eye")
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        
                        // Indicador de fortaleza
                        PasswordStrengthBar(password: newPassword)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Confirmar contraseña")
                            .font(.headline)
                        
                        SecureField("Repite la contraseña", text: $confirmPassword)
                            .padding()
                            .background(Color(.systemGray6))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    
                    if let errorMessage = errorMessage {
                        Label(errorMessage, systemImage: "exclamationmark.triangle")
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }
                
                Spacer()
                
                Button(action: setupNewPassword) {
                    if isSettingUp {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .padding()
                    } else {
                        Text("Establecer Contraseña")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                    }
                }
                .background(canProceed ? Color.green : Color.gray)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .disabled(!canProceed || isSettingUp)
                .padding(.bottom, 30)
            }
            .padding(.horizontal, 30)
            .navigationTitle("Nueva Contraseña")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    private var canProceed: Bool {
        newPassword.isValidPassword && newPassword == confirmPassword
    }
    
    private func setupNewPassword() {
        guard newPassword == confirmPassword else {
            errorMessage = "Las contraseñas no coinciden"
            return
        }
        
        guard newPassword.isValidPassword else {
            errorMessage = "La contraseña no cumple con los requisitos"
            return
        }
        
        isSettingUp = true
        
        Task {
            do {
                // Usar el salt recuperado para derivar la clave
                let cryptoService = CryptoService()
                let passwordHash = try cryptoService.hashPassword(newPassword, salt: recoveredSalt)
                let masterKey = try cryptoService.deriveKey(from: newPassword, salt: recoveredSalt)
                
                // Guardar en Keychain
                try KeychainManager.shared.saveSalt(recoveredSalt)
                try KeychainManager.shared.savePasswordHash(passwordHash)
                try KeychainManager.shared.saveMasterKey(masterKey)
                
                await MainActor.run {
                    isAuthenticated = true
                    dismiss()
                    onComplete()
                }
                
            } catch {
                await MainActor.run {
                    errorMessage = "Error al configurar: \(error.localizedDescription)"
                    isSettingUp = false
                }
            }
        }
    }
}

/// Barra de fortaleza de contraseña
struct PasswordStrengthBar: View {
    let password: String
    
    var strength: Double {
        password.passwordStrength
    }
    
    var color: Color {
        switch strength {
        case 0..<0.3: return .red
        case 0.3..<0.5: return .orange
        case 0.5..<0.7: return .yellow
        case 0.7..<0.9: return .green
        default: return .blue
        }
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 4)
                
                Rectangle()
                    .fill(color)
                    .frame(width: geometry.size.width * strength, height: 4)
                    .animation(.easeInOut, value: strength)
            }
        }
        .frame(height: 4)
    }
}

#Preview {
    RecoveryView(isAuthenticated: .constant(false))
}
