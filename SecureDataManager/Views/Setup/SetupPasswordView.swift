//
//  SetupPasswordView.swift
//  SecureDataManager
//
//  Vista de configuración inicial de contraseña - Estilo Metálico
//

import SwiftUI

struct SetupPasswordView: View {
    
    @StateObject private var viewModel = SetupViewModel()
    @Binding var isSetupComplete: Bool
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        NavigationStack {
            ZStack {
                MetallicBackground()
                
                Group {
                    switch viewModel.setupState {
                    case .passwordEntry:
                        passwordEntryView
                    case .confirmPassword:
                        confirmPasswordView
                    case .securityQuestions:
                        SecurityQuestionsSetupView(viewModel: viewModel, isSetupComplete: $isSetupComplete)
                    case .biometricSetup:
                        BiometricSetupView(viewModel: viewModel, isSetupComplete: $isSetupComplete)
                    case .completed:
                        completionView
                    }
                }
            }
        }
    }
    
    // MARK: - Password Entry
    
    private var passwordEntryView: some View {
        VStack(spacing: 24) {
            MetallicHeader(
                title: "Crear Contraseña",
                icon: "lock.shield.fill",
                iconSize: 70
            )
            
            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Contraseña maestra")
                        .font(.headline)
                        .foregroundStyle(
                            colorScheme == .dark
                                ? Color(red: 0.80, green: 0.85, blue: 0.95)
                                : Color(red: 0.25, green: 0.30, blue: 0.45)
                        )
                    
                    SecureField("Mínimo 12 caracteres", text: $viewModel.password)
                        .textContentType(.newPassword)
                        .metallicTextField()
                    
                    MetallicStrengthBar(strength: viewModel.passwordStrength)
                }
                
                // Requisitos
                VStack(alignment: .leading, spacing: 10) {
                    RequirementRow(
                        text: "Mínimo 12 caracteres",
                        isMet: viewModel.password.count >= 12
                    )
                    RequirementRow(
                        text: "Al menos una mayúscula",
                        isMet: viewModel.password.rangeOfCharacter(from: .uppercaseLetters) != nil
                    )
                    RequirementRow(
                        text: "Al menos una minúscula",
                        isMet: viewModel.password.rangeOfCharacter(from: .lowercaseLetters) != nil
                    )
                    RequirementRow(
                        text: "Al menos un número",
                        isMet: viewModel.password.rangeOfCharacter(from: .decimalDigits) != nil
                    )
                    RequirementRow(
                        text: "Al menos un carácter especial",
                        isMet: viewModel.password.rangeOfCharacter(from: CharacterSet.alphanumerics.inverted) != nil
                    )
                }
                .font(.caption)
                
                if let errorMessage = viewModel.passwordError {
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
            
            Button(action: { viewModel.proceedToConfirmPassword() }) {
                Text("Continuar")
                    .font(.headline)
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity)
                    .padding()
            }
            .foregroundStyle(.white)
            .frame(height: 54)
            .metallicButton(isEnabled: viewModel.isPasswordValid)
            .disabled(!viewModel.isPasswordValid)
            .padding(.horizontal, 24)
            .padding(.bottom, 30)
        }
        .padding(.horizontal, 24)
        .padding(.top, 40)
    }
    
    // MARK: - Confirm Password
    
    private var confirmPasswordView: some View {
        VStack(spacing: 24) {
            MetallicHeader(
                title: "Confirmar",
                icon: "checkmark.shield.fill",
                iconSize: 70
            )
            
            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Repite tu contraseña")
                        .font(.headline)
                        .foregroundStyle(
                            colorScheme == .dark
                                ? Color(red: 0.80, green: 0.85, blue: 0.95)
                                : Color(red: 0.25, green: 0.30, blue: 0.45)
                        )
                    
                    SecureField("Ingresa la misma contraseña", text: $viewModel.confirmPassword)
                        .textContentType(.newPassword)
                        .metallicTextField()
                    
                    if viewModel.password == viewModel.confirmPassword && !viewModel.confirmPassword.isEmpty {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(MetallicColors.successGradient)
                            Text("Las contraseñas coinciden")
                                .font(.subheadline)
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [Color.green.opacity(0.8), Color.green.opacity(0.6)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                        }
                    }
                    
                    if let errorMessage = viewModel.passwordError {
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
            }
            .padding(24)
            .metallicCard()
            
            Spacer()
            
            VStack(spacing: 12) {
                Button(action: { viewModel.proceedToSecurityQuestions() }) {
                    if viewModel.isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .padding()
                    } else {
                        Text("Continuar")
                            .font(.headline)
                            .fontWeight(.bold)
                            .frame(maxWidth: .infinity)
                            .padding()
                    }
                }
                .foregroundStyle(.white)
                .frame(height: 54)
                .metallicButton(isEnabled: viewModel.confirmPassword == viewModel.password && !viewModel.confirmPassword.isEmpty && !viewModel.isLoading)
                .disabled(viewModel.confirmPassword != viewModel.password || viewModel.confirmPassword.isEmpty || viewModel.isLoading)
                
                Button("Volver") {
                    viewModel.backToPasswordEntry()
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
            .padding(.horizontal, 24)
            .padding(.bottom, 30)
        }
        .padding(.horizontal, 24)
        .padding(.top, 40)
    }
    
    // MARK: - Completion
    
    private var completionView: some View {
        VStack(spacing: 30) {
            Spacer()
            
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color(red: 0.30, green: 0.75, blue: 0.50).opacity(0.3),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 10,
                            endRadius: 80
                        )
                    )
                    .frame(width: 160, height: 160)
                
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(MetallicColors.successGradient)
                    .background(
                        Circle()
                            .fill(
                                colorScheme == .dark
                                    ? Color(red: 0.15, green: 0.20, blue: 0.15)
                                    : Color(red: 0.95, green: 0.98, blue: 0.95)
                            )
                    )
            }
            
            Text("¡Configuración Completada!")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(
                    LinearGradient(
                        colors: colorScheme == .dark
                            ? [Color.white, Color(red: 0.70, green: 0.75, blue: 0.85)]
                            : [Color(red: 0.20, green: 0.25, blue: 0.40), Color(red: 0.40, green: 0.45, blue: 0.60)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            
            Text("Tu información está protegida con cifrado AES-256-GCM")
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
                .padding(.horizontal, 40)
            
            Spacer()
            
            Button("Comenzar") {
                isSetupComplete = true
            }
            .font(.headline)
            .fontWeight(.bold)
            .frame(maxWidth: .infinity)
            .padding()
            .foregroundStyle(.white)
            .frame(height: 54)
            .metallicButton(isEnabled: true)
            .padding(.horizontal, 24)
            .padding(.bottom, 50)
        }
        .padding(.horizontal, 24)
    }
}

/// Fila de requisito de contraseña estilo metálico
struct RequirementRow: View {
    let text: String
    let isMet: Bool
    
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: isMet ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(
                    isMet
                        ? MetallicColors.successGradient
                        : LinearGradient(
                            colors: colorScheme == .dark
                                ? [Color(red: 0.50, green: 0.52, blue: 0.55), Color(red: 0.40, green: 0.42, blue: 0.45)]
                                : [Color(red: 0.65, green: 0.67, blue: 0.70), Color(red: 0.75, green: 0.77, blue: 0.80)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                )
            Text(text)
                .font(.caption)
                .fontWeight(isMet ? .medium : .regular)
                .foregroundStyle(
                    isMet
                        ? (colorScheme == .dark
                            ? Color(red: 0.50, green: 0.85, blue: 0.65)
                            : Color(red: 0.25, green: 0.60, blue: 0.40))
                        : (colorScheme == .dark
                            ? Color(red: 0.55, green: 0.60, blue: 0.70)
                            : Color(red: 0.45, green: 0.50, blue: 0.60))
                )
            Spacer()
        }
    }
}

#Preview {
    SetupPasswordView(isSetupComplete: .constant(false))
}
