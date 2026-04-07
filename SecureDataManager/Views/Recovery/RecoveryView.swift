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
        NavigationStack {
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
                        
                        Text("Ingresa los 3 códigos de recuperación (1, 2, 3) para restaurar el acceso.")
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
                NewPasswordAfterRecoveryView(
                    recoveredSalt: recoveredSalt ?? Data(),
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
        
        print("=== INICIANDO RECUPERACIÓN ===")
        print("Códigos ingresados: \(shareCodes)")
        
        Task {
            do {
                // Limpiar códigos
                let cleanedCodes = shareCodes.map { 
                    $0.trimmingCharacters(in: .whitespacesAndNewlines) 
                }
                
                print("Códigos limpios: \(cleanedCodes)")
                
                // Crear shares
                var validShares: [SecretShare] = []
                for (i, code) in cleanedCodes.enumerated() {
                    if let share = SecretShare(shareCode: code) {
                        validShares.append(share)
                        print("Share \(i+1) válido: index=\(share.index), valueSize=\(share.value.count)")
                    } else {
                        print("Share \(i+1) inválido")
                    }
                }
                
                guard validShares.count >= 3 else {
                    print("Error: Solo \(validShares.count) shares válidos, se necesitan 3")
                    throw ShamirError.insufficientShares
                }
                
                // IMPORTANTE: Usar los shares con índices 1, 2, 3 (los originales)
                // Ordenar por índice y tomar los primeros 3
                let sortedShares = validShares.sorted { $0.index < $1.index }
                let sharesToUse = Array(sortedShares.prefix(3))
                
                print("Usando shares con índices: \(sharesToUse.map { $0.index })")
                
                // Verificar que tenemos los índices correctos (1, 2, 3)
                let expectedIndices: [UInt8] = [1, 2, 3]
                let actualIndices = sharesToUse.map { $0.index }
                
                if actualIndices != expectedIndices {
                    print("Advertencia: Los índices no son 1,2,3. Son: \(actualIndices)")
                }
                
                // Reconstruir
                print("Reconstruyendo secreto con \(sharesToUse.count) shares...")
                let secretData = try shamir.combine(shares: sharesToUse)
                print("Secreto reconstruido: \(secretData.count) bytes")
                print("Bytes (hex): \(secretData.map { String(format: "%02x", $0) }.joined())")
                
                // Verificar que el salt tiene el tamaño correcto (32 bytes)
                guard secretData.count == 32 else {
                    print("Error: Salt reconstruido tiene \(secretData.count) bytes, se esperaban 32")
                    throw ShamirError.reconstructionFailed
                }
                
                await MainActor.run {
                    self.recoveredSalt = secretData
                    self.isRecovering = false
                    self.showNewPasswordSetup = true
                    print("Recuperación exitosa!")
                }
                
            } catch let error as ShamirError {
                print("Error de Shamir: \(error)")
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isRecovering = false
                }
            } catch {
                print("Error inesperado: \(error)")
                await MainActor.run {
                    self.errorMessage = "Error al recuperar: \(error.localizedDescription)"
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
        print("=== CONFIGURANDO NUEVA CONTRASEÑA ===")
        print("Salt recuperado: \(recoveredSalt.count) bytes")
        
        Task {
            do {
                let cryptoService = CryptoService()
                let passwordHash = try cryptoService.hashPassword(newPassword, salt: recoveredSalt)
                let masterKey = try cryptoService.deriveKey(from: newPassword, salt: recoveredSalt)
                
                print("Hash y clave derivados exitosamente")
                
                // Guardar en Keychain
                try KeychainManager.shared.saveSalt(recoveredSalt)
                try KeychainManager.shared.savePasswordHash(passwordHash)
                
                // Guardar masterKey
                AuthStateManager.shared.masterKey = masterKey
                print("Datos guardados en Keychain")
                
                await MainActor.run {
                    isAuthenticated = true
                    print("Navegando a pantalla principal...")
                    dismiss()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        onComplete()
                    }
                }
                
            } catch {
                print("Error: \(error)")
                await MainActor.run {
                    errorMessage = "Error al configurar: \(error.localizedDescription)"
                    isSettingUp = false
                }
            }
        }
    }
}

#Preview {
    RecoveryView(isAuthenticated: .constant(false))
}
