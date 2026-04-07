//
//  SetupViewModel.swift
//  SecureDataManager
//
//  ViewModel para configuración inicial
//

import Foundation
import Combine
import CryptoKit
import LocalAuthentication
import SwiftUI

/// Estados del proceso de setup
enum SetupState {
    case passwordEntry
    case confirmPassword
    case securityQuestions
    case biometricSetup
    case completed
}

/// ViewModel para configuración inicial de la aplicación
class SetupViewModel: ObservableObject {
    
    @Published var setupState: SetupState = .passwordEntry
    @Published var password: String = ""
    @Published var confirmPassword: String = ""
    @Published var passwordStrength: Double = 0
    @Published var passwordError: String?
    
    // Sistema de recuperación híbrido
    @Published var recoveryCode: String = ""
    @Published var recoveryData: RecoveryData?
    @Published var recoveryQuestions: [String] = []
    @Published var recoveryAnswers: [String] = []
    
    @Published var isBiometricEnabled: Bool = false
    @Published var isBiometricAvailable: Bool = false
    
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    private let authViewModel = AuthViewModel()
    private let recoveryManager = RecoveryManager.shared
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        checkBiometricAvailability()
        setupPasswordValidation()
    }
    
    // MARK: - Validación de Contraseña
    
    private func setupPasswordValidation() {
        $password
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] password in
                self?.passwordStrength = password.passwordStrength
            }
            .store(in: &cancellables)
    }
    
    var isPasswordValid: Bool {
        return password.isValidPassword
    }
    
    func validatePassword() -> Bool {
        if !password.isValidPassword {
            passwordError = "La contraseña no cumple con los requisitos de seguridad"
            return false
        }
        passwordError = nil
        return true
    }
    
    func validatePasswordConfirmation() -> Bool {
        guard password == confirmPassword else {
            passwordError = "Las contraseñas no coinciden"
            return false
        }
        passwordError = nil
        return true
    }
    
    // MARK: - Navegación
    
    func proceedToConfirmPassword() {
        guard validatePassword() else { return }
        setupState = .confirmPassword
    }
    
    func proceedToSecurityQuestions() {
        guard validatePasswordConfirmation() else { return }
        setupState = .securityQuestions
    }
    
    func backToPasswordEntry() {
        setupState = .passwordEntry
        confirmPassword = ""
    }
    
    func backToConfirmPassword() {
        setupState = .confirmPassword
    }
    
    func backToSecurityQuestions() {
        setupState = .securityQuestions
    }
    
    func proceedToBiometricSetup() {
        setupState = .biometricSetup
    }
    
    // MARK: - Generación de Recuperación
    
    /// Guarda las preguntas y respuestas temporalmente
    func setRecoveryQuestions(_ questions: [String], answers: [String]) {
        self.recoveryQuestions = questions
        self.recoveryAnswers = answers
    }
    
    // MARK: - Completar Setup con Recuperación
    
    func completeSetup() async -> Bool {
        guard recoveryQuestions.count == 3 && recoveryAnswers.count == 3 else {
            errorMessage = "No se han configurado las preguntas de seguridad"
            return false
        }
        
        guard !recoveryCode.isEmpty else {
            errorMessage = "No se ha generado el código de recuperación"
            return false
        }
        
        isLoading = true
        
        do {
            // 1. Configurar contraseña (genera master key aleatoria)
            let masterKey = try authViewModel.setupPassword(password)
            
            print("Master key generada: \(masterKey.withUnsafeBytes { $0.count }) bytes")
            
            // 2. Generar RecoveryData con la master key
            let (recoveryData, _) = try recoveryManager.generateRecoveryData(
                questions: recoveryQuestions,
                answers: recoveryAnswers,
                code: recoveryCode,
                masterKey: masterKey
            )
            
            print("RecoveryData generado exitosamente")
            
            // 3. Guardar datos de recuperación en Keychain
            try KeychainManager.shared.saveRecoveryData(recoveryData)
            print("RecoveryData guardado en Keychain")
            
            // 4. Guardar masterKey en el singleton
            AuthStateManager.shared.masterKey = masterKey
            
            // 5. Configurar biometría si está habilitada
            if isBiometricEnabled {
                try authViewModel.enableBiometric()
            }
            
            await MainActor.run {
                setupState = .completed
                isLoading = false
            }
            
            return true
            
        } catch {
            await MainActor.run {
                errorMessage = "Error al completar configuración: \(error.localizedDescription)"
                isLoading = false
            }
            return false
        }
    }
    
    // MARK: - Biometría
    
    private func checkBiometricAvailability() {
        let context = LAContext()
        var error: NSError?
        isBiometricAvailable = context.canEvaluatePolicy(
            .deviceOwnerAuthenticationWithBiometrics,
            error: &error
        )
    }
    
    func verifyBiometric() {
        let context = LAContext()
        let reason = "Verificando configuración de Face ID/Touch ID"
        
        Task {
            do {
                let success = try await context.evaluatePolicy(
                    .deviceOwnerAuthenticationWithBiometrics,
                    localizedReason: reason
                )
                
                if !success {
                    await MainActor.run {
                        isBiometricEnabled = false
                    }
                }
            } catch {
                await MainActor.run {
                    isBiometricEnabled = false
                }
            }
        }
    }
    
}
