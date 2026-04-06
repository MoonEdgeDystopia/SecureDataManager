//
//  LoginView.swift
//  SecureDataManager
//
//  Vista de login con contraseña
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
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 30) {
                // Logo y título
                VStack(spacing: 16) {
                    Image(systemName: "lock.shield.fill")
                        .font(.system(size: 80))
                        .foregroundStyle(.blue)
                    
                    Text("SecureDataManager")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Tu información, segura y cifrada")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 60)
                
                Spacer()
                
                // Campo de contraseña
                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Contraseña maestra")
                            .font(.headline)
                        
                        HStack {
                            if showPassword {
                                TextField("Ingresa tu contraseña", text: $password)
                                    .textContentType(.password)
                            } else {
                                SecureField("Ingresa tu contraseña", text: $password)
                                    .textContentType(.password)
                            }
                            
                            Button(action: { showPassword.toggle() }) {
                                Image(systemName: showPassword ? "eye.slash" : "eye")
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    
                    if let errorMessage = viewModel.errorMessage {
                        Label(errorMessage, systemImage: "exclamationmark.triangle")
                            .font(.caption)
                            .foregroundStyle(.red)
                            .transition(.opacity)
                        
                        // Botón para usar PIN cuando Face ID falla
                        if errorMessage.contains("biométrica") || errorMessage.contains("cancelada") {
                            Button("Usar PIN del dispositivo") {
                                loginWithPIN()
                            }
                            .font(.caption)
                            .foregroundStyle(.blue)
                            .padding(.top, 4)
                        }
                    }
                    
                    if viewModel.remainingAttempts < 5 {
                        Text("Intentos restantes: \(viewModel.remainingAttempts)")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                }
                .offset(x: shakeAnimation ? -10 : 0)
                .animation(shakeAnimation ? .easeInOut(duration: 0.1).repeatCount(5) : .default, value: shakeAnimation)
                
                // Botón de login
                Button(action: login) {
                    if viewModel.isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .padding()
                    } else {
                        Text("Desbloquear")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                    }
                }
                .background(password.isEmpty ? Color.gray : Color.blue)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .disabled(password.isEmpty || viewModel.isLoading)
                
                // Opciones adicionales
                VStack(spacing: 12) {
                    Button("¿Olvidaste tu contraseña?") {
                        showRecovery = true
                    }
                    .font(.subheadline)
                    .foregroundStyle(.blue)
                    
                    Button("Configurar nueva cuenta") {
                        showSetup = true
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                // Indicador de seguridad
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.shield.fill")
                        .foregroundStyle(.green)
                    Text("Cifrado AES-256-GCM")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.bottom, 20)
            }
            .padding(.horizontal, 30)
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
