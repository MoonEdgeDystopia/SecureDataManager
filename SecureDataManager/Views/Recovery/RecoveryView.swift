//
//  RecoveryView.swift
//  SecureDataManager
//
//  Vista para recuperación de contraseña con preguntas + código
//

import SwiftUI
import CryptoKit

struct RecoveryView: View {
    
    @Binding var isAuthenticated: Bool
    @Environment(\.dismiss) private var dismiss
    
    @State private var answers: [String] = ["", "", ""]
    @State private var recoveryCode: String = ""
    @State private var isVerifying: Bool = false
    @State private var errorMessage: String?
    @State private var showNewPasswordSetup: Bool = false
    @State private var recoveredSalt: Data?
    @State private var recoveryData: RecoveryData?
    
    private let recoveryManager = RecoveryManager.shared
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 12) {
                        Image(systemName: "key.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(.orange)
                        
                        Text("Recuperación de Cuenta")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("Responde tus preguntas de seguridad e ingresa tu código de recuperación.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 20)
                    
                    if let data = recoveryData {
                        // Preguntas de seguridad
                        VStack(alignment: .leading, spacing: 20) {
                            Text("Preguntas de Seguridad")
                                .font(.headline)
                                .padding(.horizontal)
                            
                            // Pregunta 1
                            VStack(alignment: .leading, spacing: 8) {
                                Text(data.question1)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                
                                SecureField("Tu respuesta", text: $answers[0])
                                    .textContentType(.none)
                                    .autocorrectionDisabled()
                                    .padding()
                                    .background(Color(.systemGray6))
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                            .padding(.horizontal)
                            
                            // Pregunta 2
                            VStack(alignment: .leading, spacing: 8) {
                                Text(data.question2)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                
                                SecureField("Tu respuesta", text: $answers[1])
                                    .textContentType(.none)
                                    .autocorrectionDisabled()
                                    .padding()
                                    .background(Color(.systemGray6))
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                            .padding(.horizontal)
                            
                            // Pregunta 3
                            VStack(alignment: .leading, spacing: 8) {
                                Text(data.question3)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                
                                SecureField("Tu respuesta", text: $answers[2])
                                    .textContentType(.none)
                                    .autocorrectionDisabled()
                                    .padding()
                                    .background(Color(.systemGray6))
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                            .padding(.horizontal)
                        }
                        
                        // Código de recuperación
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Código de Recuperación")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .padding(.horizontal)
                            
                            TextField("Pega tu código aquí", text: $recoveryCode)
                                .textContentType(.none)
                                .autocorrectionDisabled()
                                .textInputAutocapitalization(.never)
                                .font(.system(.body, design: .monospaced))
                                .padding()
                                .background(Color(.systemGray6))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                .padding(.horizontal)
                        }
                        
                        if let errorMessage = errorMessage {
                            Label(errorMessage, systemImage: "exclamationmark.circle")
                                .font(.subheadline)
                                .foregroundStyle(.red)
                                .padding()
                                .background(Color.red.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                .padding(.horizontal)
                        }
                        
                        // Botón de recuperación
                        Button(action: attemptRecovery) {
                            if isVerifying {
                                ProgressView()
                                    .frame(maxWidth: .infinity)
                                    .padding()
                            } else {
                                Text("Recuperar Cuenta")
                                    .font(.headline)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                            }
                        }
                        .background(allFieldsFilled ? Color.orange : Color.gray)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .disabled(!allFieldsFilled || isVerifying)
                        .padding(.horizontal)
                    } else {
                        // Cargando datos de recuperación
                        VStack(spacing: 16) {
                            ProgressView()
                                .scaleEffect(1.5)
                            Text("Cargando datos de recuperación...")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.top, 40)
                    }
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Recuperación")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                loadRecoveryData()
            }
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
    }
    
    private var allFieldsFilled: Bool {
        !answers[0].isEmpty &&
        !answers[1].isEmpty &&
        !answers[2].isEmpty &&
        !recoveryCode.isEmpty
    }
    
    private func loadRecoveryData() {
        do {
            recoveryData = try KeychainManager.shared.getRecoveryData()
            if recoveryData == nil {
                errorMessage = "No se encontraron datos de recuperación"
            }
        } catch {
            errorMessage = "Error al cargar datos: \(error.localizedDescription)"
        }
    }
    
    private func attemptRecovery() {
        isVerifying = true
        errorMessage = nil
        
        print("=== INICIANDO RECUPERACIÓN ===")
        print("Respuestas proporcionadas")
        
        Task {
            do {
                guard let data = recoveryData else {
                    throw RecoveryError.recoveryDataNotFound
                }
                
                // Limpiar respuestas
                let cleanedAnswers = answers.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                let cleanedCode = recoveryCode.trimmingCharacters(in: .whitespacesAndNewlines)
                
                print("Verificando respuestas...")
                
                // Verificar respuestas
                let answersValid = recoveryManager.verifyAnswers(
                    answers: cleanedAnswers,
                    recoveryData: data
                )
                
                guard answersValid else {
                    print("Respuestas incorrectas")
                    throw RecoveryError.invalidAnswer
                }
                
                print("Respuestas correctas, verificando código...")
                
                // Verificar código
                let codeValid = recoveryManager.verifyCode(
                    code: cleanedCode,
                    recoveryData: data
                )
                
                guard codeValid else {
                    print("Código incorrecto")
                    throw RecoveryError.invalidCode
                }
                
                print("Código correcto, recuperando salt maestro...")
                
                // Recuperar salt maestro
                let masterSalt = try recoveryManager.recoverMasterSalt(
                    answers: cleanedAnswers,
                    code: cleanedCode,
                    recoveryData: data
                )
                
                print("Salt maestro recuperado: \(masterSalt.count) bytes")
                
                await MainActor.run {
                    self.recoveredSalt = masterSalt
                    self.isVerifying = false
                    self.showNewPasswordSetup = true
                    print("Recuperación exitosa!")
                }
                
            } catch let error as RecoveryError {
                print("Error de recuperación: \(error)")
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isVerifying = false
                }
            } catch {
                print("Error inesperado: \(error)")
                await MainActor.run {
                    self.errorMessage = "Error al recuperar: \(error.localizedDescription)"
                    self.isVerifying = false
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
