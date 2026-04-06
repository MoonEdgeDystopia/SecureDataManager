//
//  SetupPasswordView.swift
//  SecureDataManager
//
//  Vista de configuración inicial de contraseña
//

import SwiftUI

struct SetupPasswordView: View {
    
    @StateObject private var viewModel = SetupViewModel()
    @Binding var isSetupComplete: Bool
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            Group {
                switch viewModel.setupState {
                case .passwordEntry:
                    passwordEntryView
                case .confirmPassword:
                    confirmPasswordView
                case .generatingShares:
                    generatingSharesView
                case .showingShares:
                    RecoverySetupView(viewModel: viewModel)
                case .biometricSetup:
                    BiometricSetupView(viewModel: viewModel, isSetupComplete: $isSetupComplete)
                case .completed:
                    completionView
                }
            }
        }
    }
    
    // MARK: - Password Entry
    
    private var passwordEntryView: some View {
        VStack(spacing: 24) {
            VStack(spacing: 12) {
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(.blue)
                
                Text("Crear Contraseña Maestra")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Esta contraseña protegerá todos tus datos. No podrás recuperarla si la olvidas.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 40)
            
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Contraseña")
                        .font(.headline)
                    
                    SecureField("Mínimo 12 caracteres", text: $viewModel.password)
                        .textContentType(.newPassword)
                        .padding()
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    
                    PasswordStrengthBar(password: viewModel.password)
                }
                
                // Requisitos
                VStack(alignment: .leading, spacing: 6) {
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
                        .foregroundStyle(.red)
                }
            }
            
            Spacer()
            
            Button(action: { viewModel.proceedToConfirmPassword() }) {
                Text("Continuar")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
            }
            .background(viewModel.isPasswordValid ? Color.blue : Color.gray)
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .disabled(!viewModel.isPasswordValid)
            .padding(.bottom, 30)
        }
        .padding(.horizontal, 30)
    }
    
    // MARK: - Confirm Password
    
    private var confirmPasswordView: some View {
        VStack(spacing: 24) {
            VStack(spacing: 12) {
                Image(systemName: "checkmark.shield.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(.green)
                
                Text("Confirma tu Contraseña")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Repite la contraseña para confirmar que la recuerdas correctamente.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 40)
            
            VStack(alignment: .leading, spacing: 16) {
                SecureField("Repite tu contraseña", text: $viewModel.confirmPassword)
                    .textContentType(.newPassword)
                    .padding()
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                
                if viewModel.password == viewModel.confirmPassword && !viewModel.confirmPassword.isEmpty {
                    Label("Las contraseñas coinciden", systemImage: "checkmark.circle.fill")
                        .font(.subheadline)
                        .foregroundStyle(.green)
                }
                
                if let errorMessage = viewModel.passwordError {
                    Label(errorMessage, systemImage: "exclamationmark.triangle")
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }
            
            Spacer()
            
            VStack(spacing: 12) {
                Button(action: { viewModel.proceedToShares() }) {
                    if viewModel.isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .padding()
                    } else {
                        Text("Continuar")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                    }
                }
                .background(viewModel.confirmPassword == viewModel.password && !viewModel.confirmPassword.isEmpty ? Color.green : Color.gray)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .disabled(viewModel.confirmPassword != viewModel.password || viewModel.confirmPassword.isEmpty || viewModel.isLoading)
                
                Button("Volver") {
                    viewModel.backToPasswordEntry()
                }
                .foregroundStyle(.secondary)
            }
            .padding(.bottom, 30)
        }
        .padding(.horizontal, 30)
    }
    
    // MARK: - Generating Shares
    
    private var generatingSharesView: some View {
        VStack(spacing: 24) {
            ProgressView()
                .scaleEffect(1.5)
            
            Text("Generando códigos de recuperación...")
                .font(.headline)
            
            Text("Esto puede tomar unos segundos")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
    }
    
    // MARK: - Completion
    
    private var completionView: some View {
        VStack(spacing: 24) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundStyle(.green)
            
            Text("¡Configuración Completada!")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Tu información ahora está protegida con cifrado AES-256-GCM.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            
            Spacer()
            
            Button("Comenzar") {
                isSetupComplete = true
            }
            .font(.headline)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.blue)
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding(.bottom, 30)
        }
        .padding(.horizontal, 30)
    }
}

/// Fila de requisito de contraseña
struct RequirementRow: View {
    let text: String
    let isMet: Bool
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: isMet ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(isMet ? .green : .gray)
            Text(text)
                .foregroundStyle(isMet ? .primary : .secondary)
            Spacer()
        }
    }
}

#Preview {
    SetupPasswordView(isSetupComplete: .constant(false))
}
