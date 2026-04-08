//
//  RecoveryView.swift
//  SecureDataManager
//
//  Vista para recuperación de contraseña con preguntas personalizadas - Estilo Metálico
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
                        
                        Text("Responde tus preguntas de seguridad personalizadas e ingresa tu código de recuperación para restablecer el acceso a tu cuenta.")
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
                            // Preguntas de seguridad personalizadas
                            VStack(alignment: .leading, spacing: 20) {
                                HStack {
                                    Image(systemName: "questionmark.bubble.fill")
                                        .foregroundStyle(
                                            LinearGradient(
                                                colors: [Color(red: 0.40, green: 0.50, blue: 0.70), Color(red: 0.30, green: 0.40, blue: 0.60)],
                                                startPoint: .top,
                                                endPoint: .bottom
                                            )
                                        )
                                    
                                    Text("Preguntas de Seguridad")
                                        .font(.headline)
                                        .foregroundStyle(
                                            colorScheme == .dark
                                                ? Color(red: 0.80, green: 0.85, blue: 0.95)
                                                : Color(red: 0.25, green: 0.30, blue: 0.45)
                                        )
                                }
                                
                                // Pregunta 1
                                RecoveryQuestionField(
                                    number: 1,
                                    question: data.question1,
                                    answer: $answers[0]
                                )
                                
                                // Pregunta 2
                                RecoveryQuestionField(
                                    number: 2,
                                    question: data.question2,
                                    answer: $answers[1]
                                )
                                
                                // Pregunta 3
                                RecoveryQuestionField(
                                    number: 3,
                                    question: data.question3,
                                    answer: $answers[2]
                                )
                            }
                            .padding(24)
                            .metallicCard()
                            
                            // Código de recuperación
                            VStack(alignment: .leading, spacing: 16) {
                                HStack {
                                    Image(systemName: "key.horizontal.fill")
                                        .foregroundStyle(
                                            LinearGradient(
                                                colors: [Color(red: 0.85, green: 0.70, blue: 0.30), Color(red: 0.75, green: 0.60, blue: 0.20)],
                                                startPoint: .top,
                                                endPoint: .bottom
                                            )
                                        )
                                    
                                    Text("Código de Recuperación")
                                        .font(.headline)
                                        .foregroundStyle(
                                            colorScheme == .dark
                                                ? Color(red: 0.90, green: 0.85, blue: 0.70)
                                                : Color(red: 0.60, green: 0.50, blue: 0.25)
                                        )
                                }
                                
                                TextField("Pega tu código de recuperación aquí", text: $recoveryCode)
                                    .textContentType(.none)
                                    .autocorrectionDisabled()
                                    .textInputAutocapitalization(.never)
                                    .font(.system(.body, design: .monospaced))
                                    .foregroundStyle(colorScheme == .dark ? .white : .primary)
                                    .padding(14)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(
                                                colorScheme == .dark
                                                    ? Color(red: 0.25, green: 0.23, blue: 0.18).opacity(0.5)
                                                    : Color(red: 1.0, green: 0.98, blue: 0.90)
                                            )
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .stroke(
                                                        LinearGradient(
                                                            colors: [Color(red: 0.85, green: 0.70, blue: 0.30).opacity(0.5), Color(red: 0.75, green: 0.60, blue: 0.20).opacity(0.3)],
                                                            startPoint: .topLeading,
                                                            endPoint: .bottomTrailing
                                                        ),
                                                        lineWidth: 1.5
                                                    )
                                            )
                                    )
                            }
                            .padding(24)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(
                                        LinearGradient(
                                            colors: colorScheme == .dark
                                                ? [Color(red: 0.22, green: 0.20, blue: 0.16), Color(red: 0.15, green: 0.14, blue: 0.10)]
                                                : [Color(red: 1.0, green: 0.99, blue: 0.96), Color(red: 0.95, green: 0.94, blue: 0.91)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(
                                                LinearGradient(
                                                    colors: [Color(red: 0.90, green: 0.75, blue: 0.35).opacity(0.4), Color(red: 0.80, green: 0.65, blue: 0.25).opacity(0.2)],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                ),
                                                lineWidth: 2
                                            )
                                    )
                            )
                            .shadow(
                                color: Color(red: 0.85, green: 0.70, blue: 0.30).opacity(colorScheme == .dark ? 0.15 : 0.08),
                                radius: 8,
                                x: 0,
                                y: 4
                            )
                            
                            if let errorMessage = errorMessage {
                                Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                                    .font(.subheadline)
                                    .foregroundStyle(.white)
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(
                                                LinearGradient(
                                                    colors: [Color.red.opacity(0.8), Color.red.opacity(0.6)],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                )
                                            )
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .stroke(Color.red.opacity(0.5), lineWidth: 1)
                                            )
                                    )
                                    .shadow(
                                        color: Color.red.opacity(0.3),
                                        radius: 4,
                                        x: 0,
                                        y: 2
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
                            VStack(spacing: 20) {
                                ZStack {
                                    Circle()
                                        .stroke(
                                            MetallicColors.metallicBorder(isDark: colorScheme == .dark),
                                            lineWidth: 3
                                        )
                                        .frame(width: 80, height: 80)
                                    
                                    ProgressView()
                                        .scaleEffect(1.3)
                                        .tint(colorScheme == .dark ? Color(red: 0.70, green: 0.75, blue: 0.85) : Color(red: 0.40, green: 0.45, blue: 0.55))
                                }
                                
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
                
                // Limpiar respuestas (mantener mayúsculas/minúsculas del usuario)
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

// MARK: - Campo de Pregunta de Recuperación

struct RecoveryQuestionField: View {
    let number: Int
    let question: String
    @Binding var answer: String
    
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Número y pregunta
            HStack(alignment: .top, spacing: 10) {
                Text("\(number)")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                    .frame(width: 24, height: 24)
                    .background(
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color(red: 0.40, green: 0.50, blue: 0.70), Color(red: 0.30, green: 0.40, blue: 0.60)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )
                
                Text(question)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(colorScheme == .dark ? .white : .primary)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            // Campo de respuesta
            SecureField("Tu respuesta", text: $answer)
                .font(.body)
                .foregroundStyle(colorScheme == .dark ? .white : .primary)
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(
                            colorScheme == .dark
                                ? Color(red: 0.12, green: 0.13, blue: 0.15)
                                : Color(red: 0.97, green: 0.98, blue: 0.99)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(MetallicColors.metallicBorder(isDark: colorScheme == .dark), lineWidth: 1)
                        )
                )
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(
                    LinearGradient(
                        colors: colorScheme == .dark
                            ? [Color(red: 0.18, green: 0.20, blue: 0.24).opacity(0.5), Color(red: 0.13, green: 0.15, blue: 0.18).opacity(0.3)]
                            : [Color(red: 0.96, green: 0.97, blue: 0.98), Color(red: 0.91, green: 0.93, blue: 0.95)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                )
        )
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
                            
                            if newPassword == confirmPassword && !confirmPassword.isEmpty {
                                HStack {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(MetallicColors.successGradient)
                                    Text("Las contraseñas coinciden")
                                        .font(.caption)
                                        .foregroundStyle(
                                            LinearGradient(
                                                colors: [Color.green.opacity(0.8), Color.green.opacity(0.6)],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                }
                            }
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
