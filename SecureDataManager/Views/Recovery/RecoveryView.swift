//
//  RecoveryView.swift
//  SecureDataManager
//
//  Vista para recuperación de contraseña con preguntas + código - Estilo Metálico
//

import SwiftUI
import CryptoKit

struct RecoveryView: View {
    
    @Binding var isAuthenticated: Bool
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) var colorScheme
    
    @State private var answers: [String] = ["", "", ""]
    @State private var recoveryCode: String = ""
    @State private var isVerifying: Bool = false
    @State private var errorMessage: String?
    @State private var showNewPasswordSetup: Bool = false
    @State private var recoveredMasterKey: SymmetricKey?
    @State private var recoveryData: RecoveryData?
    
    private let recoveryManager = RecoveryManager.shared
    
    var body: some View {
        NavigationStack {
            ZStack {
                MetallicBackground()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        MetallicHeader(
                            title: "Recuperación",
                            icon: "key.fill",
                            iconSize: 70
                        )
                        
                        Text("Responde tus preguntas de seguridad e ingresa tu código de recuperación.")
                            .font(.subheadline)
                            .multilineTextAlignment(.center)
                            .foregroundStyle(
                                LinearGradient(
                                    colors: colorScheme == .dark
                                        ? [Color(red: 0.60, green: 0.65, blue: 0.75), Color(red: 0.45, green: 0.50, blue: 0.60)]
                                        : [Color(red: 0.35, green: 0.40, blue: 0.50), Color(red: 0.50, green: 0.55, blue: 0.65)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .padding(.horizontal)
                        
                        if let data = recoveryData {
                            // Preguntas de seguridad
                            VStack(alignment: .leading, spacing: 20) {
                                Text("Preguntas de Seguridad")
                                    .font(.headline)
                                    .foregroundStyle(
                                        colorScheme == .dark
                                            ? Color(red: 0.80, green: 0.85, blue: 0.95)
                                            : Color(red: 0.25, green: 0.30, blue: 0.45)
                                    )
                                
                                // Pregunta 1
                                VStack(alignment: .leading, spacing: 8) {
                                    Text(data.question1)
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .foregroundStyle(
                                            colorScheme == .dark
                                                ? Color(red: 0.65, green: 0.70, blue: 0.80)
                                                : Color(red: 0.35, green: 0.40, blue: 0.50)
                                        )
                                    
                                    SecureField("Tu respuesta", text: $answers[0])
                                        .textContentType(.none)
                                        .autocorrectionDisabled()
                                        .metallicTextField()
                                }
                                
                                // Pregunta 2
                                VStack(alignment: .leading, spacing: 8) {
                                    Text(data.question2)
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .foregroundStyle(
                                            colorScheme == .dark
                                                ? Color(red: 0.65, green: 0.70, blue: 0.80)
                                                : Color(red: 0.35, green: 0.40, blue: 0.50)
                                        )
                                    
                                    SecureField("Tu respuesta", text: $answers[1])
                                        .textContentType(.none)
                                        .autocorrectionDisabled()
                                        .metallicTextField()
                                }
                                
                                // Pregunta 3
                                VStack(alignment: .leading, spacing: 8) {
                                    Text(data.question3)
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .foregroundStyle(
                                            colorScheme == .dark
                                                ? Color(red: 0.65, green: 0.70, blue: 0.80)
                                                : Color(red: 0.35, green: 0.40, blue: 0.50)
                                        )
                                    
                                    SecureField("Tu respuesta", text: $answers[2])
                                        .textContentType(.none)
                                        .autocorrectionDisabled()
                                        .metallicTextField()
                                }
                            }
                            .padding(24)
                            .metallicCard()
                            
                            // Código de recuperación
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Código de Recuperación")
                                    .font(.headline)
                                    .foregroundStyle(
                                        colorScheme == .dark
                                            ? Color(red: 0.80, green: 0.85, blue: 0.95)
                                            : Color(red: 0.25, green: 0.30, blue: 0.45)
                                    )
                                
                                TextField("Pega tu código aquí", text: $recoveryCode)
                                    .textContentType(.none)
                                    .autocorrectionDisabled()
                                    .textInputAutocapitalization(.never)
                                    .font(.system(.body, design: .monospaced))
                                    .metallicTextField()
                            }
                            .padding(24)
                            .metallicCard()
                            
                            if let errorMessage = errorMessage {
                                Label(errorMessage, systemImage: "exclamationmark.circle")
                                    .font(.subheadline)
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
                            
                            // Botón de recuperación
                            Button(action: attemptRecovery) {
                                if isVerifying {
                                    ProgressView()
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                } else {
                                    Text("Recuperar Cuenta")
                                        .font(.headline)
                                        .fontWeight(.bold)
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                }
                            }
                            .foregroundStyle(.white)
                            .frame(height: 54)
                            .metallicButton(isEnabled: allFieldsFilled && !isVerifying)
                            .disabled(!allFieldsFilled || isVerifying)
                        } else {
                            // Cargando datos de recuperación
                            VStack(spacing: 16) {
                                ProgressView()
                                    .scaleEffect(1.5)
                                    .tint(colorScheme == .dark ? Color(red: 0.70, green: 0.75, blue: 0.85) : Color(red: 0.40, green: 0.45, blue: 0.55))
                                Text("Cargando datos de recuperación...")
                                    .font(.subheadline)
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
                            .padding(.top, 60)
                        }
                        
                        Spacer(minLength: 30)
                    }
                    .padding()
                }
            }
            .navigationTitle("Recuperación")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                loadRecoveryData()
            }
            .sheet(isPresented: $showNewPasswordSetup) {
                if let key = recoveredMasterKey {
                    NewPasswordAfterRecoveryView(
                        recoveredMasterKey: key,
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
                
                print("Código correcto, recuperando master key...")
                
                // Recuperar master key
                let masterKey = try recoveryManager.recoverMasterKey(
                    answers: cleanedAnswers,
                    code: cleanedCode,
                    recoveryData: data
                )
                
                print("Master key recuperada exitosamente")
                
                await MainActor.run {
                    self.recoveredMasterKey = masterKey
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
    
    let recoveredMasterKey: SymmetricKey
    @Binding var isAuthenticated: Bool
    let onComplete: () -> Void
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) var colorScheme
    
    @State private var newPassword: String = ""
    @State private var confirmPassword: String = ""
    @State private var isSettingUp: Bool = false
    @State private var errorMessage: String?
    @State private var showPassword: Bool = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                MetallicBackground()
                
                VStack(spacing: 30) {
                    MetallicHeader(
                        title: "Nueva Contraseña",
                        icon: "lock.rotation",
                        iconSize: 70
                    )
                    
                    VStack(spacing: 20) {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Nueva contraseña")
                                .font(.headline)
                                .foregroundStyle(
                                    colorScheme == .dark
                                        ? Color(red: 0.80, green: 0.85, blue: 0.95)
                                        : Color(red: 0.25, green: 0.30, blue: 0.45)
                                )
                            
                            HStack {
                                if showPassword {
                                    TextField("Mínimo 12 caracteres", text: $newPassword)
                                        .foregroundStyle(colorScheme == .dark ? .white : .primary)
                                } else {
                                    SecureField("Mínimo 12 caracteres", text: $newPassword)
                                        .foregroundStyle(colorScheme == .dark ? .white : .primary)
                                }
                                
                                Button(action: { showPassword.toggle() }) {
                                    Image(systemName: showPassword ? "eye.slash" : "eye")
                                        .foregroundStyle(
                                            LinearGradient(
                                                colors: colorScheme == .dark
                                                    ? [Color(red: 0.70, green: 0.75, blue: 0.85), Color(red: 0.50, green: 0.55, blue: 0.65)]
                                                    : [Color(red: 0.40, green: 0.45, blue: 0.55), Color(red: 0.60, green: 0.65, blue: 0.75)],
                                                startPoint: .top,
                                                endPoint: .bottom
                                            )
                                        )
                                }
                            }
                            .metallicTextField()
                            
                            MetallicStrengthBar(strength: newPassword.passwordStrength)
                        }
                        
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Confirmar contraseña")
                                .font(.headline)
                                .foregroundStyle(
                                    colorScheme == .dark
                                        ? Color(red: 0.80, green: 0.85, blue: 0.95)
                                        : Color(red: 0.25, green: 0.30, blue: 0.45)
                                )
                            
                            SecureField("Repite la contraseña", text: $confirmPassword)
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
                        }
                    }
                    .padding(24)
                    .metallicCard()
                    
                    Spacer()
                    
                    Button(action: setupNewPassword) {
                        if isSettingUp {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                                .padding()
                        } else {
                            Text("Establecer Contraseña")
                                .font(.headline)
                                .fontWeight(.bold)
                                .frame(maxWidth: .infinity)
                                .padding()
                        }
                    }
                    .foregroundStyle(.white)
                    .frame(height: 54)
                    .metallicButton(isEnabled: canProceed && !isSettingUp)
                    .disabled(!canProceed || isSettingUp)
                    .padding(.bottom, 30)
                }
                .padding(.horizontal, 24)
                .padding(.top, 40)
            }
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
        print("Usando master key recuperada (misma key, nueva contraseña)")
        
        Task {
            do {
                // Usar AuthViewModel para configurar nueva contraseña con la master key existente
                let authViewModel = AuthViewModel()
                try authViewModel.resetPassword(newPassword, masterKey: recoveredMasterKey)
                
                print("Nueva contraseña configurada exitosamente")
                print("Master key preservada - los datos existentes siguen accesibles")
                
                // Guardar masterKey en el singleton
                AuthStateManager.shared.masterKey = recoveredMasterKey
                
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
