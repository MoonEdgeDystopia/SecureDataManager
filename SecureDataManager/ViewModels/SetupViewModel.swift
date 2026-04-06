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
    case generatingShares
    case showingShares
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
    
    @Published var shares: [SecretShare] = []
    @Published var sharesGenerated: Bool = false
    
    @Published var isBiometricEnabled: Bool = false
    @Published var isBiometricAvailable: Bool = false
    
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    private let shamir = ShamirSecretSharing()
    private let authViewModel = AuthViewModel()
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
    
    // MARK: - Navegación del Setup
    
    func proceedToConfirmPassword() {
        guard validatePassword() else { return }
        setupState = .confirmPassword
    }
    
    func proceedToShares() {
        guard validatePasswordConfirmation() else { return }
        setupState = .generatingShares
        generateShares()
    }
    
    func backToPasswordEntry() {
        setupState = .passwordEntry
        confirmPassword = ""
    }
    
    func backToConfirmPassword() {
        setupState = .confirmPassword
    }
    
    // MARK: - Generación de Shares
    
    private func generateShares() {
        isLoading = true
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            do {
                // Crear datos del secreto (salt + indicador)
                let cryptoService = CryptoService()
                let salt = cryptoService.generateSalt()
                
                // El secreto es el salt que se necesita para derivar la clave
                // junto con la contraseña que solo conoce el usuario
                let secretData = salt
                
                // Generar 5 shares, necesarios 3 para reconstruir
                let generatedShares = try self.shamir.split(
                    secret: secretData,
                    totalShares: 5,
                    threshold: 3
                )
                
                DispatchQueue.main.async {
                    self.shares = generatedShares
                    self.sharesGenerated = true
                    self.setupState = .showingShares
                    self.isLoading = false
                }
                
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = "Error al generar shares: \(error.localizedDescription)"
                    self.isLoading = false
                }
            }
        }
    }
    
    func proceedToBiometric() {
        setupState = .biometricSetup
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
    
    // MARK: - Completar Setup
    
    func completeSetup() async -> Bool {
        isLoading = true
        
        do {
            // Configurar contraseña
            try authViewModel.setupPassword(password)
            
            // Guardar masterKey en el singleton
            if let key = authViewModel.masterKey {
                await MainActor.run {
                    AuthStateManager.shared.masterKey = key
                }
            }
            
            // Configurar biometría
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
    
    // MARK: - Recuperación
    
    /// Recupera el secreto desde shares
    func recoverFromShares(_ shareCodes: [String]) throws -> Data {
        guard shareCodes.count >= 3 else {
            throw ShamirError.insufficientShares
        }
        
        var shares: [SecretShare] = []
        for code in shareCodes.prefix(3) {
            guard let share = SecretShare(shareCode: code) else {
                throw ShamirError.invalidShare
            }
            shares.append(share)
        }
        
        return try shamir.combine(shares: shares)
    }
}
