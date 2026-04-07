//
//  LoginView.swift
//  SecureDataManager
//
//  Vista de login con contraseña - Estilo Metálico
//

import SwiftUI
import LocalAuthentication

struct LoginView: View {
    
    @StateObject private var viewModel = AuthViewModel()
    @Binding var isAuthenticated: Bool
    @Binding var showSetup: Bool
    
    @State private var password: String = ""
    @State private var showPassword: Bool = false
    @State private var showRecovery: Bool = false
    @State private var shakeAnimation: Bool = false
    
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Fondo metálico
                MetallicBackground()
                
                VStack(spacing: 30) {
                    // Logo y título
                    VStack(spacing: 20) {
                        ZStack {
                            // Brillo exterior
                            Circle()
                                .fill(
                                    RadialGradient(
                                        colors: [
                                            colorScheme == .dark 
                                                ? Color(red: 0.35, green: 0.40, blue: 0.50).opacity(0.4)
                                                : Color.white.opacity(0.9),
                                            Color.clear
                                        ],
                                        center: .center,
                                        startRadius: 5,
                                        endRadius: 60
                                    )
                                )
                                .frame(width: 100, height: 100)
                            
                            Image(systemName: "lock.shield.fill")
                                .metallicIcon(size: 80)
                        }
                        
                        Text("SecureDataManager")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: colorScheme == .dark
                                        ? [Color.white, Color(red: 0.70, green: 0.75, blue: 0.85)]
                                        : [Color(red: 0.20, green: 0.25, blue: 0.40), Color(red: 0.40, green: 0.45, blue: 0.60)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .shadow(
                                color: colorScheme == .dark 
                                    ? Color.black.opacity(0.5)
                                    : Color.white.opacity(0.8),
                                radius: 2,
                                x: 0,
                                y: 1
                            )
                        
                        Text("Tu información, segura y cifrada")
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
                    
                    Spacer()
                    
                    // Card de login
                    VStack(spacing: 24) {
                        // Campo de contraseña
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Contraseña maestra")
                                .font(.headline)
                                .foregroundStyle(
                                    colorScheme == .dark
                                        ? Color(red: 0.80, green: 0.85, blue: 0.95)
                                        : Color(red: 0.25, green: 0.30, blue: 0.45)
                                )
                            
                            HStack {
                                if showPassword {
                                    TextField("Ingresa tu contraseña", text: $password)
                                        .textContentType(.password)
                                        .foregroundStyle(colorScheme == .dark ? .white : .primary)
                                } else {
                                    SecureField("Ingresa tu contraseña", text: $password)
                                        .textContentType(.password)
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
                        }
                        
                        if let errorMessage = viewModel.errorMessage {
                            VStack(spacing: 8) {
                                Label(errorMessage, systemImage: "exclamationmark.triangle")
                                    .font(.caption)
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [Color.red.opacity(0.9), Color.red.opacity(0.7)],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .transition(.opacity)
                                
                                // Botón para usar PIN cuando Face ID falla
                                if errorMessage.contains("biométrica") || errorMessage.contains("cancelada") {
                                    Button("Usar PIN del dispositivo") {
                                        loginWithPIN()
                                    }
                                    .font(.caption)
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: colorScheme == .dark
                                                ? [Color(red: 0.60, green: 0.70, blue: 0.90), Color(red: 0.50, green: 0.60, blue: 0.80)]
                                                : [Color(red: 0.30, green: 0.40, blue: 0.70), Color(red: 0.40, green: 0.50, blue: 0.80)],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                }
                            }
                        }
                        
                        if viewModel.remainingAttempts < 5 {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundStyle(MetallicColors.warningGradient)
                                Text("Intentos restantes: \(viewModel.remainingAttempts)")
                                    .font(.caption)
                                    .fontWeight(.medium)
                            }
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color.orange.opacity(0.9), Color.orange.opacity(0.7)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                        }
                        
                        // Botón de login
                        Button(action: login) {
                            if viewModel.isLoading {
                                ProgressView()
                                    .frame(maxWidth: .infinity)
                                    .padding()
                            } else {
                                Text("Desbloquear")
                                    .font(.headline)
                                    .fontWeight(.bold)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                            }
                        }
                        .foregroundStyle(.white)
                        .frame(height: 54)
                        .metallicButton(isEnabled: !password.isEmpty && !viewModel.isLoading)
                        .disabled(password.isEmpty || viewModel.isLoading)
                        
                        // Opciones adicionales
                        VStack(spacing: 12) {
                            Button("¿Olvidaste tu contraseña?") {
                                showRecovery = true
                            }
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(
                                LinearGradient(
                                    colors: colorScheme == .dark
                                        ? [Color(red: 0.65, green: 0.75, blue: 0.95), Color(red: 0.55, green: 0.65, blue: 0.85)]
                                        : [Color(red: 0.30, green: 0.40, blue: 0.70), Color(red: 0.40, green: 0.50, blue: 0.80)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            
                            Button("Configurar nueva cuenta") {
                                showSetup = true
                            }
                            .font(.subheadline)
                            .foregroundStyle(
                                LinearGradient(
                                    colors: colorScheme == .dark
                                        ? [Color(red: 0.55, green: 0.60, blue: 0.70), Color(red: 0.45, green: 0.50, blue: 0.60)]
                                        : [Color(red: 0.40, green: 0.45, blue: 0.55), Color(red: 0.55, green: 0.60, blue: 0.70)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                        }
                    }
                    .padding(24)
                    .metallicCard()
                    .offset(x: shakeAnimation ? -10 : 0)
                    .animation(shakeAnimation ? .easeInOut(duration: 0.1).repeatCount(5) : .default, value: shakeAnimation)
                    
                    Spacer()
                    
                    // Indicador de seguridad
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.shield.fill")
                            .foregroundStyle(MetallicColors.successGradient)
                        Text("Cifrado AES-256-GCM")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(
                                LinearGradient(
                                    colors: colorScheme == .dark
                                        ? [Color(red: 0.50, green: 0.85, blue: 0.65), Color(red: 0.40, green: 0.75, blue: 0.55)]
                                        : [Color(red: 0.25, green: 0.60, blue: 0.40), Color(red: 0.35, green: 0.70, blue: 0.50)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        Capsule()
                            .fill(MetallicColors.cardGradient(isDark: colorScheme == .dark))
                            .overlay(
                                Capsule()
                                    .stroke(MetallicColors.metallicBorder(isDark: colorScheme == .dark), lineWidth: 1)
                            )
                    )
                    .shadow(
                        color: colorScheme == .dark ? Color.black.opacity(0.3) : Color.black.opacity(0.1),
                        radius: 4,
                        x: 0,
                        y: 2
                    )
                    .padding(.bottom, 30)
                }
                .padding(.horizontal, 24)
            }
            .navigationDestination(isPresented: $showRecovery) {
                RecoveryView(isAuthenticated: $isAuthenticated)
            }
        }
    }
    
    private func login() {
        Task {
            let success = await viewModel.verifyPassword(password)
            
            if success {
                // Guardar masterKey en el singleton para compartirlo
                if let key = viewModel.masterKey {
                    await MainActor.run {
                        AuthStateManager.shared.masterKey = key
                    }
                }
                
                // Proceder a autenticación biométrica
                let bioSuccess = await viewModel.authenticateWithBiometric()
                if bioSuccess {
                    await MainActor.run {
                        isAuthenticated = true
                    }
                } else {
                    // Si falla la biometría, mostrar error y permitir reintentar
                    await MainActor.run {
                        viewModel.errorMessage = "Autenticación biométrica fallida. Intenta de nuevo."
                    }
                }
            } else {
                await MainActor.run {
                    shakeAnimation = true
                    password = ""
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        shakeAnimation = false
                    }
                }
            }
        }
    }
    
    /// Login usando PIN del dispositivo (fallback cuando Face ID falla)
    private func loginWithPIN() {
        Task {
            // Intentar autenticación con PIN/código del dispositivo
            let context = LAContext()
            let reason = "Autenticación requerida para acceder a tus datos"
            
            do {
                let success = try await context.evaluatePolicy(
                    .deviceOwnerAuthentication,
                    localizedReason: reason
                )
                
                if success {
                    // Asegurar que el masterKey esté guardado
                    if let key = viewModel.masterKey {
                        AuthStateManager.shared.masterKey = key
                    }
                    await MainActor.run {
                        isAuthenticated = true
                    }
                }
            } catch {
                await MainActor.run {
                    viewModel.errorMessage = "Autenticación fallida. Intenta de nuevo."
                }
            }
        }
    }
}

#Preview {
    LoginView(isAuthenticated: .constant(false), showSetup: .constant(false))
}
